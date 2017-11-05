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

#include "CbUserCounter.h"
#include <stdlib.h>


void
cb_user_info_destroy (CbUserInfo *info)
{
  g_free (info->screen_name);
  g_free (info->user_name);
}

static int
score_sort (gconstpointer p1, gconstpointer p2)
{
  const CbUserInfo *ui1 = p1;
  const CbUserInfo *ui2 = p2;

  return ui1->score < ui2->score;
}


G_DEFINE_TYPE (CbUserCounter, cb_user_counter, G_TYPE_OBJECT);

CbUserCounter *
cb_user_counter_new (void)
{
  return CB_USER_COUNTER (g_object_new (CB_TYPE_USER_COUNTER, NULL));
}


void
cb_user_counter_id_seen (CbUserCounter        *counter,
                         const CbUserIdentity *id)
{
  g_return_if_fail (CB_IS_USER_COUNTER (counter));
  g_return_if_fail (id != NULL);

  cb_user_counter_user_seen (counter, id->id, id->screen_name, id->user_name);
}

void
cb_user_counter_user_seen (CbUserCounter *counter,
                           gint64         user_id,
                           const char    *screen_name,
                           const char    *user_name)
{
  gboolean found = FALSE;
  guint i;

  g_return_if_fail (CB_IS_USER_COUNTER (counter));
  g_return_if_fail (screen_name != NULL);
  g_return_if_fail (user_name != NULL);

  for (i = 0; i < counter->user_infos->len; i ++)
    {
      CbUserInfo *ui = &g_array_index (counter->user_infos, CbUserInfo, i);

      if (ui->user_id == user_id)
        {
          ui->score ++;
          ui->changed = TRUE;
          found = TRUE;
          break;
        }
    }

  if (!found)
    {
      CbUserInfo *ui;

      g_array_set_size (counter->user_infos, counter->user_infos->len + 1);
      ui = &g_array_index (counter->user_infos, CbUserInfo, counter->user_infos->len - 1);

      ui->user_id     = user_id;
      ui->screen_name = g_strdup (screen_name);
      ui->user_name   = g_strdup (user_name);
      ui->changed     = TRUE; /* Because we just inserted this, eh */
      ui->score       = 1;
    }
}


int
cb_user_counter_save (CbUserCounter *counter,
                      sqlite3       *db)
{
  int count = 0;
  guint i;

  g_return_val_if_fail (CB_IS_USER_COUNTER (counter), 0);
  g_return_val_if_fail (db != NULL, 0);

  sqlite3_exec (db, "BEGIN TRANSACTION;", NULL, NULL, NULL);

  for (i = 0; i < counter->user_infos->len; i ++)
    {
      sqlite3_stmt *stmt;
      int ok;
      CbUserInfo *ui = &g_array_index (counter->user_infos, CbUserInfo, i);

      if (!ui->changed)
        continue;

      ui->changed = FALSE;

      /* Actually save entry in DB */
      ok = sqlite3_prepare_v2 (db,
                               "INSERT OR REPLACE INTO `user_cache` (id, screen_name, user_name, score) "
                               "VALUES(?, ?, ?, ?)", -1, &stmt, NULL);

      if (ok != SQLITE_OK)
        {
          g_warning ("SQL Error: %s", sqlite3_errmsg (db));
          continue;
        }

      sqlite3_bind_int64 (stmt,  1, ui->user_id);
      sqlite3_bind_text (stmt, 2, ui->screen_name, -1, NULL);
      sqlite3_bind_text (stmt, 3, ui->user_name, -1, NULL);
      sqlite3_bind_int (stmt,  4, ui->score);

      ok = sqlite3_step (stmt);
      if (ok != SQLITE_DONE)
        g_critical ("%s", sqlite3_errstr (ok));

      sqlite3_finalize (stmt);
      count ++;
    }

  sqlite3_exec (db, "END TRANSACTION;", NULL, NULL, NULL);
  counter->changed = FALSE;
  g_array_remove_range (counter->user_infos, 0, counter->user_infos->len);
  return count;
}


static int
query_sqlite_cb (void  *user_data,
                 int    n_columns,
                 char **columns,
                 char **column_names)
{
  struct {
    GArray *infos;
    guint lowest_score;
  } *query_data = user_data;
  CbUserInfo *ui;
  guint i;
  gint64 user_id;

  g_assert (n_columns == 4);

  user_id = strtoull (columns[0], NULL, 10);

  /* Check for duplicates first */
  for (i = 0; i < query_data->infos->len; i ++)
    {
      const CbUserInfo *_ui = &g_array_index (query_data->infos, CbUserInfo, i);
      if (_ui->user_id == user_id)
        return 0;
    }

  g_array_set_size (query_data->infos, query_data->infos->len + 1);
  ui = &g_array_index (query_data->infos, CbUserInfo, query_data->infos->len - 1);

  ui->user_id = user_id;
  ui->screen_name = g_strdup (columns[1]);
  ui->user_name = g_strdup (columns[2]);
  ui->score = atoi (columns[3]);

  query_data->lowest_score = MIN (query_data->lowest_score, ui->score);

  return 0; /* Go on */
}

void
cb_user_counter_query_by_prefix (CbUserCounter *counter,
                                 sqlite3       *db,
                                 const char    *prefix,
                                 guint          max_results,
                                 CbUserInfo  **results,
                                 int           *n_results)
{
  char *sql;
  char *err;
  guint i;
  struct {
    GArray *infos;
    guint lowest_score;
  } query_data;

  g_return_if_fail (CB_IS_USER_COUNTER (counter));
  g_return_if_fail (prefix != NULL);
  g_return_if_fail (results != NULL);
  g_return_if_fail (max_results > 0);
  g_return_if_fail (n_results != NULL);

  query_data.infos = g_array_new (FALSE, TRUE, sizeof (CbUserInfo));
  query_data.lowest_score = G_MAXINT;
  g_array_set_clear_func (query_data.infos, (GDestroyNotify)cb_user_info_destroy);

  for (i = 0; i < counter->user_infos->len; i ++)
    {
      const CbUserInfo *ui = &g_array_index (counter->user_infos, CbUserInfo, i);
      char *user_name;
      char *screen_name;
      gboolean full = query_data.infos->len >= max_results;

      /* Will already be in the results from the sql query */
      if (!ui->changed)
        continue;

      if (full && ui->score < query_data.lowest_score)
        continue;

      screen_name = g_utf8_strdown (ui->screen_name, -1);
      user_name   = g_utf8_strdown (ui->user_name, -1);

      if (g_str_has_prefix (screen_name, prefix) ||
          g_str_has_prefix (user_name, prefix))
        {
          CbUserInfo *new_ui;
          /* Copy user info into result array */
          g_array_set_size (query_data.infos, query_data.infos->len + 1);
          new_ui = &g_array_index (query_data.infos, CbUserInfo, query_data.infos->len - 1);

          new_ui->user_id = ui->user_id;
          new_ui->screen_name = g_strdup (ui->screen_name);
          new_ui->user_name = g_strdup (ui->user_name);
          new_ui->score = ui->score;

          query_data.lowest_score = MIN (query_data.lowest_score, ui->score);
        }

      g_free (user_name);
      g_free (screen_name);
    }

  if (query_data.infos->len == 0)
    query_data.lowest_score = -1;

  sql = g_strdup_printf ("SELECT `id`, `screen_name`, `user_name`, `score` "
                         "FROM `user_cache` WHERE `screen_name` LIKE '%s%%' "
                         "OR `user_name` LIKE '%s%%' ORDER BY `score` DESC LIMIT %d "
                         "COLLATE NOCASE;", prefix, prefix, max_results);

  sqlite3_exec (db, sql, query_sqlite_cb, &query_data, &err);

  if (err != NULL)
    {
      g_critical ("%s SQL Error: %s", __FUNCTION__, err);
      sqlite3_free (err);
    }



  /* Now sort after score */
  g_array_sort (query_data.infos, score_sort);

  /* Remove everything after max_results */
  if (query_data.infos->len > max_results)
    g_array_remove_range (query_data.infos, max_results, query_data.infos->len - max_results);

  g_assert (query_data.infos->len <= max_results);

  /* Just use the GArray's data */
  *n_results = query_data.infos->len;
  *results = (CbUserInfo*) g_array_free (query_data.infos, FALSE);

  g_free (sql);
}

static void
cb_user_counter_finalize (GObject *obj)
{
  CbUserCounter *counter = CB_USER_COUNTER (obj);

  g_array_free (counter->user_infos, TRUE);

  G_OBJECT_CLASS (cb_user_counter_parent_class)->finalize (obj);
}

static void
cb_user_counter_class_init (CbUserCounterClass *counter_class)
{
  GObjectClass *object_class = G_OBJECT_CLASS (counter_class);

  object_class->finalize = cb_user_counter_finalize;
}

static void
cb_user_counter_init (CbUserCounter *counter)
{
  counter->changed = FALSE;
  counter->user_infos = g_array_new (FALSE, TRUE, sizeof (CbUserInfo));
  g_array_set_clear_func (counter->user_infos, (GDestroyNotify)cb_user_info_destroy);
}
