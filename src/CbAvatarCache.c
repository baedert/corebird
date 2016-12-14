#include "CbAvatarCache.h"


G_DEFINE_TYPE (CbAvatarCache, cb_avatar_cache, G_TYPE_OBJECT);

typedef struct _CacheEntry CacheEntry;
struct _CacheEntry
{
  gint64 user_id;
  int refcount;
  char *url;
  cairo_surface_t *surface;
};

static inline CacheEntry *
get_entry_for_user_id (CbAvatarCache *cache,
                       gint64         user_id)
{
  guint i;

  for (i = 0; i < cache->entries->len; i ++)
    {
      CacheEntry *e = &g_array_index (cache->entries, CacheEntry, i);

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
cb_avatar_cache_add (CbAvatarCache   *cache,
                     gint64           user_id,
                     cairo_surface_t *surface,
                     const char      *url)
{
  CacheEntry *entry = NULL;

  g_return_if_fail (CB_IS_AVATAR_CACHE (cache));

  entry = get_entry_for_user_id (cache, user_id);

  if (entry == NULL)
    {
      /* Actually a new entry */
      g_array_set_size (cache->entries, cache->entries->len + 1);
      entry = &g_array_index (cache->entries, CacheEntry, cache->entries->len - 1);
      entry->user_id = user_id;
      if (surface)
        entry->surface = cairo_surface_reference (surface);
      entry->url = g_strdup (url);
    }
  else
    {
      if (entry->surface != NULL)
        cairo_surface_destroy (entry->surface);

      if (surface)
        entry->surface = cairo_surface_reference (surface);

      if (entry->url != NULL)
        g_free (entry->url);
      entry->url = g_strdup (url);
    }
}

void
cb_avatar_cache_set_avatar (CbAvatarCache   *cache,
                            gint64           user_id,
                            cairo_surface_t *surface,
                            const char      *url)
{
  CacheEntry *entry = NULL;

  g_return_if_fail (CB_IS_AVATAR_CACHE (cache));
  g_return_if_fail (surface != NULL);

  entry = get_entry_for_user_id (cache, user_id);

  g_assert (entry != NULL);

  if (entry->surface != NULL)
    cairo_surface_destroy (entry->surface);

  entry->surface = cairo_surface_reference (surface);

  if (entry->url != NULL)
    g_free (entry->url);
  entry->url = g_strdup (url);
}

cairo_surface_t *
cb_avatar_cache_get_surface_for_id (CbAvatarCache *cache,
                                    gint64         user_id,
                                    gboolean      *out_found)
{
  CacheEntry *entry = NULL;

  g_return_val_if_fail (CB_IS_AVATAR_CACHE (cache), NULL);
  g_return_val_if_fail (user_id > 0, NULL);
  g_return_val_if_fail (out_found != NULL, NULL);

  entry = get_entry_for_user_id (cache, user_id);

  if (entry != NULL)
    {
      *out_found = TRUE;
      return entry->surface; /* Can still be NULL... */
    }
  else
    {
      *out_found = FALSE;
      return NULL;
    }

}

void
cb_avatar_cache_set_url (CbAvatarCache *cache,
                         gint64         user_id,
                         const char    *url)
{
  CacheEntry *entry = NULL;

  g_return_if_fail (CB_IS_AVATAR_CACHE (cache));

  entry = get_entry_for_user_id (cache, user_id);

  g_assert (entry != NULL);

  if (entry->url != NULL)
    g_free (entry->url);
  entry->url = g_strdup (url);
}

void
cb_avatar_cache_decrease_refcount_for_surface (CbAvatarCache   *cache,
                                               cairo_surface_t *surface)
{
  guint i;
  guint index = (guint) -1;
  CacheEntry *entry = NULL;

  g_return_if_fail (CB_IS_AVATAR_CACHE (cache));
  g_return_if_fail (surface != NULL);

  for (i = 0; i < cache->entries->len; i ++)
    {
      CacheEntry *e = &g_array_index (cache->entries, CacheEntry, i);

      if (e->surface == surface)
        {
          entry = e;
          index = i;
          break;
        }
    }

  if (entry == NULL)
    {
      /* Surface not even in cache */
      return;
    }

  entry->refcount --;

  if (entry->refcount == 0)
    {
      g_debug ("Removing avatar with id %ld from cache", entry->user_id);
      g_array_remove_index_fast (cache->entries, index);
    }
}

void
cb_avatar_cache_increase_refcount_for_surface (CbAvatarCache   *cache,
                                               cairo_surface_t *surface)
{
  CacheEntry *entry = NULL;
  guint i;

  g_return_if_fail (CB_IS_AVATAR_CACHE (cache));
  g_return_if_fail (surface != NULL);

  for (i = 0; i < cache->entries->len; i ++)
    {
      CacheEntry *e = &g_array_index (cache->entries, CacheEntry, i);

      if (e->surface == surface)
        {
          entry = e;
          break;
        }
    }


  if (entry != NULL)
    entry->refcount ++;
}

const char *
cb_avatar_cache_get_url_for_id (CbAvatarCache *cache,
                                gint64         user_id)
{
  CacheEntry *entry;

  g_return_val_if_fail (CB_IS_AVATAR_CACHE (cache), NULL);
  g_return_val_if_fail (user_id > 0, NULL);

  entry = get_entry_for_user_id (cache, user_id);

  if (entry == NULL)
    return NULL;

  return entry->url;
}




static void
cb_avatar_cache_finalize (GObject *obj)
{
  CbAvatarCache *cache = CB_AVATAR_CACHE (obj);

  g_array_free (cache->entries, TRUE);
}

static void
cb_avatar_cache_init (CbAvatarCache *cache)
{
  cache->entries = g_array_new (FALSE, TRUE, sizeof (CacheEntry));
}

static void
cb_avatar_cache_class_init (CbAvatarCacheClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_avatar_cache_finalize;
}
