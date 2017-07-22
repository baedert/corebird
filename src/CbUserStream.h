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
#include <rest/rest-proxy.h>

G_BEGIN_DECLS

typedef enum {
  CB_STREAM_MESSAGE_UNSUPPORTED,
  CB_STREAM_MESSAGE_DELETE,
  CB_STREAM_MESSAGE_DM_DELETE,
  CB_STREAM_MESSAGE_SCRUB_GEO,
  CB_STREAM_MESSAGE_LIMIT,
  CB_STREAM_MESSAGE_DISCONNECT,
  CB_STREAM_MESSAGE_FRIENDS,
  CB_STREAM_MESSAGE_EVENT,
  CB_STREAM_MESSAGE_WARNING,
  CB_STREAM_MESSAGE_DIRECT_MESSAGE,

  CB_STREAM_MESSAGE_TWEET,
  CB_STREAM_MESSAGE_EVENT_LIST_CREATED,
  CB_STREAM_MESSAGE_EVENT_LIST_DESTROYED,
  CB_STREAM_MESSAGE_EVENT_LIST_UPDATED,
  CB_STREAM_MESSAGE_EVENT_LIST_UNSUBSCRIBED,
  CB_STREAM_MESSAGE_EVENT_LIST_SUBSCRIBED,
  CB_STREAM_MESSAGE_EVENT_LIST_MEMBER_ADDED,
  CB_STREAM_MESSAGE_EVENT_LIST_MEMBER_REMOVED,
  CB_STREAM_MESSAGE_EVENT_FAVORITE,
  CB_STREAM_MESSAGE_EVENT_UNFAVORITE,
  CB_STREAM_MESSAGE_EVENT_FOLLOW,
  CB_STREAM_MESSAGE_EVENT_UNFOLLOW,
  CB_STREAM_MESSAGE_EVENT_BLOCK,
  CB_STREAM_MESSAGE_EVENT_UNBLOCK,
  CB_STREAM_MESSAGE_EVENT_MUTE,
  CB_STREAM_MESSAGE_EVENT_UNMUTE,
  CB_STREAM_MESSAGE_EVENT_USER_UPDATE,
  CB_STREAM_MESSAGE_EVENT_QUOTED_TWEET
} CbStreamMessageType;

#if 0
typedef struct _CbUserStream      CbUserStream;

#define CB_TYPE_USER_STREAM (cb_user_stream_get_type ())
G_DECLARE_FINAL_TYPE (CbUserStream, cb_user_stream, CB, USER_STREAM, GObject);

struct _CbUserStream
{
  GObject parent_instance;

  GPtrArray *receivers;
  RestProxy *proxy;
  GNetworkMonitor *network_monitor;
};

struct _CbUserStreamClass
{
  GObjectClass parent_class;
};

GType cb_user_stream_get_type (void) G_GNUC_CONST;

CbUserStream *cb_user_stream_new (const char *account_name);
void          cb_user_stream_set_proxy_data (CbUserStream *self,
                                             const char   *token,
                                             const char   *token_secret);


G_END_DECLS;

#endif
#endif
