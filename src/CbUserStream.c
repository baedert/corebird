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

#include "CbUserStream.h"
#include "CbUtils.h"
#include "rest/rest/oauth-proxy.h"
#include <string.h>

G_DEFINE_TYPE (CbUserStream, cb_user_stream, G_TYPE_OBJECT);


enum {
  INTERRUPTED,
  RESUMED,
  LAST_SIGNAL
};

enum {
  STATE_STOPPED,    /* Initial state */
  STATE_RUNNING,    /* Started and message received */
  STATE_STARTED,    /* Started, but no message/heartbeat received yet */
  STATE_STOPPING,   /* Stopping the stream */
};

static guint user_stream_signals[LAST_SIGNAL] = { 0 };

static void
cb_user_stream_finalize (GObject *o)
{
  CbUserStream *self = CB_USER_STREAM (o);

  cb_user_stream_stop (self);

  g_ptr_array_unref (self->receivers);
  g_string_free (self->data, TRUE);
  g_free (self->account_name);

  if (self->network_changed_id != 0)
    {
      g_signal_handler_disconnect (self->network_monitor, self->network_changed_id);
    }

  G_OBJECT_CLASS (cb_user_stream_parent_class)->finalize (o);
}

static void
cb_user_stream_restart (CbUserStream *self)
{
  self->restarting = TRUE;
  cb_user_stream_stop (self);
  cb_user_stream_start (self);
}

static gboolean
network_cb (gpointer user_data)
{
  CbUserStream *self = user_data;
  gboolean available;

  if (self->state == STATE_RUNNING)
    {
      self->network_timeout_id = 0;
      return G_SOURCE_REMOVE;
    }

  available = g_network_monitor_get_network_available (self->network_monitor);

  if (available)
    {
      g_debug ("%u Restarting stream (reason: network available (timeout))", self->state);
      self->network_timeout_id = 0;
      cb_user_stream_restart (self);
      return G_SOURCE_REMOVE;
    }

  return G_SOURCE_CONTINUE;
}

static void
start_network_timeout (CbUserStream *self)
{
  if (self->network_timeout_id != 0)
    return;

  self->network_timeout_id = g_timeout_add (1 * 1000, network_cb, self);
}

static void
network_changed_cb (GNetworkMonitor *monitor,
                    gboolean         available,
                    gpointer         user_data)
{
  CbUserStream *self = user_data;

  if (available == self->network_available)
    return;

  self->network_available = available;

  if (available)
    {
      g_debug ("%u Restarting stream (reason: Network available (callback))", self->state);
      cb_user_stream_restart (self);
    }
  else
    {
      g_debug ("%u Connection lost (%s) Reason: network unavailable", self->state, self->account_name);
      g_signal_emit (self, user_stream_signals[INTERRUPTED], 0);
      cb_clear_source (&self->heartbeat_timeout_id);

      start_network_timeout (self);
    }
}

static gboolean
heartbeat_cb (gpointer user_data)
{
  CbUserStream *self = user_data;

  g_debug ("%u Connection lost (%s) Reason: heartbeat. Restarting...", self->state, self->account_name);
  cb_user_stream_restart (self);
  /* We do NOT set heartbeat_timeout_id to 0 here since the _start call in the restart() above
   * will already create a new one... */

  return G_SOURCE_REMOVE;
}

static void
start_heartbeat_timeout (CbUserStream *self)
{
  if (self->heartbeat_timeout_id != 0)
    return;

  self->heartbeat_timeout_id = g_timeout_add (45 * 1000, heartbeat_cb, self);
}

static void
cb_user_stream_init (CbUserStream *self)
{
  self->receivers = g_ptr_array_new ();
  self->data = g_string_new (NULL);
  self->restarting = FALSE;
  self->state = STATE_STOPPED;

  if (self->stresstest)
    {
      self->proxy = oauth_proxy_new ("0rvHLdbzRULZd5dz6X1TUA",
                                     "oGrvd6654nWLhzLcJywSW3pltUfkhP4BnraPPVNhHtY",
                                     "https://stream.twitter.com/",
                                     FALSE);
    }
  else
    {
      /* TODO: We should be getting these from the settings */
      self->proxy = oauth_proxy_new ("0rvHLdbzRULZd5dz6X1TUA",
                                     "oGrvd6654nWLhzLcJywSW3pltUfkhP4BnraPPVNhHtY",
                                     "https://userstream.twitter.com/",
                                     FALSE);
    }
  self->proxy_data_set = FALSE;

  self->network_monitor = g_network_monitor_get_default ();
  self->network_available = g_network_monitor_get_network_available (self->network_monitor);
  self->network_changed_id = g_signal_connect (self->network_monitor,
                                               "network-changed",
                                               G_CALLBACK (network_changed_cb), self);

  if (!self->network_available)
    start_network_timeout (self);
}

static void
cb_user_stream_class_init (CbUserStreamClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_user_stream_finalize;

  user_stream_signals[INTERRUPTED] = g_signal_new ("interrupted",
                                                   G_OBJECT_CLASS_TYPE (object_class),
                                                   G_SIGNAL_RUN_FIRST,
                                                   0,
                                                   NULL, NULL,
                                                   NULL, G_TYPE_NONE, 0);

  user_stream_signals[RESUMED] = g_signal_new ("resumed",
                                                G_OBJECT_CLASS_TYPE (object_class),
                                                G_SIGNAL_RUN_FIRST,
                                                0,
                                                NULL, NULL,
                                                NULL, G_TYPE_NONE, 0);
}

CbUserStream *
cb_user_stream_new (const char *account_name,
                    gboolean    stresstest)
{
  CbUserStream *self = CB_USER_STREAM (g_object_new (CB_TYPE_USER_STREAM, NULL));
  self->account_name = g_strdup (account_name);
  self->stresstest = stresstest;

  g_debug ("Creating stream for %s", account_name);

  return self;
}

static CbStreamMessageType
get_event_type (const char *s)
{
  gsize len = strlen (s);

  switch (len)
    {
      case 4:
        if (strcmp (s, "mute") == 0)
          return CB_STREAM_MESSAGE_EVENT_MUTE;
        break;

      case 5:
        if (strcmp (s, "block") == 0)
          return CB_STREAM_MESSAGE_EVENT_BLOCK;
        break;

      case 6:
        if (strcmp (s, "unmute") == 0)
          return CB_STREAM_MESSAGE_EVENT_UNMUTE;
        if (strcmp (s, "follow") == 0)
          return CB_STREAM_MESSAGE_EVENT_FOLLOW;
        break;

      case 7:
        if (strcmp (s, "unblock") == 0)
          return CB_STREAM_MESSAGE_EVENT_UNBLOCK;
        break;

      case 8:
        if (strcmp (s, "favorite") == 0)
          return CB_STREAM_MESSAGE_EVENT_FAVORITE;
        if (strcmp (s, "unfollow") ==0)
          return CB_STREAM_MESSAGE_EVENT_UNFOLLOW;
        break;

      case 10:
        if (strcmp (s, "unfavorite") == 0)
          return CB_STREAM_MESSAGE_EVENT_UNFAVORITE;
        break;

      case 11:
        if (strcmp (s, "user_update") == 0)
          return CB_STREAM_MESSAGE_EVENT_USER_UPDATE;
        break;

      case 12:
        if (strcmp (s, "list_created") == 0)
          return CB_STREAM_MESSAGE_EVENT_LIST_CREATED;
        if (strcmp (s, "quoted_tweet") == 0)
          return CB_STREAM_MESSAGE_EVENT_QUOTED_TWEET;
        if (strcmp (s, "list_updated") == 0)
          return CB_STREAM_MESSAGE_EVENT_LIST_UPDATED;;
        break;

      case 14:
        if (strcmp (s, "list_destroyed") == 0)
          return CB_STREAM_MESSAGE_EVENT_LIST_DESTROYED;
        break;

      case 17:
        if (strcmp (s, "list_member_added") == 0)
          return CB_STREAM_MESSAGE_EVENT_LIST_MEMBER_ADDED;
        break;

      case 19:
        if (strcmp (s, "list_member_removed") == 0)
          return CB_STREAM_MESSAGE_EVENT_LIST_MEMBER_REMOVED;
        break;

      case 20:
        if (strcmp (s, "list_user_subscribed") == 0)
          return CB_STREAM_MESSAGE_EVENT_LIST_SUBSCRIBED;
        break;

      case 22:
        if (strcmp (s, "list_user_unsubscribed") == 0)
          return CB_STREAM_MESSAGE_EVENT_LIST_UNSUBSCRIBED;
        break;
    }

  return CB_STREAM_MESSAGE_UNSUPPORTED;
}

static void
continuous_cb (RestProxyCall *call,
               const gchar   *buf,
               gsize          len,
               const GError  *error,
               GObject       *weak_object,
               gpointer       user_data)
{
  CbUserStream *self = user_data;

  if (buf == NULL)
    {
      /* buff == NULL && error != NULL is what happens when the message gets cancelled.
       * This might happen a few seconds after the CbUserStream instance is finalized, so
       * make sure we don't use it here. */
      if (error != NULL)
        return;

      if (self->state != STATE_STOPPING)
        {
          g_debug ("%u, buf(%s) == NULL. Starting timeout...", self->state, self->account_name);
          start_network_timeout (self);
        }
      return;
    }

  g_string_append_len (self->data, buf, len);

  /* Actual messages end with \r\n */
  if ((len >= 2 && buf[len - 1] == '\n' && buf[len - 2] == '\r') ||
      (len >= 1 && buf[len - 1] == '\r'))
    {
      if (self->restarting)
        {
          g_signal_emit (self, user_stream_signals[RESUMED], 0);
          self->restarting = FALSE;
        }

      self->state = STATE_RUNNING;

      /* Just \r\n messages are heartbeats. */
      if (len == 2 &&
          buf[0] == '\r' && buf[1] == '\n')
        {
#if DEBUG
          char *date;
          GDateTime *now = g_date_time_new_now_local ();

          date = g_date_time_format (now, "%k:%M:%S");

          g_debug ("%u HEARTBEAT (%s) %s", self->state, self->account_name, date);
          g_free (date);
          g_date_time_unref (now);
#endif
          g_string_erase (self->data, 0, -1);
          cb_clear_source (&self->heartbeat_timeout_id);

          start_heartbeat_timeout (self);
          return;
        }

      /* TODO: Bring "OK" check back? */
      {
        JsonParser *parser;
        JsonNode *root_node;
        JsonObject *root_object;
        CbStreamMessageType message_type;
        GError *error = NULL;
        guint i;

        parser = json_parser_new ();
        json_parser_load_from_data (parser, self->data->str, -1, &error);

        if (error != NULL)
          {
            if (g_str_has_prefix (error->message, "Exceeded connection limit for user"))
              {
                /* Ignore this one, let the next reconnect handle it */
                g_string_erase (self->data, 0, -1);
                return;
              }

            g_warning ("%s: %s", __FUNCTION__, error->message);
            g_warning ("\n%s\n", self->data->str);
            g_string_erase (self->data, 0, -1);
            return;
          }


        root_node = json_parser_get_root (parser);
        root_object = json_node_get_object (root_node);

        message_type = CB_STREAM_MESSAGE_UNSUPPORTED;

        if (json_object_has_member (root_object, "text"))
          {
            message_type = CB_STREAM_MESSAGE_TWEET;
          }
        else if (json_object_has_member (root_object, "delete"))
          {
            JsonObject *d = json_object_get_object_member (root_object, "delete");

            if (json_object_has_member (d, "direct_message"))
              message_type = CB_STREAM_MESSAGE_DM_DELETE;
            else
              message_type = CB_STREAM_MESSAGE_DELETE;
          }
        else if (json_object_has_member (root_object, "scrub_geo"))
          {
            message_type = CB_STREAM_MESSAGE_SCRUB_GEO;
          }
        else if (json_object_has_member (root_object, "limit"))
          {
            message_type = CB_STREAM_MESSAGE_LIMIT;
          }
        else if (json_object_has_member (root_object, "disconnect"))
          {
            message_type = CB_STREAM_MESSAGE_DISCONNECT;
          }
        else if (json_object_has_member (root_object, "friends"))
          {
            message_type = CB_STREAM_MESSAGE_FRIENDS;
          }
        else if (json_object_has_member (root_object, "event"))
          {
            const char *event_name = json_object_get_string_member (root_object, "event");

            message_type = get_event_type (event_name);
          }
        else if (json_object_has_member (root_object, "warning"))
          {
            message_type = CB_STREAM_MESSAGE_WARNING;
          }
        else if (json_object_has_member (root_object, "direct_message"))
          {
            message_type = CB_STREAM_MESSAGE_DIRECT_MESSAGE;
          }
        else if (json_object_has_member (root_object, "status_withheld"))
          {
            message_type = CB_STREAM_MESSAGE_UNSUPPORTED;
          }

#if DEBUG
        g_print ("Message with type %d on stream @%s\n", message_type, self->account_name);
        g_print ("%s\n\n", self->data->str);
#endif

        for (i = 0; i < self->receivers->len; i++)
          cb_message_receiver_stream_message_received (g_ptr_array_index (self->receivers, i),
                                                       message_type,
                                                       root_node);

        g_object_unref (parser);
        g_string_erase (self->data, 0, -1);
      } /* Local block */
    }
}

void
cb_user_stream_start (CbUserStream *self)
{
  g_debug ("%u Starting stream for %s", self->state, self->account_name);

  g_assert (self->proxy_data_set);

  if (self->proxy_call != NULL)
    rest_proxy_call_cancel (self->proxy_call);

  self->proxy_call = rest_proxy_new_call (self->proxy);

  if (self->stresstest)
    rest_proxy_call_set_function (self->proxy_call, "1.1/statuses/sample.json");
  else
    rest_proxy_call_set_function (self->proxy_call, "1.1/user.json");

  rest_proxy_call_set_method (self->proxy_call, "GET");
  start_heartbeat_timeout (self);

  rest_proxy_call_continuous (self->proxy_call,
                              continuous_cb,
                              NULL,
                              self,
                              NULL/* error */);
}

void cb_user_stream_stop (CbUserStream *self)
{
  g_debug ("%u Stopping %s's stream", self->state, self->account_name);

  cb_clear_source (&self->network_timeout_id);
  cb_clear_source (&self->heartbeat_timeout_id);

  if (self->proxy_call != NULL)
    {
      self->state = STATE_STOPPING;
      rest_proxy_call_cancel (self->proxy_call);
      g_object_unref (self->proxy_call);
      self->proxy_call = NULL;
    }

  self->state = STATE_STOPPED;
}

void
cb_user_stream_set_proxy_data (CbUserStream *self,
                               const char   *token,
                               const char   *token_secret)
{
  oauth_proxy_set_token (OAUTH_PROXY (self->proxy), token);
  oauth_proxy_set_token_secret (OAUTH_PROXY (self->proxy), token_secret);

  self->proxy_data_set = TRUE;
}

void
cb_user_stream_register (CbUserStream      *self,
                         CbMessageReceiver *receiver)
{
  g_ptr_array_add (self->receivers, receiver);
}

void
cb_user_stream_unregister (CbUserStream      *self,
                           CbMessageReceiver *receiver)
{
  guint i;

  for (i = 0; i < self->receivers->len; i ++)
    {
      CbMessageReceiver *r = g_ptr_array_index (self->receivers, i);

      if (r == receiver)
        {
          g_ptr_array_remove_index_fast (self->receivers, i);
          break;
        }
    }
}

void
cb_user_stream_push_data (CbUserStream *self,
                          const char   *data)
{
  continuous_cb (self->proxy_call, data, strlen (data), NULL, NULL, self);
}
