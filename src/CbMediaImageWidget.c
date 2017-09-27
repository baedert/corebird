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
#include "CbMediaImageWidget.h"

G_DEFINE_TYPE (CbMediaImageWidget, cb_media_image_widget, GTK_TYPE_SCROLLED_WINDOW)

static void
cb_media_image_widget_finalize (GObject *object)
{
  CbMediaImageWidget *self = CB_MEDIA_IMAGE_WIDGET (object);

  g_clear_object (&self->drag_gesture);

  G_OBJECT_CLASS (cb_media_image_widget_parent_class)->finalize (object);
}


static void
drag_begin_cb (GtkGestureDrag *gesture,
               double          start_x,
               double          start_y,
               gpointer        user_data)
{
  CbMediaImageWidget *self = user_data;
  GtkAdjustment *adjustment;

  adjustment = gtk_scrolled_window_get_hadjustment (GTK_SCROLLED_WINDOW (self));
  self->drag_start_hvalue = gtk_adjustment_get_value (adjustment);

  adjustment = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (self));
  self->drag_start_vvalue = gtk_adjustment_get_value (adjustment);

  gtk_gesture_set_state (GTK_GESTURE (gesture), GTK_EVENT_SEQUENCE_CLAIMED);
}

static void
drag_update_cb (GtkGestureDrag *gesture,
                double          offset_x,
                double          offset_y,
                gpointer        user_data)
{
  CbMediaImageWidget *self = user_data;
  GtkAdjustment *adjustment;

  adjustment = gtk_scrolled_window_get_hadjustment (GTK_SCROLLED_WINDOW (self));
  gtk_adjustment_set_value (adjustment, self->drag_start_hvalue - offset_x);

  adjustment = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (self));
  gtk_adjustment_set_value (adjustment, self->drag_start_vvalue - offset_y);

  gtk_gesture_set_state (GTK_GESTURE (gesture), GTK_EVENT_SEQUENCE_CLAIMED);
}

static void
cb_media_image_widget_class_init (CbMediaImageWidgetClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_media_image_widget_finalize;
}

static void
cb_media_image_widget_init (CbMediaImageWidget *self)
{
  self->image = gtk_image_new ();
  gtk_container_add (GTK_CONTAINER (self), self->image);

  self->initial_scroll_x = 0.5;
  self->initial_scroll_y = 0.5;

  self->drag_gesture = gtk_gesture_drag_new (GTK_WIDGET (self));
  gtk_gesture_single_set_button (GTK_GESTURE_SINGLE (self->drag_gesture), GDK_BUTTON_MIDDLE);
  gtk_event_controller_set_propagation_phase (GTK_EVENT_CONTROLLER (self->drag_gesture), GTK_PHASE_CAPTURE);
  g_signal_connect (self->drag_gesture, "drag-begin", G_CALLBACK (drag_begin_cb), self);
  g_signal_connect (self->drag_gesture, "drag-update", G_CALLBACK (drag_update_cb), self);
}

GtkWidget *
cb_media_image_widget_new (CbMedia *media)
{
  CbMediaImageWidget *self;
  int img_width;
  int img_height;
  int win_width;
  int win_height;

  g_return_val_if_fail (CB_IS_MEDIA (media), NULL);
  g_return_val_if_fail (!media->invalid, NULL);
  g_return_val_if_fail (media->surface != NULL, NULL);

  self = CB_MEDIA_IMAGE_WIDGET (g_object_new (CB_TYPE_MEDIA_IMAGE_WIDGET, NULL));

  if (media->type == CB_MEDIA_TYPE_GIF)
    gtk_image_set_from_animation (GTK_IMAGE (self->image), media->animation);
  else
    gtk_image_set_from_surface (GTK_IMAGE (self->image), media->surface);

  img_width  = cairo_image_surface_get_width (media->surface);
  img_height = cairo_image_surface_get_height (media->surface);

  win_width = 800;
  win_height = 600;

  /* TODO: Replace the GdkScreen usage here */

  if (img_width <= 800)
    {
      win_width = img_width;
      g_object_set (self,
                    "hscrollbar-policy", GTK_POLICY_NEVER,
                    NULL);
    }

  if (img_height <= 600)
    {
      win_height = img_height;
      g_object_set (self,
                    "vscrollbar-policy", GTK_POLICY_NEVER,
                    NULL);
    }


  gtk_widget_set_size_request (GTK_WIDGET (self), win_width, win_height);

  return GTK_WIDGET (self);
}

static void
hadjustment_changed_cb (GtkAdjustment *adjustment,
                        gpointer       user_data)
{
  CbMediaImageWidget *self = user_data;
  double upper;
  double new_value;

  upper = gtk_adjustment_get_upper (adjustment);
  new_value = upper * self->initial_scroll_x - (gtk_adjustment_get_page_size (adjustment) / 2.0);

  gtk_adjustment_set_value (adjustment, new_value);

  g_signal_handler_disconnect (adjustment, self->hadj_changed_id);
}

static void
vadjustment_changed_cb (GtkAdjustment *adjustment,
                        gpointer       user_data)
{
  CbMediaImageWidget *self = user_data;
  double upper;
  double new_value;

  upper = gtk_adjustment_get_upper (adjustment);
  new_value = upper * self->initial_scroll_y - (gtk_adjustment_get_page_size (adjustment) / 2.0);

  gtk_adjustment_set_value (adjustment, new_value);

  g_signal_handler_disconnect (adjustment, self->vadj_changed_id);
}

void
cb_media_image_widget_scroll_to (CbMediaImageWidget *self,
                                 double              px,
                                 double              py)
{
  GtkAdjustment *hadj = gtk_scrolled_window_get_hadjustment (GTK_SCROLLED_WINDOW (self));
  GtkAdjustment *vadj = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (self));

  self->initial_scroll_x = px;
  self->initial_scroll_y = py;

  /* Defer the scrolling to a point where the adjustment actually has values */
  self->hadj_changed_id = g_signal_connect (G_OBJECT (hadj),
                                            "changed",
                                            G_CALLBACK (hadjustment_changed_cb),
                                            self);
  self->vadj_changed_id = g_signal_connect (G_OBJECT (vadj),
                                            "changed",
                                            G_CALLBACK (vadjustment_changed_cb),
                                            self);
}
