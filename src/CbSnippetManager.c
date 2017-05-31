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

#include "CbSnippetManager.h"


G_DEFINE_TYPE (CbSnippetManager, cb_snippet_manager, G_TYPE_OBJECT);


static int
load_snippet_cb (void *data, int n_cols, char **col_text, char **col_name)
{
  CbSnippetManager *self = data;

  g_hash_table_insert (self->snippets, g_strdup (col_text[1]), g_strdup (col_text[2]));

  return 0;
}

static void
cb_snippet_manager_load_snippets (CbSnippetManager *self)
{
  char *err = NULL;

  g_assert (!self->inited);

  sqlite3_exec (self->db,
                "SELECT `id`, `key`, `value` FROM `snippets` ORDER BY `id`;",
                load_snippet_cb,
                self,
                &err);

  if (err != NULL)
    {
      g_warning ("Couldn't load snippets: %s", err);
      g_free (err);
      return;
    }
}

static void
cb_snippet_manager_finalize (GObject *object)
{
  CbSnippetManager *self = CB_SNIPPET_MANAGER (object);

  g_hash_table_destroy (self->snippets);

  G_OBJECT_CLASS (cb_snippet_manager_parent_class)->finalize (object);
}

static void
cb_snippet_manager_class_init (CbSnippetManagerClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_snippet_manager_finalize;
}

CbSnippetManager *
cb_snippet_manager_new (sqlite3 *db)
{
  CbSnippetManager *sm = CB_SNIPPET_MANAGER (g_object_new (CB_TYPE_SNIPPET_MANAGER, NULL));

  sm->db = db;

  return sm;
}

static void
cb_snippet_manager_init (CbSnippetManager *self)
{
  self->inited = FALSE;
  self->snippets = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);
}

guint
cb_snippet_manager_n_snippets (CbSnippetManager *self)
{
  if (!self->inited)
    cb_snippet_manager_load_snippets (self);

  return g_hash_table_size (self->snippets);
}

void
cb_snippet_manager_remove_snippet (CbSnippetManager *self,
                                   const char       *snippet_key)
{
  sqlite3_stmt *stmt;

  if (!self->inited)
    cb_snippet_manager_load_snippets (self);

  g_hash_table_remove (self->snippets, snippet_key);
  sqlite3_prepare_v2 (self->db,
                      "DELETE FROM `snippets` WHERE `key`=?;",
                      -1, &stmt, NULL);
  sqlite3_bind_text (stmt, 1, snippet_key, -1, NULL);

  if (sqlite3_step (stmt) != SQLITE_DONE)
    {
      g_warning ("Couldn't remove snippet %s", snippet_key);
    }
  sqlite3_finalize (stmt);
}

void
cb_snippet_manager_insert_snippet (CbSnippetManager *self,
                                   const char       *key,
                                   const char       *value)
{
  sqlite3_stmt *stmt;

  if (!self->inited)
    cb_snippet_manager_load_snippets (self);

  g_hash_table_insert (self->snippets, g_strdup (key), g_strdup (value));

  sqlite3_prepare_v2 (self->db,
                      "INSERT INTO `snippets`(`key`, `value`) VALUES (?, ?);",
                      -1, &stmt, NULL);

  sqlite3_bind_text (stmt, 1, key, -1, NULL);
  sqlite3_bind_text (stmt, 2, value, -1, NULL);

  if (sqlite3_step (stmt) != SQLITE_DONE)
    g_warning ("Couldn't insert snippet %s", key);

  sqlite3_finalize (stmt);
}

const char *
cb_snippet_manager_get_snippet (CbSnippetManager *self,
                                const char       *key)
{
  if (!self->inited)
    cb_snippet_manager_load_snippets (self);

  return g_hash_table_lookup (self->snippets, key);
}

void
cb_snippet_manager_query_snippets (CbSnippetManager *self,
                                   GHFunc            func,
                                   gpointer          user_data)
{
  if (!self->inited)
    cb_snippet_manager_load_snippets (self);

  g_hash_table_foreach (self->snippets, func, user_data);
}

void
cb_snippet_manager_set_snippet (CbSnippetManager *self,
                                const char       *old_key,
                                const char       *key,
                                const char       *value)
{
  if (!self->inited)
    cb_snippet_manager_load_snippets (self);

  if (!g_hash_table_contains (self->snippets, old_key))
    {
      g_warning ("No snippet '%s' found in database", old_key);
      return;
    }

  cb_snippet_manager_remove_snippet (self, old_key);
  cb_snippet_manager_insert_snippet (self, key, value);
}
