/*
 * librest - RESTful web services access
 * Copyright (c) 2008, 2009, Intel Corporation.
 *
 * Authors: Rob Bradford <rob@linux.intel.com>
 *          Ross Burton <ross@linux.intel.com>
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
#include <glib-object.h>
#include "rest-params.h"

/**
 * SECTION:rest-params
 * @short_description: Container for call parameters
 * @see_also: #RestParam, #RestProxyCall.
 */

/*
 * RestParams is an alias for GHashTable achieved by opaque types in the public
 * headers and casting internally. This has several limitations, mainly
 * supporting multiple parameters with the same name and preserving the ordering
 * of parameters.
 *
 * These are not requirements for the bulk of the web services, but this
 * limitation does mean librest can't be used for a few web services.
 *
 * TODO: this should be a list to support multiple parameters with the same
 * name.
 */

/**
 * rest_params_new:
 *
 * Create a new #RestParams.
 *
 * Returns: A empty #RestParams.
 **/
RestParams *
rest_params_new (void)
{
  /* The key is a string that is owned by the RestParam, so we don't need to
     explicitly free it on removal. */
  return (RestParams *)
    g_hash_table_new_full (g_str_hash, g_str_equal,
                           NULL, (GDestroyNotify)rest_param_unref);
}

/**
 * rest_params_free:
 * @params: a valid #RestParams
 *
 * Destroy the #RestParams and the #RestParam objects that it contains.
 **/
void
rest_params_free (RestParams *params)
{
  GHashTable *hash = (GHashTable *)params;

  g_return_if_fail (params);

  g_hash_table_destroy (hash);
}

/**
 * rest_params_add:
 * @params: a valid #RestParams
 * @param: a valid #RestParam
 *
 * Add @param to @params.
 **/
void
rest_params_add (RestParams *params, RestParam *param)
{
  GHashTable *hash = (GHashTable *)params;

  g_return_if_fail (params);
  g_return_if_fail (param);

  g_hash_table_replace (hash, (gpointer)rest_param_get_name (param), param);
}

/**
 * rest_params_get:
 * @params: a valid #RestParams
 * @name: a parameter name
 *
 * Return the #RestParam called @name, or %NULL if it doesn't exist.
 *
 * Returns: a #RestParam or %NULL if the name doesn't exist
 **/
RestParam *
rest_params_get (RestParams *params, const char *name)
{
  GHashTable *hash = (GHashTable *)params;

  g_return_val_if_fail (params, NULL);
  g_return_val_if_fail (name, NULL);

  return g_hash_table_lookup (hash, name);
}

/**
 * rest_params_remove:
 * @params: a valid #RestParams
 * @name: a parameter name
 *
 * Remove the #RestParam called @name.
 **/
void
rest_params_remove (RestParams *params, const char *name)
{
  GHashTable *hash = (GHashTable *)params;

  g_return_if_fail (params);
  g_return_if_fail (name);

  g_hash_table_remove (hash, name);
}

/**
 * rest_params_are_strings:
 * @params: a valid #RestParams
 *
 * Checks if the parameters are all simple strings (have a content type of
 * "text/plain").
 *
 * Returns: %TRUE if all of the parameters are simple strings, %FALSE otherwise.
 **/
gboolean
rest_params_are_strings (RestParams *params)
{
  GHashTable *hash = (GHashTable *)params;
  GHashTableIter iter;
  RestParam *param;

  g_return_val_if_fail (params, FALSE);

  g_hash_table_iter_init (&iter, hash);
  while (g_hash_table_iter_next (&iter, NULL, (gpointer)&param)) {
    if (!rest_param_is_string (param))
      return FALSE;
  }

  return TRUE;

}

/**
 * rest_params_as_string_hash_table:
 * @params: a valid #RestParams
 *
 * Create a new #GHashTable which contains the name and value of all string
 * (content type of text/plain) parameters.
 *
 * The values are owned by the #RestParams, so don't destroy the #RestParams
 * before the hash table.
 *
 * Returns: (element-type utf8 Rest.Param) (transfer container): a new #GHashTable.
 **/
GHashTable *
rest_params_as_string_hash_table (RestParams *params)
{
  GHashTable *hash, *strings;
  GHashTableIter iter;
  const char *name = NULL;
  RestParam *param = NULL;

  g_return_val_if_fail (params, NULL);

  hash = (GHashTable *)params;
  strings = g_hash_table_new (g_str_hash, g_str_equal);

  g_hash_table_iter_init (&iter, hash);
  while (g_hash_table_iter_next (&iter, (gpointer)&name, (gpointer)&param)) {
    if (rest_param_is_string (param))
      g_hash_table_insert (strings, (gpointer)name, (gpointer)rest_param_get_content (param));
  }

  return strings;
}

/**
 * rest_params_iter_init:
 * @iter: an uninitialized #RestParamsIter
 * @params: a valid #RestParams
 *
 * Initialize a parameter iterator over @params. Modifying @params after calling
 * this function invalidates the returned iterator.
 * |[
 * RestParamsIter iter;
 * const char *name;
 * RestParam *param;
 *
 * rest_params_iter_init (&iter, params);
 * while (rest_params_iter_next (&iter, &name, &param)) {
 *   /&ast; do something with name and param &ast;/
 * }
 * ]|
 **/
void
rest_params_iter_init (RestParamsIter *iter, RestParams *params)
{
  g_return_if_fail (iter);
  g_return_if_fail (params);

  g_hash_table_iter_init ((GHashTableIter *)iter, (GHashTable *)params);
}

/**
 * rest_params_iter_next:
 * @iter: an initialized #RestParamsIter
 * @name: a location to store the name, or %NULL
 * @param: a location to store the #RestParam, or %NULL
 *
 * Advances @iter and retrieves the name and/or parameter that are now pointed
 * at as a result of this advancement.  If FALSE is returned, @name and @param
 * are not set and the iterator becomes invalid.
 *
 * Returns: %FALSE if the end of the #RestParams has been reached, %TRUE otherwise.
 **/
gboolean
rest_params_iter_next (RestParamsIter *iter, const char **name, RestParam **param)
{
  g_return_val_if_fail (iter, FALSE);

  return g_hash_table_iter_next ((GHashTableIter *)iter, (gpointer)name, (gpointer)param);
}
