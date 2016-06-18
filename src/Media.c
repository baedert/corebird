/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2016 Timm Bäder
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
#include "Media.h"



G_DEFINE_TYPE (CbMedia, cb_media, G_TYPE_OBJECT);

enum {
  PROGRESS,
  LAST_SIGNAL
};
static guint media_signals[LAST_SIGNAL] = { 0 };


static void
cb_media_finalize (GObject *object)
{
  CbMedia *media = CB_MEDIA (object);

  cairo_surface_destroy (media->surface);
  g_free (media->thumb_url);
  g_free (media->target_url);
  g_free (media->url);

  if (media->animation)
    g_object_unref (media->animation);
}

static void
cb_media_class_init (CbMediaClass *class)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (class);
  gobject_class->finalize = cb_media_finalize;

  media_signals[PROGRESS] = g_signal_new ("progress",
                                          G_OBJECT_CLASS_TYPE (gobject_class),
                                          G_SIGNAL_RUN_FIRST,
                                          0,
                                          NULL, NULL,
                                          NULL, G_TYPE_NONE, 0);
}

static void
cb_media_init (CbMedia *media)
{
  media->surface = NULL;
  media->loaded  = FALSE;
  media->invalid = FALSE;
  media->surface = NULL;
  media->url     = NULL;
  media->percent_loaded = 0;
  media->width = -1;
  media->height = -1;
}

CbMedia *
cb_media_new (void)
{
  return CB_MEDIA (g_object_new (CB_TYPE_MEDIA, NULL));
}

gboolean
cb_media_is_video (CbMedia *media)
{
  switch (media->type)
    {
      case CB_MEDIA_TYPE_ANIMATED_GIF:
      case CB_MEDIA_TYPE_VINE:
      case CB_MEDIA_TYPE_TWITTER_VIDEO:
      case CB_MEDIA_TYPE_INSTAGRAM_VIDEO:
        return TRUE;

      default:
        return FALSE;
    }

  return FALSE;
}

static gboolean
emit_media_finished (gpointer data)
{
  g_signal_emit (data, media_signals[PROGRESS], 0);

  return G_SOURCE_REMOVE;
}

void
cb_media_update_progress (CbMedia *media, int progress)
{
  media->percent_loaded = progress;

  g_main_context_invoke (NULL,
                         emit_media_finished,
                         media);
}

void
cb_media_loading_finished (CbMedia *media)
{
  g_return_if_fail (CB_IS_MEDIA (media));

  media->loaded = TRUE;

  cb_media_update_progress (media, 100);
}

CbMediaType
cb_media_type_from_url (const char *url)
{
  if (g_str_has_prefix (url, "https://vine.co/v/"))
    return CB_MEDIA_TYPE_VINE;

  if (g_str_has_suffix (url, "/photo/1"))
    return CB_MEDIA_TYPE_ANIMATED_GIF;

  if (g_str_has_suffix (url, ".gif"))
    return CB_MEDIA_TYPE_GIF;

  return CB_MEDIA_TYPE_IMAGE;
}
