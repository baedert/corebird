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

#include "CbReplyIndicator.h"
#include <glib/gi18n.h>


G_DEFINE_TYPE (CbReplyIndicator, cb_reply_indicator, GTK_TYPE_WIDGET);

enum {
  CLICKED,
  LAST_SIGNAL
};
static guint signals[LAST_SIGNAL] = { 0 };


static void
cb_reply_indicator_finalize (GObject *object)
{
  CbReplyIndicator *self = CB_REPLY_INDICATOR (object);

  gtk_widget_unparent (self->revealer);

  G_OBJECT_CLASS (cb_reply_indicator_parent_class)->finalize (object);
}

static void
cb_reply_indicator_measure (GtkWidget      *widget,
                            GtkOrientation  orientation,
                            int             for_size,
                            int            *minimum,
                            int            *natural,
                            int            *minimum_baseline,
                            int            *natural_baseline)
{
  CbReplyIndicator *self = CB_REPLY_INDICATOR (widget);

  gtk_widget_measure (self->revealer, orientation, for_size,
                      minimum, natural, minimum_baseline, natural_baseline);
}

static void
cb_reply_indicator_size_allocate (GtkWidget           *widget,
                                  const GtkAllocation *allocation,
                                  int                  baseline,
                                  GtkAllocation       *out_clip)
{
  CbReplyIndicator *self = CB_REPLY_INDICATOR (widget);

  gtk_widget_size_allocate (self->revealer, allocation, baseline, out_clip);
}

static void
button_clicked_cb (GtkButton *button,
                   gpointer   user_data)
{
  CbReplyIndicator *self = user_data;

  g_signal_emit (self, signals[CLICKED], 0);
}

static void
cb_reply_indicator_init (CbReplyIndicator *self)
{
  GtkWidget *box;
  GtkWidget *w;

  gtk_widget_set_has_surface (GTK_WIDGET (self), FALSE);

  box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 0);

  w = gtk_image_new_from_icon_name ("go-up-symbolic");
  gtk_widget_set_hexpand (w, TRUE);
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_container_add (GTK_CONTAINER (box), w);
  gtk_container_add (GTK_CONTAINER (box), gtk_label_new (_("Show Conversation")));
  w = gtk_image_new_from_icon_name ("go-up-symbolic");
  gtk_widget_set_hexpand (w, TRUE);
  gtk_widget_set_halign (w, GTK_ALIGN_START);
  gtk_container_add (GTK_CONTAINER (box), w);

  gtk_style_context_add_class (gtk_widget_get_style_context (box), "dim-label");

  self->button = gtk_button_new ();
  gtk_container_add (GTK_CONTAINER (self->button), box);
  self->revealer = gtk_revealer_new ();

  gtk_container_add (GTK_CONTAINER (self->revealer), self->button);
  gtk_widget_set_parent (self->revealer, GTK_WIDGET (self));

  g_signal_connect (self->button, "clicked", G_CALLBACK (button_clicked_cb), self);
}

static void
cb_reply_indicator_class_init (CbReplyIndicatorClass *klass)
{
  GObjectClass *object_class = (GObjectClass *)klass;
  GtkWidgetClass *widget_class = (GtkWidgetClass *)klass;

  object_class->finalize = cb_reply_indicator_finalize;

  widget_class->measure = cb_reply_indicator_measure;
  widget_class->size_allocate = cb_reply_indicator_size_allocate;

  signals[CLICKED] = g_signal_new ("clicked",
                                   G_OBJECT_CLASS_TYPE (object_class),
                                   G_SIGNAL_RUN_FIRST,
                                   0,
                                   NULL, NULL,
                                   NULL, G_TYPE_NONE, 0);

  gtk_widget_class_set_css_name (widget_class, "replyindicator");
}

void
cb_reply_indicator_set_replies_available (CbReplyIndicator *self,
                                          gboolean          replies_available)
{
  gtk_revealer_set_reveal_child (GTK_REVEALER (self->revealer), replies_available);
}

gboolean
cb_reply_indicator_get_replies_available (CbReplyIndicator *self)
{
  return gtk_revealer_get_reveal_child (GTK_REVEALER (self->revealer));
}
