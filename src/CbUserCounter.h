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

#ifndef USER_COUNTER_H
#define USER_COUNTER_H

#include <glib-object.h>
#include <sqlite3.h>

#include "CbTypes.h"

G_BEGIN_DECLS


typedef struct _CbUserInfo CbUserInfo;
struct _CbUserInfo
{
  gint64 user_id;
  char *screen_name;
  char *user_name;
  guint score;
  guint changed : 1;
};


typedef struct _CbUserCounter CbUserCOunter;
struct _CbUserCounter
{
  GObject parent_instance;

  guint changed : 1;
  GArray *user_infos;
};

#define CB_TYPE_USER_COUNTER cb_user_counter_get_type ()
G_DECLARE_FINAL_TYPE (CbUserCounter, cb_user_counter, CB, USER_COUNTER, GObject);


CbUserCounter * cb_user_counter_new             (void);
void            cb_user_counter_id_seen         (CbUserCounter        *counter,
                                                 const CbUserIdentity *id);
void            cb_user_counter_user_seen       (CbUserCounter *counter,
                                                 gint64         user_id,
                                                 const char    *screen_name,
                                                 const char    *user_name);
int             cb_user_counter_save            (CbUserCounter *counter,
                                                 sqlite3       *db);
void            cb_user_counter_query_by_prefix (CbUserCounter *counter,
                                                 sqlite3       *db,
                                                 const char    *prefix,
                                                 int            max_results,
                                                 CbUserInfo   **results,
                                                 int           *n_results);

/* CbUserInfo */
void cb_user_info_destroy (CbUserInfo *info);

G_END_DECLS

#endif

