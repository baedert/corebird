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

#ifndef __GD_STACK_H__
#define __GD_STACK_H__

#include <gtk/gtk.h>

G_BEGIN_DECLS


#define GD_TYPE_STACK (gd_stack_get_type ())
#define GD_STACK(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), GD_TYPE_STACK, GdStack))
#define GD_STACK_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), GD_TYPE_STACK, GdStackClass))
#define GD_IS_STACK(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GD_TYPE_STACK))
#define GD_IS_STACK_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), GD_TYPE_STACK))
#define GD_STACK_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), GD_TYPE_STACK, GdStackClass))

typedef struct _GdStack GdStack;
typedef struct _GdStackClass GdStackClass;
typedef struct _GdStackPrivate GdStackPrivate;

typedef enum {
  GD_STACK_TRANSITION_TYPE_NONE,
  GD_STACK_TRANSITION_TYPE_CROSSFADE,
  GD_STACK_TRANSITION_TYPE_SLIDE_RIGHT,
  GD_STACK_TRANSITION_TYPE_SLIDE_LEFT
} GdStackTransitionType;

struct _GdStack {
  GtkContainer parent_instance;
  GdStackPrivate *priv;
};

struct _GdStackClass {
  GtkContainerClass parent_class;
};

GType gd_stack_get_type (void) G_GNUC_CONST;

GtkWidget  *          gd_stack_new                     (void);
void                  gd_stack_add_named               (GdStack               *stack,
							GtkWidget             *child,
							const char            *name);
void                  gd_stack_add_titled              (GdStack               *stack,
							GtkWidget             *child,
							const char            *name,
							const char            *title);
void                  gd_stack_set_visible_child       (GdStack               *stack,
							GtkWidget             *child);
GtkWidget *           gd_stack_get_visible_child       (GdStack               *stack);
void                  gd_stack_set_visible_child_name  (GdStack               *stack,
							const char            *name);
const char *          gd_stack_get_visible_child_name  (GdStack               *stack);
void                  gd_stack_set_homogeneous         (GdStack               *stack,
							gboolean               homogeneous);
gboolean              gd_stack_get_homogeneous         (GdStack               *stack);
void                  gd_stack_set_transition_duration (GdStack               *stack,
							gint                   transition_duration);
gint                  gd_stack_get_transition_duration (GdStack               *stack);
void                  gd_stack_set_transition_type     (GdStack               *stack,
							GdStackTransitionType  type);
GdStackTransitionType gd_stack_get_transition_type     (GdStack               *stack);

G_END_DECLS

#endif
