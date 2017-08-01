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

#ifndef __CB_USER_STREAM_H__
#define __CB_USER_STREAM_H__

#include <glib-object.h>
#include "rest/rest/rest-proxy.h"
#include "CbMessageReceiver.h"
#include "CbTypes.h"

G_BEGIN_DECLS
typedef struct _CbUserStream      CbUserStream;

#define CB_TYPE_USER_STREAM (cb_user_stream_get_type ())
G_DECLARE_FINAL_TYPE (CbUserStream, cb_user_stream, CB, USER_STREAM, GObject);

struct _CbUserStream
{
  GObject parent_instance;

  GString *data;
  GPtrArray *receivers;
  RestProxy *proxy;
  RestProxyCall *proxy_call;
  GNetworkMonitor *network_monitor;

  guint network_timeout_id;
  guint heartbeat_timeout_id;
  guint network_changed_id;

  char *account_name;

  guint state;
  guint restarting : 1;
  guint proxy_data_set : 1;
  guint network_available: 1;

  guint stresstest : 1;
};

struct _CbUserStreamClass
{
  GObjectClass parent_class;
};

GType cb_user_stream_get_type (void) G_GNUC_CONST;

CbUserStream *cb_user_stream_new (const char *account_name,
                                  gboolean    stresstest);
void          cb_user_stream_set_proxy_data (CbUserStream *self,
                                             const char   *token,
                                             const char   *token_secret);

void          cb_user_stream_register (CbUserStream      *self,
                                       CbMessageReceiver *receiver);

void          cb_user_stream_unregister (CbUserStream      *self,
                                         CbMessageReceiver *receiver);

void          cb_user_stream_start (CbUserStream *self);

void          cb_user_stream_stop  (CbUserStream *self);

void          cb_user_stream_push_data (CbUserStream *self,
                                        const char   *data);


G_END_DECLS;

#endif
