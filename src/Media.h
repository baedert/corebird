#ifndef MEDIA_H
#define MEDIA_H

#include <glib-object.h>
#include <cairo-gobject.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

G_BEGIN_DECLS

typedef enum {
  CB_MEDIA_TYPE_IMAGE,
  CB_MEDIA_TYPE_VINE,
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
  guint percent_loaded : 7;

  cairo_surface_t *surface;
  GdkPixbufAnimation *animation;
};

typedef struct _CbMedia CbMedia;

#define CB_TYPE_MEDIA cb_media_get_type ()
G_DECLARE_FINAL_TYPE (CbMedia, cb_media, CB, MEDIA, GObject);


GType       cb_media_get_type (void) G_GNUC_CONST;
CbMedia    *cb_media_new (void);

gboolean    cb_media_is_video (CbMedia *media);
void        cb_media_loading_finished (CbMedia *media);
void        cb_media_update_progress (CbMedia *media, int progress);

CbMediaType cb_media_type_from_url (const char *url);

G_END_DECLS

#endif
