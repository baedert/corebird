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

#include "CbFilter.h"


G_DEFINE_TYPE (CbFilter, cb_filter, G_TYPE_OBJECT);

static void
cb_filter_finalize (GObject *obj)
{
  CbFilter *filter = CB_FILTER (obj);

  g_free (filter->contents);
  if (filter->regex != NULL)
    g_regex_unref (filter->regex);

  G_OBJECT_CLASS (cb_filter_parent_class)->finalize (obj);
}

static void
cb_filter_init (CbFilter *filter)
{
  filter->contents = NULL;
  filter->regex = NULL;
}

static void
cb_filter_class_init (CbFilterClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_filter_finalize;
}

CbFilter *
cb_filter_new (const char *expr)
{
  CbFilter *filter = CB_FILTER (g_object_new (CB_TYPE_FILTER, NULL));

  cb_filter_reset (filter, expr);

  return filter;
}

void
cb_filter_reset (CbFilter *filter, const char *expr)
{
  g_return_if_fail (CB_IS_FILTER (filter));
  g_return_if_fail (expr != NULL);

  filter->regex = g_regex_new (expr,
                               G_REGEX_CASELESS,
                               0, /* No match flags */
                               NULL);
  filter->contents = g_strdup (expr);
}

gboolean
cb_filter_matches (CbFilter *filter, const char *text)
{
  g_return_val_if_fail (CB_IS_FILTER (filter), FALSE);
  g_return_val_if_fail (text != NULL, FALSE);

  if (filter->regex == NULL)
    return FALSE;

  return g_regex_match (filter->regex,
                        text,
                        0,
                        NULL);
}


const char *
cb_filter_get_contents (CbFilter *filter)
{
  g_return_val_if_fail (CB_IS_FILTER (filter), "");

  return filter->contents;
}

int
cb_filter_get_id (CbFilter *filter)
{
  g_return_val_if_fail (CB_IS_FILTER (filter), 0);

  return filter->id;
}

void
cb_filter_set_id (CbFilter *filter, int id)
{
  g_return_if_fail (CB_IS_FILTER (filter));
  g_return_if_fail (id >= 0);

  filter->id = id;
}
