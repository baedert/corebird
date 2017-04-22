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

#include "CbBundle.h"
#include <string.h>


G_DEFINE_TYPE (CbBundle, cb_bundle, G_TYPE_OBJECT);

CbBundle *
cb_bundle_new (void)
{
  return CB_BUNDLE (g_object_new (CB_TYPE_BUNDLE, NULL));
}

static GValue *
find_value (CbBundle *self,
            int       key)
{
  guint i;

  for (i = 0; i < self->keys->len; i ++)
    {
      int k = g_array_index (self->keys, int, i);
      if (k == key)
        {
          return &g_array_index (self->values, GValue, i);
        }
    }

  return NULL;
}

guint
cb_bundle_get_size (CbBundle *self)
{
  g_return_val_if_fail (CB_IS_BUNDLE (self), 0);

  g_assert (self->keys->len == self->values->len);

  return self->keys->len;
}

void
cb_bundle_put_string (CbBundle   *self,
                      int         key,
                      const char *val)
{
  GValue *gvalue;

  g_return_if_fail (CB_IS_BUNDLE (self));
  g_return_if_fail (val != NULL);

  g_assert (find_value (self, key) == NULL);

  g_array_append_val (self->keys, key);
  g_array_set_size (self->values, self->values->len + 1);
  gvalue = &g_array_index (self->values, GValue, self->values->len - 1);

  g_assert (self->keys->len == self->values->len);

  g_value_init (gvalue, G_TYPE_STRING);

  g_value_set_string (gvalue, val);
}

const char *
cb_bundle_get_string (CbBundle *self,
                      int       key)
{
  GValue *gvalue;

  g_return_val_if_fail (CB_IS_BUNDLE (self), NULL);

  gvalue = find_value (self, key);

  if (gvalue != NULL)
    return g_value_get_string (gvalue);

  return NULL;
}

void
cb_bundle_put_int (CbBundle *self,
                   int       key,
                   int       val)
{
  GValue *gvalue;

  g_return_if_fail (CB_IS_BUNDLE (self));

  g_assert (find_value (self, key) == NULL);

  g_array_append_val (self->keys, key);
  g_array_set_size (self->values, self->values->len + 1);
  gvalue = &g_array_index (self->values, GValue, self->values->len - 1);

  g_assert (self->keys->len == self->values->len);

  g_value_init (gvalue, G_TYPE_INT);

  g_value_set_int (gvalue, val);
}

int
cb_bundle_get_int (CbBundle *self,
                   int       key)
{
  GValue *gvalue;

  g_return_val_if_fail (CB_IS_BUNDLE (self), 0);

  gvalue = find_value (self, key);

  if (gvalue != NULL)
    return g_value_get_int (gvalue);

  return -1;
}

void
cb_bundle_put_int64 (CbBundle *self,
                     int       key,
                     gint64    val)
{
  GValue *gvalue;

  g_return_if_fail (CB_IS_BUNDLE (self));

  g_assert (find_value (self, key) == NULL);

  g_array_append_val (self->keys, key);
  g_array_set_size (self->values, self->values->len + 1);
  gvalue = &g_array_index (self->values, GValue, self->values->len - 1);

  g_assert (self->keys->len == self->values->len);

  g_value_init (gvalue, G_TYPE_INT64);

  g_value_set_int64 (gvalue, val);
}

gint64
cb_bundle_get_int64 (CbBundle *self,
                     int       key)
{
  GValue *gvalue;

  g_return_val_if_fail (CB_IS_BUNDLE (self), 0);

  gvalue = find_value (self, key);

  if (gvalue != NULL)
    return g_value_get_int64 (gvalue);

  return -1;
}

void
cb_bundle_put_bool (CbBundle *self,
                    int       key,
                    gboolean  val)
{
  GValue *gvalue;

  g_return_if_fail (CB_IS_BUNDLE (self));

  g_assert (find_value (self, key) == NULL);

  g_array_append_val (self->keys, key);
  g_array_set_size (self->values, self->values->len + 1);
  gvalue = &g_array_index (self->values, GValue, self->values->len - 1);

  g_assert (self->keys->len == self->values->len);

  g_value_init (gvalue, G_TYPE_BOOLEAN);

  g_value_set_boolean (gvalue, val);
}

gboolean
cb_bundle_get_bool (CbBundle *self,
                    int       key)
{
  GValue *gvalue;

  g_return_val_if_fail (CB_IS_BUNDLE (self), 0);

  gvalue = find_value (self, key);

  if (gvalue != NULL)
    return g_value_get_boolean (gvalue);

  return FALSE;
}

void
cb_bundle_put_object (CbBundle *self,
                      int       key,
                      GObject  *val)
{
  GValue *gvalue;

  g_return_if_fail (CB_IS_BUNDLE (self));

  g_assert (find_value (self, key) == NULL);

  g_array_append_val (self->keys, key);
  g_array_set_size (self->values, self->values->len + 1);
  gvalue = &g_array_index (self->values, GValue, self->values->len - 1);

  g_assert (self->keys->len == self->values->len);

  g_value_init (gvalue, G_TYPE_POINTER);

  g_value_set_pointer (gvalue, g_object_ref (val));
}

GObject *
cb_bundle_get_object (CbBundle *self,
                      int       key)
{
  GValue *gvalue;

  g_return_val_if_fail (CB_IS_BUNDLE (self), 0);

  gvalue = find_value (self, key);

  if (gvalue != NULL)
    return g_value_get_pointer (gvalue);

  return NULL;
}

gboolean
cb_bundle_equals (CbBundle *self,
                  CbBundle *other)
{
  guint i;

  g_return_val_if_fail (CB_IS_BUNDLE (self), FALSE);

  if (other == NULL)
    return FALSE;

  g_return_val_if_fail (CB_IS_BUNDLE (other), FALSE);

  for (i = 0; i < self->values->len; i ++)
    {
      GValue *v1;
      GValue *v2;
      char *contents1;
      char *contents2;
      int key = g_array_index (self->keys, int, i);

      v1 = find_value (self, key);
      v2 = find_value (other, key);

      /* They must contains the same keys */
      if (v1 == NULL)
        return FALSE;

      contents1 = g_strdup_value_contents (v1);
      contents2 = g_strdup_value_contents (v2);

      if (strcmp (contents1, contents2) != 0)
        return FALSE;

      g_free (contents1);
      g_free (contents2);
    }

  return self->keys->len == other->keys->len;
}

static void
cb_bundle_finalize (GObject *object)
{
  guint i;
  CbBundle *self = CB_BUNDLE (object);

  /* _put_object ref's the object, so unref it here */
  for (i = 0; i < self->values->len; i ++)
    {
      GValue *v = &g_array_index (self->values, GValue, i);

      /* We only insert pointers for _put_object */
      if (G_VALUE_HOLDS_POINTER (v))
        g_object_unref (G_OBJECT (g_value_get_pointer (v)));
    }

  g_array_unref (self->keys);
  g_array_unref (self->values);

  G_OBJECT_CLASS (cb_bundle_parent_class)->finalize (object);
}

static void
cb_bundle_class_init (CbBundleClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_bundle_finalize;
}

static void
cb_bundle_init (CbBundle *self)
{
  self->keys   = g_array_new (FALSE, FALSE, sizeof (int));
  self->values = g_array_new (FALSE, TRUE, sizeof (GValue));
  g_array_set_clear_func (self->values, (GDestroyNotify)g_value_reset);
}
