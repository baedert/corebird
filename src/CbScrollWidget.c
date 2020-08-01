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

  gint64 start_time;
  gint64 end_time;
  double transition_diff;
  double transition_start_value;
};
typedef struct _CbScrollWidgetPrivate CbScrollWidgetPrivate;

enum
{
  SIGNAL_SCROLLED_TO_START,
  SIGNAL_SCROLLED_TO_END,
  LAST_SIGNAL
};
static guint scroll_widget_signals[LAST_SIGNAL] = { 0 };

static GtkBuildableIface *parent_buildable_iface;
static void cb_scroll_widget_buildable_init (GtkBuildableIface *iface);

G_DEFINE_TYPE_WITH_CODE (CbScrollWidget, cb_scroll_widget, GTK_TYPE_WIDGET,
                         G_ADD_PRIVATE (CbScrollWidget)
                         G_IMPLEMENT_INTERFACE (GTK_TYPE_BUILDABLE,
                                                cb_scroll_widget_buildable_init));


static void
cb_scroll_widget_buildable_add_child (GtkBuildable  *buildable,
                                      GtkBuilder    *builder,
                                      GObject       *child,
                                      const char    *type)
{
  CbScrollWidget *self = CB_SCROLL_WIDGET (buildable);
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);
  if (GTK_IS_WIDGET (child) &&
      gtk_widget_get_parent (GTK_WIDGET (child)) == NULL)
    {
      if (type)
        GTK_BUILDER_WARN_INVALID_CHILD_TYPE (buildable, type);
      else
        gtk_scrolled_window_set_child (GTK_SCROLLED_WINDOW (priv->scrolled_window), GTK_WIDGET (child));
    }
  else
    {
      parent_buildable_iface->add_child (buildable, builder, child, type);
    }
}


static void
adjustment_value_changed_cb (GObject    *source,
                             GParamSpec *pspec,
                             gpointer    user_data)
{
  CbScrollWidget *self = user_data;

  if (cb_scroll_widget_scrolled_down (self))
    g_signal_emit (self, scroll_widget_signals[SIGNAL_SCROLLED_TO_END], 0);

  if (cb_scroll_widget_scrolled_up (self))
    g_signal_emit (self, scroll_widget_signals[SIGNAL_SCROLLED_TO_START], 0);
}

static void
cb_scroll_widget_buildable_init (GtkBuildableIface *iface)
{
  parent_buildable_iface = g_type_interface_peek_parent (iface);
  iface->add_child = cb_scroll_widget_buildable_add_child;
}

static void
cb_scroll_widget_dispose (GObject *object)
{
  CbScrollWidget *self = CB_SCROLL_WIDGET (object);
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);

  g_clear_pointer (&priv->scrolled_window, gtk_widget_unparent);

  G_OBJECT_CLASS (cb_scroll_widget_parent_class)->dispose (object);
}

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

  object_class->dispose = cb_scroll_widget_dispose;
  object_class->finalize = cb_scroll_widget_finalize;

  scroll_widget_signals[SIGNAL_SCROLLED_TO_START] =
    g_signal_new ("scrolled-to-start",
                  G_OBJECT_CLASS_TYPE (object_class),
                  G_SIGNAL_RUN_FIRST,
                  0,
                  NULL, NULL,
                  NULL, G_TYPE_NONE, 0);

  scroll_widget_signals[SIGNAL_SCROLLED_TO_END] =
    g_signal_new ("scrolled-to-end",
                  G_OBJECT_CLASS_TYPE (object_class),
                  G_SIGNAL_RUN_FIRST,
                  0,
                  NULL, NULL,
                  NULL, G_TYPE_NONE, 0);

  gtk_widget_class_set_layout_manager_type (widget_class, GTK_TYPE_BIN_LAYOUT);
}

static void
cb_scroll_widget_init (CbScrollWidget *self)
{
  CbScrollWidgetPrivate *priv = cb_scroll_widget_get_instance_private (self);
  GtkAdjustment *vadjustment;

  priv->scrolled_window = gtk_scrolled_window_new ();
  gtk_widget_set_parent (priv->scrolled_window, GTK_WIDGET (self));

  /* TODO: Do we also need to connect to notify::upper + notify::page-size? */
  vadjustment = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (priv->scrolled_window));
  g_signal_connect (vadjustment, "notify::value", G_CALLBACK (adjustment_value_changed_cb), self);
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
                             GtkPolicyType   hscroll_policy,
                             GtkPolicyType   vscroll_policy)
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
  GtkAdjustment *adjustment = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (priv->scrolled_window));
  GtkSettings *settings = gtk_widget_get_settings (GTK_WIDGET (self));
  GdkFrameClock *frame_clock = gtk_widget_get_frame_clock (GTK_WIDGET (self));
  gboolean animations_enabled;

  if (!gtk_widget_get_mapped (GTK_WIDGET (self)))
    goto skip;

  g_object_get (settings, "gtk-enable-animations", &animations_enabled, NULL);

  if (force_start)
    {
      if (animations_enabled && animate)
        {
        }
      else
        {
          goto skip;
        }
    }
  else
    {
    }

  return;
skip:
  gtk_adjustment_set_value (adjustment, 0);
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

  gtk_scrolled_window_set_child (GTK_SCROLLED_WINDOW (priv->scrolled_window), GTK_WIDGET (child));
}
