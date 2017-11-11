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

#include "CbAspectImage.h"
#include "CbUtils.h"

G_DEFINE_TYPE (CbAspectImage, cb_aspect_image, GTK_TYPE_WIDGET);


static void
cb_aspect_image_measure (GtkWidget      *widget,
                         GtkOrientation  orientation,
                         int             for_size,
                         int            *minimum,
                         int            *natural,
                         int            *minimum_baseline,
                         int            *natural_baseline)
{
  CbAspectImage *self = CB_ASPECT_IMAGE (widget);

  if (orientation == GTK_ORIENTATION_VERTICAL)
    {
      if (self->texture != NULL)
        {
          *minimum = *natural = gdk_texture_get_height (self->texture);
        }
    }
}

static void
cb_aspect_image_snapshot (GtkWidget   *widget,
                          GtkSnapshot *snapshot)
{
  CbAspectImage *self = CB_ASPECT_IMAGE (widget);
  int width = gtk_widget_get_width (widget);
  int height = gtk_widget_get_height (widget);
  int texture_width = 0;
  int x = 0;

  if (self->texture == NULL)
    return;

  /* TODO: We could probably use a cross-fade node here now? */

  texture_width = gdk_texture_get_width (self->texture);
  x = (width - texture_width) / 2;

  gtk_snapshot_push_opacity (snapshot, self->opacity, "AspectImage opacity");

  gtk_snapshot_push_clip (snapshot, &GRAPHENE_RECT_INIT (0, 0, width, height), "AspectImage Clip");

  gtk_snapshot_push_blur (snapshot, 10, "AspectImage blur");
  gtk_snapshot_append_texture (snapshot, self->texture,
                               &GRAPHENE_RECT_INIT (0, 0, width, height), "AspectImage texture");
  gtk_snapshot_pop (snapshot); /* Blur */

  gtk_snapshot_append_texture (snapshot, self->texture,
                               &GRAPHENE_RECT_INIT (x, 0, texture_width, height), "AspectImage texture");

  gtk_snapshot_pop (snapshot); /* Clip */
  gtk_snapshot_pop (snapshot); /* Opacity */
}

static void
cb_aspect_image_finalize (GObject *object)
{
  CbAspectImage *self = CB_ASPECT_IMAGE (object);

  g_clear_object (&self->texture);

  G_OBJECT_CLASS (cb_aspect_image_parent_class)->finalize (object);
}

static void
cb_aspect_image_class_init (CbAspectImageClass *klass)
{
  GObjectClass *object_class   = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_aspect_image_finalize;

  widget_class->measure = cb_aspect_image_measure;
  widget_class->snapshot = cb_aspect_image_snapshot;
}

static void
opacity_animation_func (CbAnimation *animation,
                        double       t)
{
  CbAspectImage *self = CB_ASPECT_IMAGE (animation->owner);

  self->opacity = t;
  gtk_widget_queue_draw (animation->owner);
}

static void
cb_aspect_image_init (CbAspectImage *self)
{
  gtk_widget_set_has_window (GTK_WIDGET (self), FALSE);

  self->texture = NULL;
  self->opacity = 1.0;

  cb_animation_init (&self->opacity_animation, GTK_WIDGET (self), opacity_animation_func);
}

GtkWidget *
cb_aspect_image_new (void)
{
  return GTK_WIDGET (g_object_new (CB_TYPE_ASPECT_IMAGE, NULL));
}

/* Takes the given pixbuf and just converts it to a GdkTexture */
void
cb_aspect_image_set_pixbuf (CbAspectImage   *self,
                            const GdkPixbuf *pixbuf)
{
  cairo_surface_t *surface;
  GdkTexture *texture;
  /* We don't use new_for_pixbuf since that's slower when drawing with the cairo renderer */

  surface = gdk_cairo_surface_create_from_pixbuf (pixbuf, 1, NULL);
  texture = cb_utils_surface_to_texture (surface, 1);

  g_set_object (&self->texture, texture);

  gtk_widget_queue_resize (GTK_WIDGET (self));
}
