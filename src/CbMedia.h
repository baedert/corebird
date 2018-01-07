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

#ifndef __CB_MEDIA_H__
#define __CB_MEDIA_H__

#include <glib-object.h>
#include <cairo-gobject.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

typedef enum {
  CB_MEDIA_TYPE_IMAGE,
  CB_MEDIA_TYPE_GIF,
  CB_MEDIA_TYPE_ANIMATED_GIF,
  CB_MEDIA_TYPE_TWITTER_VIDEO,
  CB_MEDIA_TYPE_INSTAGRAM_VIDEO,

  CB_MEDIA_TYPE_UNKNOWN
} CbMediaType;


struct _CbMedia
{
  GObject parent_instance;

  char *url;
  char *thumb_url;
  char *target_url;

  int width;
  int height;

  CbMediaType type;
  guint loaded : 1;
  guint invalid : 1;
  double percent_loaded;

  GdkPixbufAnimation *animation;
  GdkTexture *texture;
};

typedef struct _CbMedia CbMedia;

#define CB_TYPE_MEDIA cb_media_get_type ()
G_DECLARE_FINAL_TYPE (CbMedia, cb_media, CB, MEDIA, GObject);

CbMedia *   cb_media_new              (void);
gboolean    cb_media_is_video         (CbMedia *media);
void        cb_media_loading_finished (CbMedia *media);
void        cb_media_update_progress  (CbMedia *media,
                                       double   progress);
CbMediaType cb_media_type_from_url    (const char *url);

G_END_DECLS

#endif
