


/* -*- Mode: C; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/*
 * Copyright (c) 2013 Red Hat, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Author: Alexander Larsson <alexl@redhat.com>
 *
 */

#include <gtk/gtk.h>
#include "gd-stack.h"
#include <math.h>
#include <string.h>

/* TODO:
 *  more transiton types (slides)
 *  filter events out events to the last_child widget during transitions
 */

enum  {
  PROP_0,
  PROP_HOMOGENEOUS,
  PROP_VISIBLE_CHILD,
  PROP_VISIBLE_CHILD_NAME,
  PROP_TRANSITION_DURATION,
  PROP_TRANSITION_TYPE,
};

enum
{
  CHILD_PROP_0,
  CHILD_PROP_NAME,
  CHILD_PROP_TITLE,
  CHILD_PROP_SYMBOLIC_ICON_NAME,
  CHILD_PROP_POSITION
};

typedef struct _GdStackChildInfo GdStackChildInfo;

struct _GdStackChildInfo {
  GtkWidget *widget;
  char *name;
  char *title;
  char *symbolic_icon_name;
};

struct _GdStackPrivate {
  GList *children;

  GdkWindow* bin_window;
  GdkWindow* view_window;

  GdStackChildInfo *visible_child;

  gboolean homogeneous;

  GdStackTransitionType transition_type;
  gint transition_duration;

  GdStackChildInfo *last_visible_child;
  cairo_surface_t *last_visible_surface;
  GtkAllocation last_visible_surface_allocation;
  gdouble transition_pos;

  guint tick_id;
  gint64 start_time;
  gint64 end_time;
};

#define GTK_PARAM_READWRITE G_PARAM_READWRITE|G_PARAM_STATIC_NAME|G_PARAM_STATIC_NICK|G_PARAM_STATIC_BLURB
#define GD_STACK_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), GD_TYPE_STACK, GdStackPrivate))

static void     gd_stack_add                            (GtkContainer  *widget,
							 GtkWidget     *child);
static void     gd_stack_remove                         (GtkContainer  *widget,
							 GtkWidget     *child);
static void     gd_stack_forall                         (GtkContainer *container,
							 gboolean      include_internals,
							 GtkCallback   callback,
							 gpointer      callback_data);
static void     gd_stack_compute_expand                 (GtkWidget      *widget,
							 gboolean       *hexpand,
							 gboolean       *vexpand);
static void     gd_stack_size_allocate                  (GtkWidget     *widget,
							 GtkAllocation *allocation);
static gboolean gd_stack_draw                           (GtkWidget     *widget,
							 cairo_t       *cr);
static void     gd_stack_get_preferred_height           (GtkWidget     *widget,
							 gint          *minimum_height,
							 gint          *natural_height);
static void     gd_stack_get_preferred_height_for_width (GtkWidget     *widget,
							 gint           width,
							 gint          *minimum_height,
							 gint          *natural_height);
static void     gd_stack_get_preferred_width            (GtkWidget     *widget,
							 gint          *minimum_width,
							 gint          *natural_width);
static void     gd_stack_get_preferred_width_for_height (GtkWidget     *widget,
							 gint           height,
							 gint          *minimum_width,
							 gint          *natural_width);
static void     gd_stack_finalize                       (GObject       *obj);
static void     gd_stack_get_property                   (GObject       *object,
							 guint          property_id,
							 GValue        *value,
							 GParamSpec    *pspec);
static void     gd_stack_set_property                   (GObject       *object,
							 guint          property_id,
							 const GValue  *value,
							 GParamSpec    *pspec);
static void     gd_stack_get_child_property             (GtkContainer *container,
                                                         GtkWidget    *child,
                                                         guint         property_id,
                                                         GValue       *value,
                                                         GParamSpec   *pspec);
static void     gd_stack_set_child_property             (GtkContainer *container,
                                                         GtkWidget    *child,
                                                         guint         property_id,
                                                         const GValue *value,
                                                         GParamSpec   *pspec);
static void     gd_stack_unschedule_ticks               (GdStack       *stack);
static int      get_bin_window_x                        (GdStack       *stack,
                                                         GtkAllocation *allocation);

G_DEFINE_TYPE(GdStack, gd_stack, GTK_TYPE_CONTAINER);

static void
gd_stack_init (GdStack *stack)
{
  stack->priv = GD_STACK_GET_PRIVATE (stack);

  gtk_widget_set_has_window ((GtkWidget*) stack, TRUE);
  gtk_widget_set_redraw_on_allocate ((GtkWidget*) stack, TRUE);
}

static void
gd_stack_finalize (GObject* obj)
{
  GdStack *stack = GD_STACK (obj);
  GdStackPrivate *priv = stack->priv;

  gd_stack_unschedule_ticks (stack);

  if (priv->last_visible_surface != NULL)
    cairo_surface_destroy (priv->last_visible_surface);

  G_OBJECT_CLASS (gd_stack_parent_class)->finalize (obj);
}

static void
gd_stack_get_property (GObject *object,
		       guint property_id,
		       GValue *value,
		       GParamSpec *pspec)
{
  GdStack *stack = GD_STACK (object);
  GdStackPrivate *priv = stack->priv;

  switch (property_id)
    {
    case PROP_HOMOGENEOUS:
      g_value_set_boolean (value, priv->homogeneous);
      break;
    case PROP_VISIBLE_CHILD:
      g_value_set_object (value, priv->visible_child);
      break;
    case PROP_VISIBLE_CHILD_NAME:
      g_value_set_string (value, gd_stack_get_visible_child_name (stack));
      break;
    case PROP_TRANSITION_DURATION:
      g_value_set_int (value, gd_stack_get_transition_duration (stack));
      break;
    case PROP_TRANSITION_TYPE:
      g_value_set_int (value, gd_stack_get_transition_type (stack));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
gd_stack_set_property (GObject *object,
		       guint property_id,
		       const GValue *value,
		       GParamSpec *pspec)
{
  GdStack *stack = GD_STACK (object);

  switch (property_id)
    {
    case PROP_HOMOGENEOUS:
      gd_stack_set_homogeneous (stack, g_value_get_boolean (value));
      break;
    case PROP_VISIBLE_CHILD:
      gd_stack_set_visible_child (stack, g_value_get_object (value));
      break;
    case PROP_VISIBLE_CHILD_NAME:
      gd_stack_set_visible_child_name (stack, g_value_get_string (value));
      break;
    case PROP_TRANSITION_DURATION:
      gd_stack_set_transition_duration (stack, g_value_get_int (value));
      break;
    case PROP_TRANSITION_TYPE:
      gd_stack_set_transition_type (stack, g_value_get_int (value));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
gd_stack_realize (GtkWidget *widget)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;
  GtkAllocation allocation;
  GdkWindowAttr attributes = { 0 };
  GdkWindowAttributesType attributes_mask;
  GdStackChildInfo *info;
  GList *l;

  gtk_widget_set_realized (widget, TRUE);

  gtk_widget_get_allocation (widget, &allocation);

  attributes.x = allocation.x;
  attributes.y = allocation.y;
  attributes.width = allocation.width;
  attributes.height = allocation.height;
  attributes.window_type = GDK_WINDOW_CHILD;
  attributes.wclass = GDK_INPUT_OUTPUT;
  attributes.visual = gtk_widget_get_visual (widget);
  attributes.event_mask =
    gtk_widget_get_events (widget) | GDK_EXPOSURE_MASK;
  attributes_mask = (GDK_WA_X | GDK_WA_Y) | GDK_WA_VISUAL;

  priv->view_window =
    gdk_window_new (gtk_widget_get_parent_window ((GtkWidget*) stack),
                    &attributes, attributes_mask);
  gtk_widget_set_window (widget, priv->view_window);
  gtk_widget_register_window (widget, priv->view_window);

  attributes.x = get_bin_window_x (stack, &allocation);
  attributes.y = 0;
  attributes.width = allocation.width;
  attributes.height = allocation.height;

  priv->bin_window =
    gdk_window_new (priv->view_window, &attributes, attributes_mask);
  gtk_widget_register_window (widget, priv->bin_window);

  for (l = priv->children; l != NULL; l = l->next)
    {
      info = l->data;

      gtk_widget_set_parent_window (info->widget, priv->bin_window);
    }

  gdk_window_show (priv->bin_window);
}

static void
gd_stack_unrealize (GtkWidget* widget)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;

  gtk_widget_unregister_window (widget, priv->bin_window);
  gdk_window_destroy (priv->bin_window);
  priv->view_window = NULL;

  GTK_WIDGET_CLASS (gd_stack_parent_class)->unrealize (widget);
}

static void
gd_stack_class_init (GdStackClass * klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);
  GtkContainerClass *container_class = GTK_CONTAINER_CLASS (klass);

  object_class->get_property = gd_stack_get_property;
  object_class->set_property = gd_stack_set_property;
  object_class->finalize = gd_stack_finalize;

  widget_class->size_allocate = gd_stack_size_allocate;
  widget_class->draw = gd_stack_draw;
  widget_class->realize = gd_stack_realize;
  widget_class->unrealize = gd_stack_unrealize;
  widget_class->get_preferred_height = gd_stack_get_preferred_height;
  widget_class->get_preferred_height_for_width = gd_stack_get_preferred_height_for_width;
  widget_class->get_preferred_width = gd_stack_get_preferred_width;
  widget_class->get_preferred_width_for_height = gd_stack_get_preferred_width_for_height;
  widget_class->compute_expand = gd_stack_compute_expand;

  container_class->add = gd_stack_add;
  container_class->remove = gd_stack_remove;
  container_class->forall = gd_stack_forall;
  container_class->set_child_property = gd_stack_set_child_property;
  container_class->get_child_property = gd_stack_get_child_property;
  /*container_class->get_path_for_child = gd_stack_get_path_for_child; */
  gtk_container_class_handle_border_width (container_class);

  g_object_class_install_property (object_class,
				   PROP_HOMOGENEOUS,
				   g_param_spec_boolean ("homogeneous",
							 "Homogeneous",
							 "Homogeneous sizing",
							 TRUE,
							 GTK_PARAM_READWRITE | G_PARAM_CONSTRUCT));
  g_object_class_install_property (object_class,
				   PROP_VISIBLE_CHILD,
				   g_param_spec_object ("visible-child",
							"Visible child",
							"The widget currently visible in the stack",
							GTK_TYPE_WIDGET,
							GTK_PARAM_READWRITE));
  g_object_class_install_property (object_class,
				   PROP_VISIBLE_CHILD_NAME,
				   g_param_spec_string ("visible-child-name",
							"Name of visible child",
							"The name of the widget currently visible in the stack",
							NULL,
							GTK_PARAM_READWRITE));
  g_object_class_install_property (object_class,
                                   PROP_TRANSITION_DURATION,
                                   g_param_spec_int ("transition-duration",
                                                     "Transition duration",
                                                     "The animation duration, in milliseconds",
                                                     G_MININT, G_MAXINT,
                                                     200,
                                                     GTK_PARAM_READWRITE | G_PARAM_CONSTRUCT));
  g_object_class_install_property (object_class,
                                   PROP_TRANSITION_TYPE,
                                   g_param_spec_int ("transition-type",
                                                     "Transition type",
                                                     "The type of animation used to transition",
                                                     GD_STACK_TRANSITION_TYPE_NONE,
                                                     G_MAXINT,
                                                     GD_STACK_TRANSITION_TYPE_NONE,
                                                     GTK_PARAM_READWRITE | G_PARAM_CONSTRUCT));

  gtk_container_class_install_child_property (container_class, CHILD_PROP_NAME,
    g_param_spec_string ("name",
                         "Name",
                         "The name of the child page",
                         NULL,
                         GTK_PARAM_READWRITE));

  gtk_container_class_install_child_property (container_class, CHILD_PROP_TITLE,
    g_param_spec_string ("title",
                         "Title",
                         "The title of the child page",
                         NULL,
                         GTK_PARAM_READWRITE));

  gtk_container_class_install_child_property (container_class, CHILD_PROP_SYMBOLIC_ICON_NAME,
    g_param_spec_string ("symbolic-icon-name",
                         "Symbolic icon name",
                         "The symbolic icon name of the child page",
                         NULL,
                         GTK_PARAM_READWRITE));

  gtk_container_class_install_child_property (container_class, CHILD_PROP_POSITION,
    g_param_spec_int ("position",
                      "Position",
                      "The index of the child in the parent",
                      -1, G_MAXINT, 0,
                      GTK_PARAM_READWRITE));

  g_type_class_add_private (klass, sizeof (GdStackPrivate));
}


GtkWidget *
gd_stack_new (void)
{
  return g_object_new (GD_TYPE_STACK, NULL);
}

static GdStackChildInfo *
find_child_info_for_widget (GdStack *stack,
                            GtkWidget *child)
{
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *info;
  GList *l;

  for (l = priv->children; l != NULL; l = l->next)
    {
      info = l->data;
      if (info->widget == child)
        return info;
    }

  return NULL;
}

static void
reorder_child (GdStack   *stack,
               GtkWidget *child,
               gint       position)
{
  GdStackPrivate *priv;
  GList *l;
  GList *old_link = NULL;
  GList *new_link = NULL;
  GdStackChildInfo *child_info;
  gint num = 0;

  priv = stack->priv;

  l = priv->children;

  /* Loop to find the old position and link of child, new link of child and
   * total number of children. new_link will be NULL if the child should be
   * moved to the end (in case of position being < 0 || >= num)
   */
  while (l && (new_link == NULL || old_link == NULL))
    {
      /* Record the new position if found */
      if (position == num)
        new_link = l;

      if (old_link == NULL)
        {
          GdStackChildInfo *info;
          info = l->data;

          /* Keep trying to find the current position and link location of the
             child */
          if (info->widget == child)
            {
              old_link = l;
              child_info = info;
            }
        }

      l = g_list_next (l);
      num++;
    }

  g_return_if_fail (old_link != NULL);

  if (old_link == new_link || (g_list_next (old_link) == NULL && new_link == NULL))
    return;

  priv->children = g_list_delete_link (priv->children, old_link);
  priv->children = g_list_insert_before (priv->children, new_link, child_info);

  gtk_widget_child_notify (child, "position");
}

static void
gd_stack_get_child_property (GtkContainer *container,
                             GtkWidget    *child,
                             guint         property_id,
                             GValue       *value,
                             GParamSpec   *pspec)
{
  GdStack *stack = GD_STACK (container);
  GdStackChildInfo *info;
  GList *list;
  guint i;

  info = find_child_info_for_widget (stack, child);
  if (info == NULL)
    {
      GTK_CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID (container, property_id, pspec);
      return;
    }

  switch (property_id)
    {
    case CHILD_PROP_NAME:
      g_value_set_string (value, info->name);
      break;

    case CHILD_PROP_TITLE:
      g_value_set_string (value, info->title);
      break;

    case CHILD_PROP_SYMBOLIC_ICON_NAME:
      g_value_set_string (value, info->symbolic_icon_name);
      break;

    case CHILD_PROP_POSITION:
      i = 0;
      for (list = stack->priv->children; list != NULL; list = g_list_next (list))
        {
          if (info == list->data)
            break;
          ++i;
        }
      g_value_set_int (value, i);
      break;

    default:
      GTK_CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID (container, property_id, pspec);
      break;
    }
}

static void
gd_stack_set_child_property (GtkContainer *container,
                             GtkWidget    *child,
                             guint         property_id,
                             const GValue *value,
                             GParamSpec   *pspec)
{
  GdStack *stack = GD_STACK (container);
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *info;

  info = find_child_info_for_widget (stack, child);
  if (info == NULL)
    {
      GTK_CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID (container, property_id, pspec);
      return;
    }

  switch (property_id)
    {
    case CHILD_PROP_NAME:
      g_free (info->name);
      info->name = g_value_dup_string (value);

      gtk_container_child_notify (container, child, "name");

      if (priv->visible_child == info)
        g_object_notify (G_OBJECT (stack), "visible-child-name");

      break;

    case CHILD_PROP_TITLE:
      g_free (info->title);
      info->title = g_value_dup_string (value);
      gtk_container_child_notify (container, child, "title");
      break;

    case CHILD_PROP_SYMBOLIC_ICON_NAME:
      g_free (info->symbolic_icon_name);
      info->symbolic_icon_name = g_value_dup_string (value);
      gtk_container_child_notify (container, child, "symbolic-icon-name");
      break;

    case CHILD_PROP_POSITION:
      reorder_child (stack, child, g_value_get_int (value));
      break;

    default:
      GTK_CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID (container, property_id, pspec);
      break;
    }
}

/* From clutter-easing.c, based on Robert Penner's
 * infamous easing equations, MIT license. */
static double
ease_out_cubic (double t)
{
  double p = t - 1;
  return p * p * p + 1;
}

static int
get_bin_window_x (GdStack *stack, GtkAllocation *allocation)
{
  GdStackPrivate *priv = stack->priv;
  int x = 0;

  if (priv->transition_pos < 1.0)
    {
      if (priv->transition_type == GD_STACK_TRANSITION_TYPE_SLIDE_LEFT)
        x = allocation->width * (1 - ease_out_cubic (priv->transition_pos));
      if (priv->transition_type == GD_STACK_TRANSITION_TYPE_SLIDE_RIGHT)
        x = -allocation->width * (1 - ease_out_cubic (priv->transition_pos));
    }

  return x;
}

static gboolean
gd_stack_set_transition_position (GdStack *stack,
                                  gdouble pos)
{
  GdStackPrivate *priv = stack->priv;
  gboolean done;

  priv->transition_pos = pos;
  gtk_widget_queue_draw (GTK_WIDGET (stack));

  if (priv->bin_window != NULL &&
      (priv->transition_type == GD_STACK_TRANSITION_TYPE_SLIDE_LEFT ||
       priv->transition_type == GD_STACK_TRANSITION_TYPE_SLIDE_RIGHT))
    {
      GtkAllocation allocation;
      gtk_widget_get_allocation (GTK_WIDGET (stack), &allocation);
      gdk_window_move (priv->bin_window,
                       get_bin_window_x (stack, &allocation), 0);
    }

  done = pos >= 1.0;

  if (done || priv->last_visible_surface != NULL)
    {
      if (priv->last_visible_child)
        {
          gtk_widget_set_child_visible (priv->last_visible_child->widget, FALSE);
          priv->last_visible_child = NULL;
        }
    }

  if (done)
    {
      if (priv->last_visible_surface != NULL)
        {
          cairo_surface_destroy (priv->last_visible_surface);
          priv->last_visible_surface = NULL;
        }

      gtk_widget_queue_resize (GTK_WIDGET (stack));
    }

  return done;
}

static gboolean
gd_stack_transition_cb (GdStack *stack,
                        GdkFrameClock *frame_clock,
                        gpointer user_data)
{
  GdStackPrivate *priv = stack->priv;
  gint64 now;
  gdouble t;

  now = gdk_frame_clock_get_frame_time (frame_clock);

  t = 1.0;
  if (now < priv->end_time)
    t = (now - priv->start_time) / (double) (priv->end_time - priv->start_time);

  /* Finish animation early if not mapped anymore */
  if (!gtk_widget_get_mapped (GTK_WIDGET (stack)))
    t = 1.0;

  if (gd_stack_set_transition_position (stack, t))
    {
      gtk_widget_set_opacity (GTK_WIDGET (stack), 1.0);
      priv->tick_id = 0;

      return FALSE;
    }

  return TRUE;
}

static void
gd_stack_schedule_ticks (GdStack *stack)
{
  GdStackPrivate *priv = stack->priv;

  if (priv->tick_id == 0)
    {
      priv->tick_id =
        gtk_widget_add_tick_callback (GTK_WIDGET (stack), (GtkTickCallback)gd_stack_transition_cb, stack, NULL);
    }
}

static void
gd_stack_unschedule_ticks (GdStack *stack)
{
  GdStackPrivate *priv = stack->priv;

  if (priv->tick_id != 0)
    {
      gtk_widget_remove_tick_callback (GTK_WIDGET (stack), priv->tick_id);
      priv->tick_id = 0;
    }
}

static void
gd_stack_start_transition (GdStack *stack)
{
  GdStackPrivate *priv = stack->priv;
  GtkWidget *widget = GTK_WIDGET (stack);
  gboolean animations_enabled;

  g_object_get (gtk_widget_get_settings (widget),
                "gtk-enable-animations", &animations_enabled,
                NULL);

  if (gtk_widget_get_mapped (widget) &&
      animations_enabled &&
      priv->transition_type != GD_STACK_TRANSITION_TYPE_NONE &&
      priv->last_visible_child != NULL)
    {
      gtk_widget_set_opacity (widget, 0.999);

      priv->transition_pos = 0.0;
      priv->start_time = gdk_frame_clock_get_frame_time (gtk_widget_get_frame_clock (widget));
      priv->end_time = priv->start_time + (priv->transition_duration * 1000);
      gd_stack_schedule_ticks (stack);
    }
  else
    {
      gd_stack_unschedule_ticks (stack);
      gd_stack_set_transition_position (stack, 1.0);
    }
}

static void
set_visible_child (GdStack *stack,
		   GdStackChildInfo *child_info)
{
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *info;
  GtkWidget *widget = GTK_WIDGET (stack);
  GList *l;

  /* If none, pick first visible */
  if (child_info == NULL)
    {
      for (l = priv->children; l != NULL; l = l->next)
	{
          info = l->data;
	  if (gtk_widget_get_visible (info->widget))
	    {
	      child_info = info;
	      break;
	    }
	}
    }

  if (child_info == priv->visible_child)
    return;

  if (priv->last_visible_child)
    gtk_widget_set_child_visible (priv->last_visible_child->widget, FALSE);
  priv->last_visible_child = NULL;

  if (priv->last_visible_surface != NULL)
    cairo_surface_destroy (priv->last_visible_surface);
  priv->last_visible_surface = NULL;

  if (priv->visible_child && priv->visible_child->widget)
    {
      if (gtk_widget_is_visible (widget))
        priv->last_visible_child = priv->visible_child;
      else
        gtk_widget_set_child_visible (priv->visible_child->widget, FALSE);
    }

  priv->visible_child = child_info;

  if (child_info)
    gtk_widget_set_child_visible (child_info->widget, TRUE);

  gtk_widget_queue_resize (GTK_WIDGET (stack));
  gtk_widget_queue_draw (GTK_WIDGET (stack));

  g_object_notify (G_OBJECT (stack), "visible-child");
  g_object_notify (G_OBJECT (stack), "visible-child-name");

  gd_stack_start_transition (stack);
}

static void
stack_child_visibility_notify_cb (GObject *obj,
				  GParamSpec *pspec,
				  gpointer user_data)
{
  GdStack *stack = GD_STACK (user_data);
  GdStackPrivate *priv = stack->priv;
  GtkWidget *child = GTK_WIDGET (obj);
  GdStackChildInfo *child_info;

  child_info = find_child_info_for_widget (stack, child);

  if (priv->visible_child == NULL &&
      gtk_widget_get_visible (child))
    set_visible_child (stack, child_info);
  else if (priv->visible_child == child_info &&
	   !gtk_widget_get_visible (child))
    set_visible_child (stack, NULL);

  if (child_info == priv->last_visible_child)
    {
      gtk_widget_set_child_visible (priv->last_visible_child->widget, FALSE);
      priv->last_visible_child = NULL;
    }
}

void
gd_stack_add_titled (GdStack    *stack,
                     GtkWidget  *child,
                     const char *name,
                     const char *title)
{
  g_return_if_fail (GD_IS_STACK (stack));
  g_return_if_fail (GTK_IS_WIDGET (child));

  gtk_container_add_with_properties (GTK_CONTAINER (stack),
                                     child,
                                     "name", name,
                                     "title", title,
                                     NULL);
}

void
gd_stack_add_named (GdStack    *stack,
                    GtkWidget  *child,
                    const char *name)
{
  g_return_if_fail (GD_IS_STACK (stack));
  g_return_if_fail (GTK_IS_WIDGET (child));

  gtk_container_add_with_properties (GTK_CONTAINER (stack),
                                     child,
                                     "name", name,
                                     NULL);
}

static void
gd_stack_add (GtkContainer *container,
	      GtkWidget *child)
{
  GdStack *stack = GD_STACK (container);
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *child_info;

  g_return_if_fail (child != NULL);

  child_info = g_slice_new (GdStackChildInfo);
  child_info->widget = child;
  child_info->name = NULL;
  child_info->title = NULL;
  child_info->symbolic_icon_name = NULL;

  priv->children = g_list_append (priv->children, child_info);

  gtk_widget_set_parent_window (child, priv->bin_window);
  gtk_widget_set_parent (child, GTK_WIDGET (stack));

  g_signal_connect (child, "notify::visible",
                    G_CALLBACK (stack_child_visibility_notify_cb), stack);

  gtk_widget_child_notify (child, "position");

  if (priv->visible_child == NULL &&
      gtk_widget_get_visible (child))
    set_visible_child (stack, child_info);
  else
    gtk_widget_set_child_visible (child, FALSE);

  if (priv->homogeneous || priv->visible_child == child_info)
    gtk_widget_queue_resize (GTK_WIDGET (stack));
}

static void
gd_stack_remove (GtkContainer *container,
		 GtkWidget    *child)
{
  GdStack *stack = GD_STACK (container);
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *child_info;
  gboolean was_visible;

  child_info = find_child_info_for_widget (stack, child);
  if (child_info == NULL)
    return;

  priv->children = g_list_remove (priv->children, child_info);

  g_signal_handlers_disconnect_by_func (child,
					stack_child_visibility_notify_cb,
					stack);

  was_visible = gtk_widget_get_visible (child);

  child_info->widget = NULL;

  if (priv->visible_child == child_info)
    set_visible_child (stack, NULL);

  if (priv->last_visible_child == child_info)
    priv->last_visible_child = NULL;

  gtk_widget_unparent (child);

  g_free (child_info->name);
  g_free (child_info->title);
  g_free (child_info->symbolic_icon_name);
  g_slice_free (GdStackChildInfo, child_info);

  if (priv->homogeneous && was_visible)
    gtk_widget_queue_resize (GTK_WIDGET (stack));
}

void
gd_stack_set_homogeneous (GdStack *stack,
			 gboolean homogeneous)
{
  GdStackPrivate *priv;

  g_return_if_fail (GD_IS_STACK (stack));

  priv = stack->priv;

  homogeneous = !!homogeneous;

  if (priv->homogeneous == homogeneous)
    return;

  priv->homogeneous = homogeneous;

  if (gtk_widget_get_visible (GTK_WIDGET(stack)))
    gtk_widget_queue_resize (GTK_WIDGET (stack));

  g_object_notify (G_OBJECT (stack), "homogeneous");
}

gboolean
gd_stack_get_homogeneous (GdStack *stack)
{
  g_return_val_if_fail (GD_IS_STACK (stack), FALSE);

  return stack->priv->homogeneous;
}

gint
gd_stack_get_transition_duration (GdStack *stack)
{
  g_return_val_if_fail (GD_IS_STACK (stack), 0);

  return stack->priv->transition_duration;
}

void
gd_stack_set_transition_duration (GdStack *stack,
                                  gint value)
{
  g_return_if_fail (GD_IS_STACK (stack));

  stack->priv->transition_duration = value;
  g_object_notify (G_OBJECT (stack), "transition-duration");
}

GdStackTransitionType
gd_stack_get_transition_type (GdStack *stack)
{
  g_return_val_if_fail (GD_IS_STACK (stack), GD_STACK_TRANSITION_TYPE_NONE);

  return stack->priv->transition_type;
}

void
gd_stack_set_transition_type (GdStack *stack,
                              GdStackTransitionType value)
{
  g_return_if_fail (GD_IS_STACK (stack));

  stack->priv->transition_type = value;
  g_object_notify (G_OBJECT (stack), "transition-type");
}

/**
 * gd_stack_get_visible_child:
 * @stack: a #GdStack
 *
 * Gets the currently visible child of the #GdStack, or %NULL if the
 * there are no visible children. The returned widget does not have a reference
 * added, so you do not need to unref it.
 *
 * Return value: (transfer none): pointer to child of the #GdStack
 **/
GtkWidget *
gd_stack_get_visible_child (GdStack *stack)
{
  g_return_val_if_fail (GD_IS_STACK (stack), NULL);

  return stack->priv->visible_child ? stack->priv->visible_child->widget : NULL;
}

const char *
gd_stack_get_visible_child_name (GdStack *stack)
{
  g_return_val_if_fail (GD_IS_STACK (stack), NULL);

  if (stack->priv->visible_child)
    return stack->priv->visible_child->name;

  return NULL;
}

void
gd_stack_set_visible_child (GdStack    *stack,
			    GtkWidget  *child)
{
  GdStackChildInfo *child_info;

  g_return_if_fail (GD_IS_STACK (stack));
  g_return_if_fail (GTK_IS_WIDGET (child));

  child_info = find_child_info_for_widget (stack, child);
  if (child_info == NULL)
    return;

  if (gtk_widget_get_visible (child_info->widget))
    set_visible_child (stack, child_info);
}

void
gd_stack_set_visible_child_name (GdStack    *stack,
				 const char *name)
{
  GdStackPrivate *priv;
  GdStackChildInfo *child_info, *info;
  GList *l;

  g_return_if_fail (GD_IS_STACK (stack));
  g_return_if_fail (name != NULL);

  priv = stack->priv;

  child_info = NULL;
  for (l = priv->children; l != NULL; l = l->next)
    {
      info = l->data;
      if (info->name != NULL &&
	  strcmp (info->name, name) == 0)
	{
	  child_info = info;
	  break;
	}
    }

  if (child_info != NULL && gtk_widget_get_visible (child_info->widget))
    set_visible_child (stack, child_info);
}

static void
gd_stack_forall (GtkContainer *container,
		 gboolean      include_internals,
		 GtkCallback   callback,
		 gpointer      callback_data)
{
  GdStack *stack = GD_STACK (container);
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *child_info;
  GList *l;

  l = priv->children;
  while (l)
    {
      child_info = l->data;
      l = l->next;

      (* callback) (child_info->widget, callback_data);
    }
}

static void
gd_stack_compute_expand (GtkWidget      *widget,
			 gboolean       *hexpand_p,
			 gboolean       *vexpand_p)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;
  gboolean hexpand, vexpand;
  GdStackChildInfo *child_info;
  GtkWidget *child;
  GList *l;

  hexpand = FALSE;
  vexpand = FALSE;
  for (l = priv->children; l != NULL; l = l->next)
    {
      child_info = l->data;
      child = child_info->widget;

      if (!hexpand &&
	  gtk_widget_compute_expand (child, GTK_ORIENTATION_HORIZONTAL))
	hexpand = TRUE;

      if (!vexpand &&
	  gtk_widget_compute_expand (child, GTK_ORIENTATION_VERTICAL))
	vexpand = TRUE;

      if (hexpand && vexpand)
	break;
    }

  *hexpand_p = hexpand;
  *vexpand_p = vexpand;
}

static void
gd_stack_draw_crossfade (GtkWidget *widget,
                         cairo_t *cr)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;

  if (priv->last_visible_surface)
    {
      cairo_set_source_surface (cr, priv->last_visible_surface,
				priv->last_visible_surface_allocation.x,
				priv->last_visible_surface_allocation.y);
      cairo_set_operator (cr, CAIRO_OPERATOR_ADD);
      cairo_paint_with_alpha (cr, MAX (1.0 - priv->transition_pos, 0));
    }

  cairo_push_group (cr);
  cairo_set_operator (cr, CAIRO_OPERATOR_OVER);
  gtk_container_propagate_draw (GTK_CONTAINER (stack),
                                priv->visible_child->widget,
                                cr);
  cairo_pop_group_to_source (cr);
  cairo_set_operator (cr, CAIRO_OPERATOR_ADD);
  cairo_paint_with_alpha (cr, priv->transition_pos);
}

static void
gd_stack_draw_slide (GtkWidget *widget,
                     cairo_t *cr)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;
  GtkAllocation allocation;
  int x = 0;

  gtk_widget_get_allocation (widget, &allocation);

  x = get_bin_window_x (stack, &allocation);

  if (priv->transition_type == GD_STACK_TRANSITION_TYPE_SLIDE_LEFT)
    x -= allocation.width;
  if (priv->transition_type == GD_STACK_TRANSITION_TYPE_SLIDE_RIGHT)
    x += allocation.width;

  if (priv->last_visible_surface)
    {
      cairo_save (cr);
      cairo_set_source_surface (cr, priv->last_visible_surface, x, 0);
      cairo_paint (cr);
      cairo_restore (cr);
     }

  gtk_container_propagate_draw (GTK_CONTAINER (stack),
                                priv->visible_child->widget,
                                cr);
}

static gboolean
gd_stack_draw (GtkWidget *widget,
	       cairo_t *cr)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;
  cairo_t *pattern_cr;

  if (priv->visible_child)
    {
      if (priv->transition_pos < 1.0)
        {
          if (priv->last_visible_surface == NULL &&
              priv->last_visible_child != NULL)
            {
	      gtk_widget_get_allocation (priv->last_visible_child->widget,
					 &priv->last_visible_surface_allocation);
              priv->last_visible_surface =
		gdk_window_create_similar_surface (gtk_widget_get_window (widget),
						   CAIRO_CONTENT_COLOR_ALPHA,
						   priv->last_visible_surface_allocation.width,
						   priv->last_visible_surface_allocation.height);
	      pattern_cr = cairo_create (priv->last_visible_surface);
              /* We don't use propagate_draw here, because we don't want to apply
                 the bin_window offset */
              gtk_widget_draw (priv->last_visible_child->widget, pattern_cr);
	      cairo_destroy (pattern_cr);
            }

          switch (priv->transition_type)
            {
            case GD_STACK_TRANSITION_TYPE_CROSSFADE:
              gd_stack_draw_crossfade (widget, cr);
              break;
            case GD_STACK_TRANSITION_TYPE_SLIDE_LEFT:
            case GD_STACK_TRANSITION_TYPE_SLIDE_RIGHT:
              gd_stack_draw_slide (widget, cr);
              break;
            default:
              g_assert_not_reached ();
            }

        }
      else if (gtk_cairo_should_draw_window (cr, priv->bin_window))
        gtk_container_propagate_draw (GTK_CONTAINER (stack),
                                      priv->visible_child->widget,
                                      cr);
    }

  return TRUE;
}

static void
gd_stack_size_allocate (GtkWidget *widget,
			GtkAllocation *allocation)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;
  GtkAllocation child_allocation;

  g_return_if_fail (allocation != NULL);

  gtk_widget_set_allocation (widget, allocation);

  child_allocation = *allocation;
  child_allocation.x = 0;
  child_allocation.y = 0;

  if (priv->last_visible_child)
    gtk_widget_size_allocate (priv->last_visible_child->widget, &child_allocation);

  if (priv->visible_child)
    gtk_widget_size_allocate (priv->visible_child->widget, &child_allocation);

   if (gtk_widget_get_realized (widget))
    {
      gdk_window_move_resize (priv->view_window,
                              allocation->x, allocation->y,
                              allocation->width, allocation->height);
      gdk_window_move_resize (priv->bin_window,
                              get_bin_window_x (stack, allocation), 0,
                              allocation->width, allocation->height);
    }
}

static void
gd_stack_get_preferred_height (GtkWidget *widget,
			       gint *minimum_height,
			       gint *natural_height)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *child_info;
  GtkWidget *child;
  gint child_min, child_nat;
  GList *l;

  *minimum_height = 0;
  *natural_height = 0;

  for (l = priv->children; l != NULL; l = l->next)
    {
      child_info = l->data;
      child = child_info->widget;

      if (!priv->homogeneous &&
	  (priv->visible_child != child_info &&
           priv->last_visible_child != child_info))
	continue;
      if (gtk_widget_get_visible (child))
	{
	  gtk_widget_get_preferred_height (child, &child_min, &child_nat);

	  *minimum_height = MAX (*minimum_height, child_min);
	  *natural_height = MAX (*natural_height, child_nat);
	}
    }

  if (priv->last_visible_surface != NULL)
    {
      *minimum_height = MAX (*minimum_height, priv->last_visible_surface_allocation.height);
      *natural_height = MAX (*natural_height, priv->last_visible_surface_allocation.height);
    }
}

static void
gd_stack_get_preferred_height_for_width (GtkWidget* widget,
					 gint width,
					 gint *minimum_height,
					 gint *natural_height)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *child_info;
  GtkWidget *child;
  gint child_min, child_nat;
  GList *l;

  *minimum_height = 0;
  *natural_height = 0;

  for (l = priv->children; l != NULL; l = l->next)
    {
      child_info = l->data;
      child = child_info->widget;

      if (!priv->homogeneous &&
	  (priv->visible_child != child_info &&
           priv->last_visible_child != child_info))
	continue;
      if (gtk_widget_get_visible (child))
	{
	  gtk_widget_get_preferred_height_for_width (child, width, &child_min, &child_nat);

	  *minimum_height = MAX (*minimum_height, child_min);
	  *natural_height = MAX (*natural_height, child_nat);
	}
    }

  if (priv->last_visible_surface != NULL)
    {
      *minimum_height = MAX (*minimum_height, priv->last_visible_surface_allocation.height);
      *natural_height = MAX (*natural_height, priv->last_visible_surface_allocation.height);
    }
}

static void
gd_stack_get_preferred_width (GtkWidget *widget,
			       gint *minimum_width,
			       gint *natural_width)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *child_info;
  GtkWidget *child;
  gint child_min, child_nat;
  GList *l;

  *minimum_width = 0;
  *natural_width = 0;

  for (l = priv->children; l != NULL; l = l->next)
    {
      child_info = l->data;
      child = child_info->widget;

      if (!priv->homogeneous &&
	  (priv->visible_child != child_info &&
           priv->last_visible_child != child_info))
	continue;
      if (gtk_widget_get_visible (child))
	{
	  gtk_widget_get_preferred_width (child, &child_min, &child_nat);

	  *minimum_width = MAX (*minimum_width, child_min);
	  *natural_width = MAX (*natural_width, child_nat);
	}
    }

  if (priv->last_visible_surface != NULL)
    {
      *minimum_width = MAX (*minimum_width, priv->last_visible_surface_allocation.width);
      *natural_width = MAX (*natural_width, priv->last_visible_surface_allocation.width);
    }
}

static void
gd_stack_get_preferred_width_for_height (GtkWidget* widget,
					 gint height,
					 gint *minimum_width,
					 gint *natural_width)
{
  GdStack *stack = GD_STACK (widget);
  GdStackPrivate *priv = stack->priv;
  GdStackChildInfo *child_info;
  GtkWidget *child;
  gint child_min, child_nat;
  GList *l;

  *minimum_width = 0;
  *natural_width = 0;

  for (l = priv->children; l != NULL; l = l->next)
    {
      child_info = l->data;
      child = child_info->widget;

      if (!priv->homogeneous &&
	  (priv->visible_child != child_info &&
           priv->last_visible_child != child_info))
	continue;
      if (gtk_widget_get_visible (child))
	{
	  gtk_widget_get_preferred_width_for_height (child, height, &child_min, &child_nat);

	  *minimum_width = MAX (*minimum_width, child_min);
	  *natural_width = MAX (*natural_width, child_nat);
	}
    }

  if (priv->last_visible_surface != NULL)
    {
      *minimum_width = MAX (*minimum_width, priv->last_visible_surface_allocation.width);
      *natural_width = MAX (*natural_width, priv->last_visible_surface_allocation.width);
    }
}
