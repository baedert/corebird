/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2017 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "CbAnimation.h"
#include "CbUtils.h"


static void
remove_tick_id (CbAnimation *self)
{
  if (self->tick_id != 0)
    {
      gtk_widget_remove_tick_callback (self->owner, self->tick_id);
      self->tick_id = 0;
    }
}

static double
cb_animation_get_current_delta (const CbAnimation *self)
{
  guint64 now = gdk_frame_clock_get_frame_time (gtk_widget_get_frame_clock (self->owner));
  guint64 current_duration;
  double t;

  current_duration = now - self->start_time;
  t = ((double)current_duration / (double)self->duration);
  t = MIN (t, 1.0);

  t = ease_out_cubic (t);

  return t;
}

static gboolean
cb_animation_tick_cb (GtkWidget     *widget,
                      GdkFrameClock *frame_clock,
                      gpointer       user_data)
{
  CbAnimation *self = user_data;
  double t = cb_animation_get_current_delta (self);
  double progress;

  progress = self->start_percentage + (t * (1.0 - self->start_percentage));

  if (self->reverse)
    progress = 1.0 - progress;

  self->func (self, progress);

  if (t >= 1.0)
    {
      self->tick_id = 0;
      return G_SOURCE_REMOVE;
    }

  return G_SOURCE_CONTINUE;
}

void
cb_animation_init (CbAnimation   *self,
                   GtkWidget     *owner,
                   CbAnimateFunc  func)
{
  self->owner = owner;
  self->duration = CB_TRANSITION_DURATION;
  self->tick_id = 0;
  self->func = func;
  self->reverse = FALSE;
}

void
cb_animation_stop (CbAnimation *self)
{
  if (self->tick_id == 0)
    return;

  /* Stopping means we call the current callback once with t = 1.0,
   * then stop updating. */

  if (self->reverse)
    self->func (self, 0.0);
  else
    self->func (self, 1.0);

  remove_tick_id (self);
}

void
cb_animation_start (CbAnimation *self)
{
  guint64 now;

  self->reverse = FALSE;

  /* Before realized, just jump to the end... */
  if (!gtk_widget_get_realized (self->owner))
    {
      self->func (self, 1.0);
      remove_tick_id (self);
      return;
    }

  now = gdk_frame_clock_get_frame_time (gtk_widget_get_frame_clock (self->owner));
  if (self->tick_id != 0)
    {
      double t = cb_animation_get_current_delta (self);

      self->duration = (self->start_time + self->duration) - now;
      self->start_percentage = t;
      self->start_time = now;
    }
  else
    {

      self->start_percentage = 0.0;
      self->duration = CB_TRANSITION_DURATION;
      self->start_time = now;
      self->tick_id = gtk_widget_add_tick_callback (self->owner,
                                                    cb_animation_tick_cb,
                                                    self, NULL);
    }
}

void
cb_animation_start_reverse (CbAnimation *self)
{
  guint64 now;

  self->reverse = TRUE;

  /* Before realized, just jump to the end... */
  if (!gtk_widget_get_realized (self->owner))
    {
      self->func (self, 0.0);
      remove_tick_id (self);
      return;
    }

  now = gdk_frame_clock_get_frame_time (gtk_widget_get_frame_clock (self->owner));

  if (self->tick_id != 0)
    {
      double t = cb_animation_get_current_delta (self);

      self->duration = (self->start_time + self->duration) - now;
      self->start_percentage = 1.0 - t;
      self->start_time = now;
    }
  else
    {
      self->duration = CB_TRANSITION_DURATION;
      self->start_percentage = 0.0;
      self->start_time = now;
      self->tick_id = gtk_widget_add_tick_callback (self->owner,
                                                    cb_animation_tick_cb,
                                                    self, NULL);
    }
}

gboolean
cb_animation_is_running (const CbAnimation *self)
{
  return self->tick_id != 0;
}

gboolean
cb_animation_is_reverse (const CbAnimation *self)
{
  return self->reverse;
}

void
cb_animation_destroy (CbAnimation *self)
{
  cb_animation_stop (self);
}
