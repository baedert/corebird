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


GType cb_user_counter_get_type (void) G_GNUC_CONST;

CbUserCounter * cb_user_counter_new (void);

void  cb_user_counter_id_seen (CbUserCounter        *counter,
                               const CbUserIdentity *id);

void  cb_user_counter_user_seen (CbUserCounter *counter,
                                 gint64         user_id,
                                 const char    *screen_name,
                                 const char    *user_name);

int  cb_user_counter_save (CbUserCounter *counter, sqlite3 *db);

void cb_user_counter_query_by_prefix (CbUserCounter *counter,
                                      sqlite3       *db,
                                      const char    *prefix,
                                      int            max_results,
                                      CbUserInfo   **results,
                                      int           *n_results);

/* CbUserInfo */
void cb_user_info_destroy (CbUserInfo *info);

G_END_DECLS

#endif

