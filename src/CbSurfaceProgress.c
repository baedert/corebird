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

#include "CbSurfaceProgress.h"

G_DEFINE_TYPE(CbSurfaceProgress, cb_surface_progress, GTK_TYPE_WIDGET)

static void
cb_surface_progress_snapshot (GtkWidget   *widget,
                              GtkSnapshot *snapshot)
{
  CbSurfaceProgress *self = CB_SURFACE_PROGRESS (widget);
  if (self->texture == NULL)
    return;

  g_warning ("CbSurfaceProgress is still a thing, but video playback doesn't work right now anyway...");

#if 0
  int width, height;
  cairo_surface_t *tmp_surface;
  cairo_t *ctx;
  double arc_size, cx, cy, radius;
  double scale;
  cairo_t *ct;


  width = gtk_widget_get_width (widget);
  height = gtk_widget_get_height (widget);

  ct = gtk_snapshot_append_cairo (snapshot,
                                  &GRAPHENE_RECT_INIT (0, 0, width, height), "SurfaceProgress");

  scale = MIN ((double)width  / (double)cairo_image_surface_get_width (self->surface),
               (double)height / (double)cairo_image_surface_get_height (self->surface));

  tmp_surface = cairo_surface_create_similar (self->surface,
                                              CAIRO_CONTENT_COLOR_ALPHA,
                                              width, height);

  ctx = cairo_create (tmp_surface);

  /* Draw the surface slightly translucent on the widget's surface */
  cairo_save (ct);
  cairo_rectangle (ct, 0, 0, width, height);
  cairo_scale (ct, scale, scale);
  cairo_set_source_surface (ct, self->surface, 0, 0);
  cairo_paint_with_alpha (ct, 0.5);
  cairo_restore (ct);

  /* Draw self->surface on tmp surface */
  cairo_save (ctx);
  cairo_rectangle (ctx, 0, 0, width, height);
  cairo_scale (ctx, scale, scale);
  cairo_set_source_surface (ctx, self->surface, 0, 0);
  cairo_fill (ctx);
  cairo_restore (ctx);

  arc_size = MIN (width, height) * 2.0;
  cx = width / 2.0;
  cy = height / 2.0;
  radius = (arc_size / 2.0) - 0.5;

  cairo_set_operator (ctx, CAIRO_OPERATOR_DEST_IN);

  cairo_set_source_rgba (ctx, 1.0, 0.0, 0.0, 1.0);
  cairo_move_to (ctx, width / 2.0, height / 2.0);
  cairo_arc (ctx, cx, cy, radius, 0, 0);

  cairo_arc (ctx, cx, cy, radius, 0, 2 * G_PI * self->progress);
  cairo_move_to (ctx, cx, cy);
  cairo_fill (ctx);

  /* Draw the tmp surface */
  cairo_rectangle (ct, 0, 0, width, height);
  cairo_set_source_surface (ct, tmp_surface, 0, 0);
  cairo_fill (ct);

  cairo_surface_destroy (tmp_surface);

  cairo_destroy (ct);
#endif
}

static void
cb_surface_progress_measure (GtkWidget      *widget,
                             GtkOrientation  orientation,
                             int             for_size,
                             int            *minimum,
                             int            *natural,
                             int            *minimum_baseline,
                             int            *natural_baseline)
{
  *minimum = *natural = 1;
}

static void
cb_surface_progress_finalize (GObject *object)
{
  CbSurfaceProgress *self = CB_SURFACE_PROGRESS (object);

  g_clear_object (&self->texture);

  G_OBJECT_CLASS (cb_surface_progress_parent_class)->finalize (object);
}

static void
cb_surface_progress_init (CbSurfaceProgress *self)
{
}

static void
cb_surface_progress_class_init (CbSurfaceProgressClass *klass)
{
  GObjectClass   *object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_surface_progress_finalize;

  widget_class->measure = cb_surface_progress_measure;
  widget_class->snapshot = cb_surface_progress_snapshot;
}

GtkWidget *
cb_surface_progress_new (void)
{
  return GTK_WIDGET (g_object_new (CB_TYPE_SURFACE_PROGRESS, NULL));
}

double
cb_surface_progress_get_progress (CbSurfaceProgress *self)
{
  return self->progress;
}

void
cb_surface_progress_set_progress (CbSurfaceProgress *self,
                                  double             progress)
{

  if (progress >= 1.0)
    self->progress = 1.0;
  else if (progress < 0.0)
    self->progress = 0.0;
  else
    self->progress = progress;

  gtk_widget_queue_draw (GTK_WIDGET (self));
}

GdkTexture *
cb_surface_progress_get_texture (CbSurfaceProgress *self)
{
  return self->texture;
}

void
cb_surface_progress_set_texture (CbSurfaceProgress *self,
                                 GdkTexture        *texture)
{
  g_set_object (&self->texture, texture);
  gtk_widget_queue_resize (GTK_WIDGET (self));
}
