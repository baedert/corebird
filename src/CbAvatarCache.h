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

#ifndef AVATAR_CACHE_H
#define AVATAR_CACHE_H

#include <glib-object.h>
#include <cairo.h>

G_BEGIN_DECLS

typedef struct _CbAvatarCache CbAvatarCache;
struct _CbAvatarCache
{
  GObject parent_instance;

  GArray *entries;
};

#define CB_TYPE_AVATAR_CACHE cb_avatar_cache_get_type ()
G_DECLARE_FINAL_TYPE (CbAvatarCache, cb_avatar_cache, CB, AVATAR_CACHE, GObject);


GType cb_avatar_cache_get_type (void) G_GNUC_CONST;

CbAvatarCache *cb_avatar_cache_new (void);

void  cb_avatar_cache_decrease_refcount_for_surface (CbAvatarCache   *cache,
                                                     cairo_surface_t *surface);
void  cb_avatar_cache_increase_refcount_for_surface (CbAvatarCache   *cache,
                                                     cairo_surface_t *surface);

void  cb_avatar_cache_add (CbAvatarCache   *cache,
                           gint64           user_id,
                           cairo_surface_t *surface,
                           const char      *url);

void  cb_avatar_cache_set_avatar (CbAvatarCache   *cache,
                                  gint64           user_id,
                                  cairo_surface_t *surface,
                                  const char      *url);


cairo_surface_t * cb_avatar_cache_get_surface_for_id (CbAvatarCache *cache,
                                                      gint64         user_id,
                                                      gboolean      *out_found);

const char *cb_avatar_cache_get_url_for_id (CbAvatarCache *cache,
                                            gint64         user_id);

guint cb_avatar_cache_get_n_entries (CbAvatarCache *cache);

void cb_avatar_cache_set_url (CbAvatarCache *cache,
                              gint64         user_id,
                              const char    *url);



G_END_DECLS

#endif
