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

#ifndef __TWEET_H
#define __TWEET_H

#include <glib-object.h>
#include <json-glib/json-glib.h>
#include "Types.h"
#include "Media.h"

#define CB_TWEET_MAX_LENGTH 140

typedef enum
{
  /** Force hiding (there's no way this flag will ever get flipped...)*/
  CB_TWEET_STATE_HIDDEN_FORCE             = 1 << 0,
  /** Hidden because we unfollowed the author */
  CB_TWEET_STATE_HIDDEN_UNFOLLOWED        = 1 << 1,
  /** Hidden because one of the filters matched the tweet */
  CB_TWEET_STATE_HIDDEN_FILTERED          = 1 << 2,
  CB_TWEET_STATE_HIDDEN_RTS_DISABLED      = 1 << 3,
  /** Hidden because it's a RT by the authenticating user */
  CB_TWEET_STATE_HIDDEN_RT_BY_USER        = 1 << 4,
  CB_TWEET_STATE_HIDDEN_RT_BY_FOLLOWEE    = 1 << 5,
  /** Hidden because the author is blocked */
  CB_TWEET_STATE_HIDDEN_AUTHOR_BLOCKED    = 1 << 6,
  /** Hidden because the author of a retweet is blocked */
  CB_TWEET_STATE_HIDDEN_RETWEETER_BLOCKED = 1 << 7,
  /** Hidden because the author was muted */
  CB_TWEET_STATE_HIDDEN_AUTHOR_MUTED      = 1 << 8,
  /** Hidden because the author of a retweet is muted */
  CB_TWEET_STATE_HIDDEN_RETWEETER_MUTED   = 1 << 9,

  /* The authenticating user retweeted this tweet */
  CB_TWEET_STATE_RETWEETED                = 1 << 10,
  /* The authenticating user favorited this tweet */
  CB_TWEET_STATE_FAVORITED                = 1 << 11,
  /* This tweet has been deleted by its author */
  CB_TWEET_STATE_DELETED                  = 1 << 12,
  /* The author of this tweet is verified */
  CB_TWEET_STATE_VERIFIED                 = 1 << 13,
  /* The author of this tweet is protected */
  CB_TWEET_STATE_PROTECTED                = 1 << 14,
  /* At least one media attached to this tweet is marked sensitive */
  CB_TWEET_STATE_NSFW                     = 1 << 15
} CbTweetState;


struct _CbTweet
{
  GObject parent_instance;

  guint state : 16;

  gint64 id;
  CbMiniTweet source_tweet;
  CbMiniTweet *retweeted_tweet;
  CbMiniTweet *quoted_tweet;
  char *avatar_url;
  gint64 my_retweet;
  char *notification_id;
  guint seen : 1;
  /** if 0, this tweet is NOT part of a conversation */
  gint64 reply_id;
  guint retweet_count;
  guint favorite_count;

#ifdef DEBUG
  /* In debug mode, we save the entire json we got from Twitter so we can later look at it */
  char *json_data;
#endif
};
typedef struct _CbTweet CbTweet;

#define CB_TYPE_TWEET cb_tweet_get_type ()
G_DECLARE_FINAL_TYPE (CbTweet, cb_tweet, CB, TWEET, GObject);

CbTweet *   cb_tweet_new (void);

gboolean    cb_tweet_is_hidden (CbTweet *tweet);

CbMedia **  cb_tweet_get_medias (CbTweet *tweet, int *n_medias);
char **     cb_tweet_get_mentions (CbTweet *tweet, int *n_mentions);
gboolean    cb_tweet_has_inline_media (CbTweet *tweet);
gint64      cb_tweet_get_user_id (CbTweet *tweet);
const char *cb_tweet_get_screen_name (CbTweet *tweet);
const char *cb_tweet_get_user_name (CbTweet *tweet);
void        cb_tweet_load_from_json (CbTweet *tweet, JsonNode *status_node, GDateTime *now);

/* Flag stuff */
gboolean    cb_tweet_is_flag_set (CbTweet *tweet, guint flag);
void        cb_tweet_set_flag (CbTweet *tweet, guint flag);
void        cb_tweet_unset_flag (CbTweet *tweet, guint flag);

char       *cb_tweet_get_formatted_text (CbTweet *tweet, guint transform_flags);
char       *cb_tweet_get_trimmed_text (CbTweet *tweet, guint transform_flags);
char       *cb_tweet_get_real_text (CbTweet *tweet);

gboolean    cb_tweet_get_seen (CbTweet *tweet);
void        cb_tweet_set_seen (CbTweet *tweet, gboolean value);

#endif


