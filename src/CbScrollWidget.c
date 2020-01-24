/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2019 Timm Bäder
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

#include "CbScrollWidget.h"

struct _CbScrollWidgetPrivate
{
  GtkWidget *scrolled_window;
};
typedef struct _CbScrollWidgetPrivate CbScrollWidgetPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (CbScrollWidget, cb_scroll_widget, GTK_TYPE_WIDGET);

static void
cb_scroll_widget_finalize (GObject *object)
{
  CbScrollWidget *self = CB_SCROLL_WIDGET (object);
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);

  G_OBJECT_CLASS (cb_scroll_widget_parent_class)->finalize (object);
}

static void
cb_scroll_widget_class_init (CbScrollWidgetClass *klass)
{
  GObjectClass *object_class   = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);
  /*GtkContainerClass *container_class = GTK_CONTAINER_CLASS (klass);*/

  object_class->finalize = cb_scroll_widget_finalize;

  /*container_class->add = cb_scroll_widget_add;*/

  gtk_widget_class_set_layout_manager_type (widget_class, GTK_TYPE_BIN_LAYOUT);
}

static void
cb_scroll_widget_init (CbScrollWidget *self)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);

  priv->scrolled_window = gtk_scrolled_window_new (NULL, NULL);
  gtk_widget_set_parent (priv->scrolled_window, GTK_WIDGET (self));
}

GtkWidget *
cb_scroll_widget_new (void)
{
  GObject *o = g_object_new (CB_TYPE_SCROLL_WIDGET, NULL);

  g_assert (GTK_IS_WIDGET (o));

  return GTK_WIDGET (o);
}

void
cb_scroll_widget_set_policy (CbScrollWidget *self,
                             GtkPolicyType    hscroll_policy,
                             GtkPolicyType    vscroll_policy)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);

  g_assert (CB_IS_SCROLL_WIDGET (self));

  gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (priv->scrolled_window),
                                  hscroll_policy,
                                  vscroll_policy);
}

gboolean
cb_scroll_widget_scrolled_down (CbScrollWidget *self)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);
  GtkAdjustment *a;

  g_assert (CB_IS_SCROLL_WIDGET (self));

  a = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (priv->scrolled_window));

  return gtk_adjustment_get_value (a) >=
         gtk_adjustment_get_upper (a) - gtk_adjustment_get_page_size (a) - 5;
}

gboolean
cb_scroll_widget_scrolled_up (CbScrollWidget *self)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);
  GtkAdjustment *a;

  g_assert (CB_IS_SCROLL_WIDGET (self));

  a = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (priv->scrolled_window));

  return gtk_adjustment_get_value (a) <= 5;
}

void
cb_scroll_widget_scroll_down_next (CbScrollWidget *self,
                                   gboolean        animate,
                                   gboolean        force_start)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);
}
void
cb_scroll_widget_scroll_up_next (CbScrollWidget *self,
                                 gboolean        animate,
                                 gboolean        force_start)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);
}

void
cb_scroll_widget_balance_next_upper_change (CbScrollWidget *self,
                                            int             mode)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);
}

GtkAdjustment *
cb_scroll_widget_get_vadjustment (CbScrollWidget *self)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);
  GtkAdjustment *adjustment;

  adjustment = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (priv->scrolled_window));

  g_assert (GTK_IS_ADJUSTMENT (adjustment));

  return adjustment;
}

void
cb_scroll_widget_add (CbScrollWidget *self,
                      GtkWidget      *child)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);

  gtk_container_add (GTK_CONTAINER (priv->scrolled_window), child);
}
