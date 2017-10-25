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

#include "CbTextView.h"
#include "corebird.h"


G_DEFINE_TYPE (CbTextView, cb_text_view, GTK_TYPE_WIDGET);

static void
cb_text_view_measure (GtkWidget      *widget,
                      GtkOrientation  orientation,
                      int             for_size,
                      int            *minimum,
                      int            *natural,
                      int            *minimum_baseline,
                      int            *natural_baseline)
{
  CbTextView *self = CB_TEXT_VIEW (widget);
  int min1, nat1;
  int min2, nat2;

  gtk_widget_measure (self->scrolled_window, orientation, for_size, &min1, &nat1, NULL, NULL);
  gtk_widget_measure (self->box,             orientation, for_size, &min2, &nat2, NULL, NULL);

  if (orientation == GTK_ORIENTATION_HORIZONTAL)
    {
      *minimum = MAX (min1, min2);
      *natural = MAX (nat1, nat2);
    }
  else /* VERTICAL */
    {
      *minimum = min1 + min2;
      *natural = nat1 + nat2;
    }
}

static void
cb_text_view_size_allocate (GtkWidget           *widget,
                            const GtkAllocation *allocation,
                            int                  baseline,
                            GtkAllocation       *out_clip)
{
  CbTextView *self = CB_TEXT_VIEW (widget);
  GtkAllocation child_alloc;
  int box_height;
  GdkRectangle child_clip;

  gtk_widget_measure (self->box, GTK_ORIENTATION_VERTICAL, allocation->width,
                      &box_height, NULL, NULL, NULL);

  child_alloc.x = 0;
  child_alloc.y = allocation->height - box_height;
  child_alloc.width = allocation->width;
  child_alloc.height = box_height;
  gtk_widget_size_allocate (self->box, &child_alloc, -1, out_clip);

  child_alloc.y = 0;
  child_alloc.height = allocation->height - box_height;
  gtk_widget_size_allocate (self->scrolled_window, &child_alloc, -1, &child_clip);

  gdk_rectangle_union (&child_clip, &child_clip, out_clip);
}

static void
cb_text_view_finalize (GObject *object)
{
  CbTextView *self = CB_TEXT_VIEW (object);

  gtk_widget_unparent (self->box);
  gtk_widget_unparent (self->scrolled_window);

  g_object_unref (self->account);

  G_OBJECT_CLASS (cb_text_view_parent_class)->finalize (object);
}

static void
cb_text_view_class_init (CbTextViewClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_text_view_finalize;

  widget_class->measure = cb_text_view_measure;
  widget_class->size_allocate = cb_text_view_size_allocate;

  gtk_widget_class_set_css_name (GTK_WIDGET_CLASS (klass), "textview");
}

static void
cb_text_view_init (CbTextView *self)
{
  gtk_widget_set_has_window (GTK_WIDGET (self), FALSE);

  self->scrolled_window = gtk_scrolled_window_new (NULL, NULL);
  gtk_widget_set_parent (self->scrolled_window, GTK_WIDGET (self));

  self->text_view = gtk_text_view_new ();
  gtk_text_view_set_accepts_tab (GTK_TEXT_VIEW (self->text_view), FALSE);
  gtk_text_view_set_wrap_mode (GTK_TEXT_VIEW (self->text_view), PANGO_WRAP_WORD_CHAR);
  gtk_container_add (GTK_CONTAINER (self->scrolled_window), self->text_view);

  self->box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->box), "dim-label");
  gtk_widget_set_parent (self->box, GTK_WIDGET (self));

  gtk_style_context_add_class (gtk_widget_get_style_context (GTK_WIDGET (self)), "view");
  gtk_style_context_add_class (gtk_widget_get_style_context (GTK_WIDGET (self)), "fancy");
}

GtkWidget *
cb_text_view_new (void)
{
  return GTK_WIDGET (g_object_new (CB_TYPE_TEXT_VIEW, NULL));
}

void
cb_text_view_set_account (CbTextView *self,
                          void       *account)
{
  g_set_object (&self->account, account);
}

void
cb_text_view_add_widget (CbTextView *self,
                         GtkWidget  *widget)
{
  gtk_container_add (GTK_CONTAINER (self->box), widget);
}

void
cb_text_view_insert_at_cursor (CbTextView *self,
                               const char *text)
{
  g_return_if_fail (text != NULL);

  gtk_text_buffer_insert_at_cursor (gtk_text_view_get_buffer (GTK_TEXT_VIEW (self->text_view)),
                                    text, -1);
}
