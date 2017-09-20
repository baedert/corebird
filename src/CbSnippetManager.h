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
#ifndef _CB_SNIPPET_MANAGER_H
#define _CB_SNIPPET_MANAGER_H

#include <glib.h>
#include <glib-object.h>
#include <sqlite3.h>

struct _CbSnippetManager
{
  GObject parent_instance;

  GHashTable *snippets;
  sqlite3 *db;
  guint inited : 1;
};
typedef struct _CbSnippetManager CbSnippetManager;

#define CB_TYPE_SNIPPET_MANAGER cb_snippet_manager_get_type ()
G_DECLARE_FINAL_TYPE (CbSnippetManager, cb_snippet_manager, CB, SNIPPET_MANAGER, GObject);

/*
 * TODO: This is only a GObject because we can bind that properly in the vapi,
 * but a SnippetManager exists only once and for the entire lifetime of the GtkApplication
 * object we have...
 */

CbSnippetManager * cb_snippet_manager_new            (sqlite3 *db);
guint              cb_snippet_manager_n_snippets     (CbSnippetManager *self);
void               cb_snippet_manager_remove_snippet (CbSnippetManager *self,
                                                      const char       *snippet_key);
void               cb_snippet_manager_insert_snippet (CbSnippetManager *self,
                                                      const char       *key,
                                                      const char       *value);
const char *       cb_snippet_manager_get_snippet    (CbSnippetManager *self,
                                                      const char       *key);
void               cb_snippet_manager_query_snippets (CbSnippetManager *self,
                                                      GHFunc            func,
                                                      gpointer          user_data);
void               cb_snippet_manager_set_snippet    (CbSnippetManager *self,
                                                      const char       *old_key,
                                                      const char       *key,
                                                      const char       *value);
#endif
