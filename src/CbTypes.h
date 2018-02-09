/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2016 Timm Bäder
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

#ifndef __TYPES_H
#define __TYPES_H

#include <glib-object.h>
#include <json-glib/json-glib.h>
#include "CbMedia.h"

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

struct _CbUserIdentity
{
  gint64  id;
  guint   verified : 1;
  char   *screen_name;
  char   *user_name;
};
typedef struct _CbUserIdentity CbUserIdentity;
void cb_user_identity_free (CbUserIdentity *id);
void cb_user_identity_copy (const CbUserIdentity *id, CbUserIdentity *id2);

void cb_user_identity_parse (CbUserIdentity *id, JsonObject *user_obj);

struct _CbTextEntity
{
  guint  from;
  guint  to;
  char  *display_text;
  char  *tooltip_text;
  char  *target;
};
typedef struct _CbTextEntity CbTextEntity;
void cb_text_entity_free (CbTextEntity *e);
void cb_text_entity_copy (const CbTextEntity *e1, CbTextEntity *e2);

struct _CbMiniTweet
{
  gint64 id;
  gint64 created_at;
  guint display_range_start;
  CbUserIdentity author;
  char *text;
  gint64 reply_id;

  CbTextEntity *entities;
  guint n_entities;

  CbMedia **medias;
  guint n_medias;

  CbUserIdentity *reply_users;
  guint n_reply_users;
};
typedef struct _CbMiniTweet CbMiniTweet;
void cb_mini_tweet_free (CbMiniTweet *tweet);
void cb_mini_tweet_copy (const CbMiniTweet *t1, CbMiniTweet *t2);
void cb_mini_tweet_init (CbMiniTweet *t);
void cb_mini_tweet_parse (CbMiniTweet *t, JsonObject *obj);
void cb_mini_tweet_parse_entities (CbMiniTweet *t, JsonObject *obj);

#endif
