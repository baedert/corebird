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

#ifndef _CB_UTILS_H_
#define _CB_UTILS_H_

#include <gtk/gtk.h>
#include <glib-object.h>
#include "CbTypes.h"
#include "rest/rest-proxy-call.h"
#include "rest/rest-proxy.h"


#define CB_TRANSITION_DURATION (200 * 1000)



typedef GtkWidget * (*CbUtilsCreateWidgetFunc) (gpointer  data, gpointer  user_data);


void cb_utils_bind_model (GtkWidget                  *listbox,
                          GListModel                 *model,
                          GtkListBoxCreateWidgetFunc  func,
                          void                       *data);

void cb_utils_bind_non_gobject_model (GtkWidget               *listbox,
                                      GListModel              *model,
                                      CbUtilsCreateWidgetFunc  func,
                                      gpointer                 user_data);

void cb_utils_unbind_non_gobject_model (GtkWidget  *listbox,
                                        GListModel *model);

void cb_utils_linkify_user (const CbUserIdentity *user,
                            GString              *str);

void cb_utils_write_reply_text (const CbMiniTweet *t,
                                GString           *str);

char * cb_utils_escape_quotes (const char *in);
char * cb_utils_escape_ampersands (const char *in);

GDateTime * cb_utils_parse_date (const char *_in);

char * cb_utils_get_file_type (const char *url);
char * cb_utils_rest_proxy_call_to_string (RestProxyCall *call);

void     cb_utils_load_threaded_async  (RestProxyCall       *call,
                                        GCancellable        *cancellable,
                                        GAsyncReadyCallback  callback,
                                        gpointer             user_data);

JsonNode *cb_utils_load_threaded_finish (GAsyncResult   *result,
                                         GError        **error);

void              cb_utils_query_users_async (RestProxy           *proxy,
                                              const char          *query,
                                              GCancellable        *cancellable,
                                              GAsyncReadyCallback  callback,
                                              gpointer             user_data);
CbUserIdentity * cb_utils_query_users_finish (GAsyncResult  *result,
                                              int           *out_length,
                                              GError       **error);

GskTexture *cb_utils_surface_to_texture (cairo_surface_t *surface,
                                         int              scale);

char * cb_utils_get_time_delta (GDateTime *time,
                                GDateTime *now);

void   cb_utils_load_custom_css (void);

static inline void
cb_clear_source (guint *id)
{
  if (*id == 0)
    return;

  g_source_remove (*id);
  *id = 0;
}

static inline double
ease_out_cubic (double t)
{
  double p = t - 1;
  return p * p * p + 1;
}

#endif
