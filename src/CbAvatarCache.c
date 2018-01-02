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

#include "CbAvatarCache.h"


G_DEFINE_TYPE (CbAvatarCache, cb_avatar_cache, G_TYPE_OBJECT);

typedef struct _CacheEntry CacheEntry;
struct _CacheEntry
{
  gint64 user_id;
  int refcount;
  char *url;
  GdkTexture *texture;
};

static void
cache_entry_destroy (CacheEntry *entry)
{
  g_free (entry->url);

  if (entry->texture)
    g_object_unref (entry->texture);
}

static inline CacheEntry *
get_entry_for_user_id (CbAvatarCache *self,
                       gint64         user_id)
{
  guint i;

  for (i = 0; i < self->entries->len; i ++)
    {
      CacheEntry *e = &g_array_index (self->entries, CacheEntry, i);

      if (e->user_id == user_id)
        return e;
    }

  return NULL;
}

CbAvatarCache *
cb_avatar_cache_new (void)
{
  return CB_AVATAR_CACHE (g_object_new (CB_TYPE_AVATAR_CACHE, NULL));
}

void
cb_avatar_cache_add (CbAvatarCache   *self,
                     gint64           user_id,
                     GdkTexture      *texture,
                     const char      *url)
{
  CacheEntry *entry = NULL;

  g_return_if_fail (CB_IS_AVATAR_CACHE (self));

  entry = get_entry_for_user_id (self, user_id);

  if (entry == NULL)
    {
      /* Actually a new entry */
      g_array_set_size (self->entries, self->entries->len + 1);
      entry = &g_array_index (self->entries, CacheEntry, self->entries->len - 1);
      entry->user_id = user_id;
      if (texture)
        entry->texture = g_object_ref (texture);
      entry->url = g_strdup (url);
      /* The subsequent incrase_refcount will push this up to 1. Entries with
       * refcount 0 won't be removed from the cache until a decrease_refcount call */
      entry->refcount = 0;
    }
  else
    {
      g_set_object (&entry->texture, texture);
      g_free (entry->url);
      entry->url = g_strdup (url);
    }
}

void
cb_avatar_cache_set_avatar (CbAvatarCache   *self,
                            gint64           user_id,
                            GdkTexture      *texture,
                            const char      *url)
{
  CacheEntry *entry = NULL;

  g_return_if_fail (CB_IS_AVATAR_CACHE (self));
  g_return_if_fail (texture != NULL);

  entry = get_entry_for_user_id (self, user_id);

  g_assert (entry != NULL);

  g_set_object (&entry->texture, texture);

  g_free (entry->url);
  entry->url = g_strdup (url);
}

GdkTexture *
cb_avatar_cache_get_texture_for_id (CbAvatarCache *self,
                                    gint64         user_id,
                                    gboolean      *out_found)
{
  const CacheEntry *entry = NULL;

  g_return_val_if_fail (CB_IS_AVATAR_CACHE (self), NULL);
  g_return_val_if_fail (user_id > 0, NULL);
  g_return_val_if_fail (out_found != NULL, NULL);

  entry = get_entry_for_user_id (self, user_id);

  if (entry != NULL)
    {
      *out_found = TRUE;
      return entry->texture; /* Can still be NULL... */
    }
  else
    {
      *out_found = FALSE;
      return NULL;
    }

}

void
cb_avatar_cache_set_url (CbAvatarCache *self,
                         gint64         user_id,
                         const char    *url)
{
  CacheEntry *entry = NULL;

  g_return_if_fail (CB_IS_AVATAR_CACHE (self));

  entry = get_entry_for_user_id (self, user_id);

  g_assert (entry != NULL);

  if (entry->url != NULL)
    g_free (entry->url);

  entry->url = g_strdup (url);
}

void
cb_avatar_cache_decrease_refcount_for_texture (CbAvatarCache   *self,
                                               GdkTexture      *texture)
{
  guint i;
  guint index = (guint) -1;
  CacheEntry *entry = NULL;

  g_return_if_fail (CB_IS_AVATAR_CACHE (self));
  g_return_if_fail (texture != NULL);

  for (i = 0; i < self->entries->len; i ++)
    {
      CacheEntry *e = &g_array_index (self->entries, CacheEntry, i);

      if (e->texture == texture)
        {
          entry = e;
          index = i;
          break;
        }
    }

  if (entry == NULL)
    {
      /* Texture not even in cache */
      return;
    }

  entry->refcount --;

  if (entry->refcount <= 0)
    {
      g_debug ("Removing avatar with id %" G_GINT64_FORMAT " from cache", entry->user_id);
      g_array_remove_index_fast (self->entries, index);
    }
}

void
cb_avatar_cache_increase_refcount_for_texture (CbAvatarCache   *self,
                                               GdkTexture      *texture)
{
  guint i;

  g_return_if_fail (CB_IS_AVATAR_CACHE (self));
  g_return_if_fail (texture != NULL);

  for (i = 0; i < self->entries->len; i ++)
    {
      CacheEntry *e = &g_array_index (self->entries, CacheEntry, i);

      if (e->texture == texture)
        {
          e->refcount ++;
          break;
        }
    }
}

const char *
cb_avatar_cache_get_url_for_id (CbAvatarCache *self,
                                gint64         user_id)
{
  const CacheEntry *entry;

  g_return_val_if_fail (CB_IS_AVATAR_CACHE (self), NULL);
  g_return_val_if_fail (user_id > 0, NULL);

  entry = get_entry_for_user_id (self, user_id);

  if (entry == NULL)
    return NULL;

  return entry->url;
}

guint
cb_avatar_cache_get_n_entries (CbAvatarCache *self)
{
  g_return_val_if_fail (CB_IS_AVATAR_CACHE (self), 0);

  return self->entries->len;
}

static void
cb_avatar_cache_finalize (GObject *obj)
{
  CbAvatarCache *self = CB_AVATAR_CACHE (obj);

  g_array_free (self->entries, TRUE);

  G_OBJECT_CLASS (cb_avatar_cache_parent_class)->finalize (obj);
}

static void
cb_avatar_cache_init (CbAvatarCache *self)
{
  self->entries = g_array_new (FALSE, TRUE, sizeof (CacheEntry));
  g_array_set_clear_func (self->entries, (GDestroyNotify) cache_entry_destroy);
}

static void
cb_avatar_cache_class_init (CbAvatarCacheClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_avatar_cache_finalize;
}
