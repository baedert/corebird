/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2018 Timm Bäder
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

#include "CbMaxSizeContainer.h"

G_DEFINE_TYPE (CbMaxSizeContainer, cb_max_size_container, GTK_TYPE_BIN);


static void
cb_max_size_container_measure (GtkWidget      *widget,
                               GtkOrientation  orientation,
                               int             for_size,
                               int            *minimum,
                               int            *natural,
                               int            *minimum_baseline,
                               int            *natural_baseline)
{
  CbMaxSizeContainer *self = CB_MAX_SIZE_CONTAINER (widget);
  GtkWidget *child = gtk_bin_get_child (GTK_BIN (widget));
  int min_height;
  int nat_height;

  if (child == NULL)
    return;

  if (orientation == GTK_ORIENTATION_HORIZONTAL)
    {
      gtk_widget_measure (child, orientation, for_size,
                          minimum, natural, minimum_baseline, natural_baseline);
      return;
    }

  gtk_widget_measure (child, orientation, for_size, &min_height, &nat_height, NULL, NULL);

  *minimum = min_height * self->fraction;
  *natural = nat_height * self->fraction;
}

static void
cb_max_size_container_size_allocate (GtkWidget           *widget,
                                     const GtkAllocation *allocation,
                                     int                  baseline)
{
  GtkWidget *child = gtk_bin_get_child (GTK_BIN (widget));
  GtkAllocation child_alloc;
  int min_height;

  if (child == NULL)
    return;

  gtk_widget_measure (child, GTK_ORIENTATION_VERTICAL, allocation->width,
                      &min_height, NULL, NULL, NULL);

  child_alloc.x = 0;
  child_alloc.y = 0;
  child_alloc.width = allocation->width;
  child_alloc.height = min_height;

  gtk_widget_size_allocate (child, &child_alloc, baseline);
}

static void
cb_max_size_container_snapshot (GtkWidget   *widget,
                                GtkSnapshot *snapshot)
{
  GtkWidget *child = gtk_bin_get_child (GTK_BIN (widget));

  if (child == NULL)
    return;

  gtk_snapshot_push_clip (snapshot,
                          &GRAPHENE_RECT_INIT (
                            0, 0,
                            gtk_widget_get_width (widget),
                            gtk_widget_get_height (widget)
                          ));

  gtk_widget_snapshot_child (widget, child, snapshot);

  gtk_snapshot_pop (snapshot);
}

static GtkWidget *
cb_max_size_container_pick (GtkWidget *widget,
                            double     x,
                            double     y)
{
  if (x >= 0 && x < gtk_widget_get_width (widget) &&
      y >= 0 && y < gtk_widget_get_height (widget))
    return GTK_WIDGET_CLASS (cb_max_size_container_parent_class)->pick (widget, x, y);
  else if (gtk_widget_contains (widget, x, y))
    return widget;

  return NULL;
}

static void
open_animate_func (CbAnimation *self,
                   double       t,
                   gpointer     user_data)
{
  cb_max_size_container_set_fraction (CB_MAX_SIZE_CONTAINER (self->owner), t);
}

static void
cb_max_size_container_class_init (CbMaxSizeContainerClass *klass)
{
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  widget_class->pick = cb_max_size_container_pick;
  widget_class->measure = cb_max_size_container_measure;
  widget_class->size_allocate = cb_max_size_container_size_allocate;
  widget_class->snapshot = cb_max_size_container_snapshot;
}

static void
cb_max_size_container_init (CbMaxSizeContainer *self)
{
  cb_animation_init (&self->open_animation,
                     GTK_WIDGET (self),
                     open_animate_func);
}

void
cb_max_size_container_set_fraction (CbMaxSizeContainer *self,
                                    double              fraction)
{
  fraction = CLAMP (fraction, 0, 1);

  if (fraction != self->fraction)
    {
      self->fraction = fraction;
      gtk_widget_queue_resize (GTK_WIDGET (self));
    }
}

double
cb_max_size_container_get_fraction (CbMaxSizeContainer *self)
{
  return self->fraction;
}

void
cb_max_size_container_animate_open (CbMaxSizeContainer *self)
{
  /* TODO: This is stupid and CbAnimation should have some set_reversed API. Probably. */
  if (self->fraction > 0)
    {
      /*if (!cb_animation_is_reverse (&self->open_animation))*/
        cb_animation_start_reverse (&self->open_animation);
      /*else*/
        /*cb_animation_start (&self->open_animation);*/
    }
  else
    {
      /*if (cb_animation_is_reverse (&self->open_animation))*/
        /*cb_animation_start_reverse (&self->open_animation);*/
      /*else*/
        cb_animation_start (&self->open_animation, NULL);
    }
}
