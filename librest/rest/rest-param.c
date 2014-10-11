/*
 * librest - RESTful web services access
 * Copyright (c) 2010 Intel Corporation.
 *
 * Authors: Ross Burton <ross@linux.intel.com>
 *          Rob Bradford <rob@linux.intel.com>
 *
 * RestParam is inspired by libsoup's SoupBuffer
 * Copyright (C) 2000-2030 Ximian, Inc
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU Lesser General Public License,
 * version 2.1, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
 * more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

#include <config.h>
#include <string.h>
#include "rest-param.h"

/**
 * SECTION:rest-param
 * @short_description: Name/value parameter data type with intelligent memory
 * management
 * @see_also: #RestParams, #RestProxyCall.
 */

/* Internal RestMemoryUse values */
enum {
  REST_MEMORY_OWNED = REST_MEMORY_COPY + 1
};

struct _RestParam {
  char          *name;
  RestMemoryUse  use;
  gconstpointer  data;
  gsize          length;
  const char    *content_type;
  char          *filename;

  volatile gint  ref_count;
  gpointer       owner;
  GDestroyNotify owner_dnotify;
};

G_DEFINE_BOXED_TYPE (RestParam, rest_param, rest_param_ref, rest_param_unref)

/**
 * rest_param_new_full:
 * @name: the parameter name
 * @use: the #RestMemoryUse describing how the memory can be used
 * @data: (array length=length) (element-type guint8): a pointer to
 *   the start of the data
 * @length: the length of the data
 * @content_type: the content type of the data
 * @filename: the original filename, or %NULL
 *
 * Create a new #RestParam called @name with @length bytes of @data as the
 * value.  @content_type is the type of the data as a MIME type, for example
 * "text/plain" for simple string parameters.
 *
 * If the parameter is a file upload it can be passed as @filename.
 *
 * Returns: a new #RestParam.
 **/
RestParam *
rest_param_new_full (const char    *name,
                     RestMemoryUse  use,
                     gconstpointer  data,
                     gsize          length,
                     const char    *content_type,
                     const char    *filename)
{
  RestParam *param;

  param = g_slice_new0 (RestParam);

  if (use == REST_MEMORY_COPY) {
    data = g_memdup (data, length);
    use  = REST_MEMORY_TAKE;
  }

  param->name   = g_strdup (name);
  param->use    = use;
  param->data   = data;
  param->length = length;

  param->content_type = g_intern_string (content_type);
  param->filename     = g_strdup (filename);

  param->ref_count = 1;

  if (use == REST_MEMORY_TAKE) {
    param->owner         = (gpointer)data;
    param->owner_dnotify = g_free;
  }

  return param;
}

/**
 * rest_param_new_with_owner:
 * @name: the parameter name
 * @data: (array length=length) (element-type guint8): a pointer to
 *   the start of the data
 * @length: the length of the data
 * @content_type: the content type of the data
 * @filename: (allow-none): the original filename, or %NULL
 * @owner: (transfer full): pointer to an object that owns @data
 * @owner_dnotify: (allow-none): a function to free/unref @owner when
 *   the buffer is freed
 *
 * Create a new #RestParam called @name with @length bytes of @data as the
 * value.  @content_type is the type of the data as a MIME type, for example
 * "text/plain" for simple string parameters.
 *
 * If the parameter is a file upload it can be passed as @filename.
 *
 * When the #RestParam is freed, it will call @owner_dnotify, passing @owner to
 * it. This allows you to do something like this:
 *
 * |[
 * GMappedFile *map = g_mapped_file_new (filename, FALSE, &error);
 * RestParam *param = rest_param_new_with_owner ("media",
 *                                               g_mapped_file_get_contents (map),
 *                                               g_mapped_file_get_length (map),
 *                                               "image/jpeg",
 *                                               filename,
 *                                               map,
 *                                               (GDestroyNotify)g_mapped_file_unref);
 * ]|
 *
 * Returns: a new #RestParam.
 **/
RestParam *
rest_param_new_with_owner (const char     *name,
                           gconstpointer   data,
                           gsize           length,
                           const char     *content_type,
                           const char     *filename,
                           gpointer        owner,
                           GDestroyNotify  owner_dnotify)
{
  RestParam *param;

  param = g_slice_new0 (RestParam);

  param->name = g_strdup (name);

  param->use    = REST_MEMORY_OWNED;
  param->data   = data;
  param->length = length;

  param->content_type = g_intern_string (content_type);
  param->filename     = g_strdup (filename);

  param->ref_count = 1;

  param->owner         = owner;
  param->owner_dnotify = owner_dnotify;

  return param;
}

/**
 * rest_param_new_string:
 * @name: the parameter name
 * @use: the #RestMemoryUse describing how the memory can be used
 * @string: the parameter value
 *
 * A convience constructor to create a #RestParam from a given UTF-8 string.
 * The resulting #RestParam will have a content type of "text/plain".
 *
 * Returns: a new #RestParam.
 **/
RestParam *
rest_param_new_string (const char    *name,
                       RestMemoryUse  use,
                       const char    *string)
{

  if (string == NULL) {
    use = REST_MEMORY_STATIC;
    string = "";
  }

  return rest_param_new_full (name,
                              use, string, strlen (string) + 1,
                              g_intern_static_string ("text/plain"),
                              NULL);
}

/**
 * rest_param_get_name:
 * @param: a valid #RestParam
 *
 * Get the name of the parameter.
 *
 * Returns: the parameter name.
 **/
const char *
rest_param_get_name (RestParam *param)
{
  return param->name;
}

/**
 * rest_param_get_content_type:
 * @param: a valid #RestParam
 *
 * Get the MIME type of the parameter.  For example, basic strings have the MIME
 * type "text/plain".
 *
 * Returns: the MIME type
 **/
const char *
rest_param_get_content_type (RestParam *param)
{
  return param->content_type;
}

/**
 * rest_param_get_file_name:
 * @param: a valid #RestParam
 *
 * Get the original file name of the parameter, if one is available.
 *
 * Returns: the filename if          set, or %NULL.
 **/
const char *
rest_param_get_file_name (RestParam *param)
{
  return param->filename;
}

/**
 * rest_param_is_string:
 * @param: a valid #RestParam
 *
 * Determine if the parameter is a string value, i.e. the content type is "text/plain".
 *
 * Returns: %TRUE if the parameter is a string, %FALSE otherwise.
 */
gboolean
rest_param_is_string (RestParam *param)
{
  return param->content_type == g_intern_static_string ("text/plain");
}

/**
 * rest_param_get_content:
 * @param: a valid #RestParam
 *
 * Get the content of @param.  The content should be treated as read-only and
 * not modified in any way.
 *
 * Returns: (transfer none): the content.
 **/
gconstpointer
rest_param_get_content (RestParam *param)
{
  return param->data;
}

/**
 * rest_param_get_content_length:
 * @param: a valid #RestParam
 *
 * Get the length of the content of @param.
 *
 * Returns: the length of the content
 **/
gsize
rest_param_get_content_length (RestParam *param)
{
  return param->length;
}

/**
 * rest_param_ref:
 * @param: a valid #RestParam
 *
 * Increase the reference count on @param.
 *
 * Returns: the #RestParam
 **/
RestParam *
rest_param_ref (RestParam *param)
{
  /* TODO: bring back REST_MEMORY_TEMPORARY? */
  g_return_val_if_fail (param, NULL);
  g_return_val_if_fail (param->ref_count > 0, NULL);

  g_atomic_int_inc (&param->ref_count);

  return param;
}

/**
 * rest_param_unref:
 * @param: a valid #RestParam
 *
 * Decrease the reference count on @param, destroying it if the reference count
 * reaches 0.
 **/
void
rest_param_unref (RestParam *param)
{
  g_return_if_fail (param);

  if (g_atomic_int_dec_and_test (&param->ref_count)) {
    if (param->owner_dnotify)
      param->owner_dnotify (param->owner);
    g_free (param->name);
    g_free (param->filename);

    g_slice_free (RestParam, param);
  }
}
