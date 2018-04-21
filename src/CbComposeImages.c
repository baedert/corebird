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

#include "CbComposeImages.h"
#include "corebird.h"

G_DEFINE_TYPE (CbComposeImages, cb_compose_images, GTK_TYPE_WIDGET);

/*
 * There is a known problem here.
 * Since we take each image and shrink it down by half the button width/height,
 * and the GtkImage keeps the aspect ratio, subtracting something from the size
 * of the image on top will also subtract that amount on the bottom.
 * This might make for some unpolished look.
 */

#define MAX_MEDIA_PER_UPLOAD 4
#define MIN_IMAGE_HEIGHT 80
#define IMAGE_SPACING 12
#define IMAGE_PADDING 6


typedef struct {
  char *path;
  GtkWidget *image;
  GtkWidget *delete_button;
  GtkWidget *progressbar;
  double fraction;
  guint deleted: 1;
} Image;

static void
image_destroy (const Image *image)
{
  gtk_widget_unparent (image->image);
  gtk_widget_unparent (image->progressbar);
  gtk_widget_unparent (image->delete_button);

  g_free (image->path);
}

static Image *
find_image (CbComposeImages *self,
            const char      *path)
{
  const guint n_images = self->images->len;
  Image *ret = NULL;
  guint i;

  for (i = 0; i < n_images; i ++)
    {
      ret = &g_array_index (self->images, Image, i);
      if (strcmp (path, ret->path) == 0)
        break;
    }

#if DEBUG
  if (ret != NULL)
    g_assert (strcmp (ret->path, path) == 0);
#endif

  return ret;
}

enum {
  IMAGE_REMOVED,
  LAST_SIGNAL
};
static guint signals[LAST_SIGNAL] = { 0 };


static GtkSizeRequestMode
cb_compose_images_get_request_mode (GtkWidget *widget)
{
  CbComposeImages *self = CB_COMPOSE_IMAGES (widget);

  if (self->images->len == 0)
    return GTK_SIZE_REQUEST_CONSTANT_SIZE;

  return GTK_SIZE_REQUEST_HEIGHT_FOR_WIDTH;
}

static void
cb_compose_images_measure (GtkWidget      *widget,
                           GtkOrientation  orientation,
                           int             for_size,
                           int            *minimum,
                           int            *natural,
                           int            *minimum_baseline,
                           int            *natural_baseline)
{
  CbComposeImages *self = CB_COMPOSE_IMAGES (widget);
  const guint n_images = self->images->len;
  guint i;

  if (n_images == 0)
    return;

  for (i = 0; i < n_images; i ++)
    {
      const Image *image = &g_array_index (self->images, Image, i);
      GtkWidget *img = image->image;
      int button_width, button_height;
      int image_min, image_nat;

      gtk_widget_measure (image->delete_button, GTK_ORIENTATION_HORIZONTAL, -1,
                          &button_width, NULL, NULL, NULL);
      gtk_widget_measure (image->delete_button, GTK_ORIENTATION_VERTICAL, button_width,
                          &button_height, NULL, NULL, NULL);

      /* The button overlaps the image by half its allocation */
      if (orientation == GTK_ORIENTATION_HORIZONTAL)
        {
          gtk_widget_measure (img, orientation, MAX (-1, for_size - (button_height / 2)),
                              &image_min, &image_nat, NULL, NULL);

          *minimum += image_min + (button_width / 2);
          *natural += image_nat + (button_width / 2);
        }
      else /* VERTICAL */
        {
          int image_width = for_size > -1 ? (for_size / MAX_MEDIA_PER_UPLOAD) - IMAGE_SPACING : -1;
          const double fraction = 1.0 - image->fraction;

          image_width -= button_width / 2;

          gtk_widget_measure (img, orientation, MAX (image_width, -1),
                              &image_min, &image_nat, NULL, NULL);

          *minimum = MAX (*minimum, (image_min + (button_height / 2)) * fraction);
          *natural = MAX (*natural, (image_nat + (button_height / 2)) * fraction);
        }
    }

  /* Don't forget the spacing */
  if (orientation == GTK_ORIENTATION_HORIZONTAL)
    {
      *minimum += IMAGE_SPACING * (n_images - 1);
      *natural += IMAGE_SPACING * (n_images - 1);
    }
}

static void
cb_compose_images_size_allocate (GtkWidget           *widget,
                                 const GtkAllocation *allocation,
                                 int                  baseline)
{
  CbComposeImages *self = CB_COMPOSE_IMAGES (widget);
  const guint n_images = self->images->len;
  guint i;
  int max_image_width;
  GtkAllocation image_alloc;

  if (n_images == 0)
    return;

  max_image_width = (allocation->width / MAX_MEDIA_PER_UPLOAD) - IMAGE_SPACING;
  image_alloc.x = 0;
  image_alloc.y = 0;
  image_alloc.height = allocation->height;

  for (i = 0; i < n_images; i ++)
    {
      const Image *image = &g_array_index (self->images, Image, i);
      GtkWidget *img = image->image;
      int child_width;
      GtkAllocation button_alloc;
      int image_height;
      int nat_child_height, min_child_height;

      gtk_widget_measure (image->delete_button, GTK_ORIENTATION_HORIZONTAL, -1,
                          &button_alloc.width, NULL, NULL, NULL);
      gtk_widget_measure (image->delete_button, GTK_ORIENTATION_VERTICAL, button_alloc.width,
                          &button_alloc.height, NULL, NULL, NULL);
      image_height = allocation->height - (button_alloc.height / 2);

      gtk_widget_measure (img, GTK_ORIENTATION_HORIZONTAL, MAX (image_height, -1),
                          NULL, &child_width, NULL, NULL);

      child_width = MIN (child_width, max_image_width) - (button_alloc.width / 2);

      gtk_widget_measure (img, GTK_ORIENTATION_VERTICAL, child_width,
                          &min_child_height, &nat_child_height, NULL, NULL);

      image_alloc.y = (button_alloc.height / 2) +
                      ((allocation->height - button_alloc.height / 2) * image->fraction); /* Delete animation */
      image_alloc.width = child_width;
      image_alloc.height = MAX (MIN (nat_child_height, image_height), min_child_height);
      gtk_widget_size_allocate (img, &image_alloc, baseline);

      /* Allocate delete button */
      button_alloc.x = image_alloc.x + image_alloc.width - (button_alloc.width / 2);
      button_alloc.y = 0;
      gtk_widget_size_allocate (image->delete_button, &button_alloc, baseline);

      /* Progressbar */
      if (gtk_widget_get_visible (image->progressbar))
        {
          GtkAllocation progress_alloc;
          progress_alloc.x = image_alloc.x + IMAGE_PADDING;

          gtk_widget_measure (image->progressbar, GTK_ORIENTATION_VERTICAL, -1,
                              &progress_alloc.height, NULL, NULL, NULL);
          gtk_widget_measure (image->progressbar, GTK_ORIENTATION_HORIZONTAL, -1,
                              &progress_alloc.width, NULL, NULL, NULL);
          progress_alloc.width = MAX (progress_alloc.width, image_alloc.width - (IMAGE_PADDING * 2));

          progress_alloc.y = image_alloc.y + image_alloc.height - progress_alloc.height - IMAGE_PADDING;

          gtk_widget_size_allocate (image->progressbar, &progress_alloc, baseline);
        }

      image_alloc.x += (image_alloc.width + (button_alloc.width / 2) + IMAGE_SPACING) * (1.0 - image->fraction);
    }
}

static void
cb_compose_images_snapshot (GtkWidget   *widget,
                            GtkSnapshot *snapshot)
{
  const int width = gtk_widget_get_width (widget);
  const int height = gtk_widget_get_height (widget);

  /* This is only relevant when an image gets transitioned to being deleted,
   * but we just always push a clip node here, for simplicity. */
  gtk_snapshot_push_clip (snapshot,
                          &GRAPHENE_RECT_INIT (0, 0, width, height),
                          "ComposeImagesClip");

  GTK_WIDGET_CLASS (cb_compose_images_parent_class)->snapshot (widget, snapshot);

  gtk_snapshot_pop (snapshot);
}

static void
cb_compose_images_finalize (GObject *o)
{
  CbComposeImages *self = (CbComposeImages*) o;
  guint i, p;

  cb_animation_destroy (&self->delete_animation);

  for (i = 0, p = self->images->len; i < p; i ++)
    {
      const Image *image = &g_array_index (self->images, Image, i);

      image_destroy (image);
      /* Don't remove from the GArray here */
    }

  g_array_free (self->images, TRUE);

  G_OBJECT_CLASS (cb_compose_images_parent_class)->finalize (o);
}

static void
delete_animation_func (CbAnimation *self,
                       double       t,
                       gpointer     user_data)
{
  CbComposeImages *compose_images = CB_COMPOSE_IMAGES (self->owner);
  Image *image = user_data;

  g_assert (image != NULL);
  g_assert (image->deleted);

  /* fraction of 1.0 is 'fully deleted' */
  image->fraction = t;
  gtk_widget_queue_resize (self->owner);

  if (t >= 1.0)
    {
      const guint n_images = compose_images->images->len;
      guint index = 0;

      g_signal_emit (self->owner, signals[IMAGE_REMOVED], 0, image->path);

      for (index = 0; index < n_images; index ++)
        {
          const Image *other = &g_array_index (compose_images->images, Image, index);

          if (other == image)
            break;
        }

      g_assert (index < n_images);

      /* Now remove the image from our actual list */
      image_destroy (image);
      g_array_remove_index (compose_images->images, index);
    }
}

static void
cb_compose_images_class_init (CbComposeImagesClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_compose_images_finalize;

  widget_class->get_request_mode = cb_compose_images_get_request_mode;
  widget_class->measure = cb_compose_images_measure;
  widget_class->size_allocate = cb_compose_images_size_allocate;
  widget_class->snapshot = cb_compose_images_snapshot;

  signals[IMAGE_REMOVED] = g_signal_new ("image-removed",
                                         G_OBJECT_CLASS_TYPE (object_class),
                                         G_SIGNAL_RUN_FIRST,
                                         0,
                                         NULL, NULL,
                                         NULL, G_TYPE_NONE, 1, G_TYPE_STRING);
}

static void
cb_compose_images_init (CbComposeImages *self)
{
  gtk_widget_set_has_surface (GTK_WIDGET (self), FALSE);

  self->images = g_array_new (FALSE, TRUE, sizeof (Image));

  cb_animation_init (&self->delete_animation,
                     GTK_WIDGET (self),
                     delete_animation_func);
}

static void
delete_button_clicked_cb (GtkButton *source,
                          gpointer   user_data)
{
  CbComposeImages *self = user_data;
  const guint n_images = self->images->len;
  Image *image = NULL;
  guint i;

  /* If the button really gets clicked in the split second the
   * delete animation is running, just ignore it */
  if (cb_animation_is_running (&self->delete_animation))
    return;

  /* Find the image by button... */
  for (i = 0; i < n_images; i ++)
    {
      Image *img = &g_array_index (self->images, Image, i);

      if (img->delete_button == (GtkWidget *)source)
        {
          image = img;
          break;
        }
    }

  g_assert (image != NULL);

  /* Hide non-image widgets during delete transtion */
  gtk_widget_set_child_visible (image->delete_button, FALSE);
  gtk_widget_hide (image->progressbar);

  image->deleted = TRUE;
  cb_animation_start (&self->delete_animation, image);
}

void
cb_compose_images_load_image (CbComposeImages *self,
                              const char      *image_path)
{
  GFile *file;
  GError *error = NULL;
  GdkTexture *texture;
  Image *image;

#if DEBUG
  g_assert (!cb_compose_images_is_full (self));
#endif

  file = g_file_new_for_path (image_path);
  texture = gdk_texture_new_from_file (file, &error);

  if (error != NULL)
    {
      g_warning (G_STRLOC ": Couldn't load image %s: %s",
                 image_path, error->message);
      g_object_unref (file);
      return;
    }

  g_array_set_size (self->images, self->images->len + 1);
  image = &g_array_index (self->images, Image, self->images->len - 1);
  image->path = g_strdup (image_path);
  image->fraction = 0.0;
  image->deleted = FALSE;

  image->image = gtk_image_new_from_paintable (GDK_PAINTABLE (g_steal_pointer (&texture)));
  gtk_image_set_can_shrink (GTK_IMAGE (image->image), TRUE);
  gtk_widget_set_size_request (image->image, -1, MIN_IMAGE_HEIGHT);
  gtk_widget_set_parent (image->image, GTK_WIDGET (self));

  image->delete_button = gtk_button_new_from_icon_name ("window-close-symbolic");
  gtk_style_context_add_class (gtk_widget_get_style_context (image->delete_button), "close-button");
  g_signal_connect (image->delete_button, "clicked", G_CALLBACK (delete_button_clicked_cb), self);
  gtk_widget_set_parent (image->delete_button, GTK_WIDGET (self));

  image->progressbar = gtk_progress_bar_new ();
  gtk_widget_hide (image->progressbar);
  gtk_widget_set_parent (image->progressbar, GTK_WIDGET (self));

  g_object_unref (file);
}

void
cb_compose_images_set_image_progress (CbComposeImages *self,
                                      const char      *image_path,
                                      double           progress)
{
  const Image *image = find_image (self, image_path);

  if (image == NULL)
    return;

  gtk_widget_show (image->progressbar);
  gtk_progress_bar_set_fraction (GTK_PROGRESS_BAR (image->progressbar), progress);
}

void
cb_compose_images_end_image_progress (CbComposeImages *self,
                                      const char      *image_path,
                                      const char      *error_message)
{
  const Image *image = find_image (self, image_path);

  if (image == NULL)
    return;

  gtk_widget_hide (image->progressbar);

  if (error_message != NULL)
    {
      g_warning (G_STRLOC ": Error in image upload: %s", error_message);
    }
}

int
cb_compose_images_get_n_images (CbComposeImages *self)
{
  return self->images->len;
}

gboolean
cb_compose_images_is_full (CbComposeImages *self)
{
  return self->images->len == MAX_MEDIA_PER_UPLOAD ||
         cb_compose_images_has_gif (self);
}

gboolean
cb_compose_images_has_gif (CbComposeImages *self)
{
  return FALSE;
}

void
cb_compose_images_insensitivize_buttons (CbComposeImages *self)
{
  const guint n_images = self->images->len;
  guint i;

  for (i = 0; i < n_images; i ++)
    {
      const Image *image = &g_array_index (self->images, Image, i);

      gtk_widget_set_sensitive (image->delete_button, FALSE);
    }
}
