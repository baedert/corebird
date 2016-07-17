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

#include "CbTweet.h"
#include "TextTransform.h"


/* TODO: We might want to put this into a utils.c later */
static gboolean
usable_json_value (JsonObject *object, const char *name)
{
  if (!json_object_has_member (object, name))
    return FALSE;

  return !json_object_get_null_member (object, name);
}

static guint
json_array_size (JsonObject *object, const char *name)
{
  if (!json_object_has_member (object, name))
    return 0;

  return (guint)json_array_get_length (json_object_get_array_member (object, name));
}



G_DEFINE_TYPE (CbTweet, cb_tweet, G_TYPE_OBJECT);

enum {
  STATE_CHANGED,
  LAST_SIGNAL
};

static guint tweet_signals[LAST_SIGNAL] = { 0 };


gboolean
cb_tweet_is_hidden (CbTweet *tweet)
{
  g_return_val_if_fail (CB_IS_TWEET (tweet), TRUE);

  return (tweet->state & (CB_TWEET_STATE_HIDDEN_FORCE |
                          CB_TWEET_STATE_HIDDEN_UNFOLLOWED |
                          CB_TWEET_STATE_HIDDEN_FILTERED |
                          CB_TWEET_STATE_HIDDEN_RTS_DISABLED |
                          CB_TWEET_STATE_HIDDEN_RT_BY_USER |
                          CB_TWEET_STATE_HIDDEN_RT_BY_FOLLOWEE |
                          CB_TWEET_STATE_HIDDEN_AUTHOR_BLOCKED |
                          CB_TWEET_STATE_HIDDEN_RETWEETER_BLOCKED |
                          CB_TWEET_STATE_HIDDEN_AUTHOR_MUTED |
                          CB_TWEET_STATE_HIDDEN_RETWEETER_MUTED)) > 0;
}

gboolean
cb_tweet_has_inline_media (CbTweet *tweet)
{
  g_return_val_if_fail (CB_IS_TWEET (tweet), FALSE);

  if (tweet->quoted_tweet != NULL)
    return tweet->quoted_tweet->n_medias > 0;
  else if (tweet->retweeted_tweet != NULL)
    return tweet->retweeted_tweet->n_medias > 0;

  return tweet->source_tweet.n_medias > 0;
}

/* TODO: Replace these 3 functinos with one that returns a pointer to a CbUserIdentity? */
gint64
cb_tweet_get_user_id (CbTweet *tweet)
{
  if (tweet->retweeted_tweet != NULL)
    return tweet->retweeted_tweet->author.id;

  return tweet->source_tweet.author.id;
}

const char *
cb_tweet_get_screen_name (CbTweet *tweet)
{
  if (tweet->retweeted_tweet != NULL)
    return tweet->retweeted_tweet->author.screen_name;

  return tweet->source_tweet.author.screen_name;
}

const char *
cb_tweet_get_user_name (CbTweet *tweet)
{
  if (tweet->retweeted_tweet != NULL)
    return tweet->retweeted_tweet->author.user_name;

  return tweet->source_tweet.author.user_name;
}

CbMedia **
cb_tweet_get_medias (CbTweet *tweet,
                     int     *n_medias)
{
  g_return_val_if_fail (CB_IS_TWEET (tweet), NULL);
  g_return_val_if_fail (n_medias != NULL, NULL);

  if (tweet->quoted_tweet != NULL)
    {
      *n_medias = tweet->quoted_tweet->n_medias;
      return tweet->quoted_tweet->medias;
    }
  else if (tweet->retweeted_tweet != NULL)
    {
      *n_medias = tweet->retweeted_tweet->n_medias;
      return tweet->retweeted_tweet->medias;
    }
  else
    {
      *n_medias = tweet->source_tweet.n_medias;
      return tweet->source_tweet.medias;
    }
}

char **
cb_tweet_get_mentions (CbTweet  *tweet,
                       int      *n_mentions)
{
  CbTextEntity *entities;
  gsize n_entities;
  gsize i, x;
  char **mentions;

  g_return_val_if_fail (CB_IS_TWEET (tweet), NULL);
  g_return_val_if_fail (n_mentions != NULL, NULL);

  if (tweet->retweeted_tweet != NULL)
    {
      entities   = tweet->retweeted_tweet->entities;
      n_entities = tweet->retweeted_tweet->n_entities;
    }
  else
    {
      entities   = tweet->source_tweet.entities;
      n_entities = tweet->source_tweet.n_entities;
    }

  *n_mentions = 0;
  for (i = 0; i < n_entities; i ++)
    if (entities[i].display_text[0] == '@')
        (*n_mentions) ++;

  if (*n_mentions == 0)
    return NULL;


  mentions = g_malloc (sizeof(char*) * (*n_mentions));

  x = 0;
  for (i = 0; i < n_entities; i ++)
    if (entities[i].display_text[0] == '@')
      {
        mentions[x] = g_strdup (entities[i].display_text);
        x ++;
      }

  return mentions;
}

void
cb_tweet_load_from_json (CbTweet   *tweet,
                         JsonNode  *status_node,
                         GDateTime *now)
{
  JsonObject *status;
  JsonObject *user;
  gboolean has_media;

  g_return_if_fail (CB_IS_TWEET (tweet));
  g_return_if_fail (status_node != NULL);
  g_return_if_fail (now != NULL);

  status = json_node_get_object (status_node);
  user = json_object_get_object_member (status, "user");

  tweet->id = json_object_get_int_member (status, "id");
  tweet->retweet_count = (guint) json_object_get_int_member (status, "retweet_count");
  tweet->favorite_count = (guint) json_object_get_int_member (status, "favorite_count");

  if (json_object_get_boolean_member (status, "favorited"))
    tweet->state |= CB_TWEET_STATE_FAVORITED;
  if (json_object_get_boolean_member (status, "retweeted"))
    tweet->state |= CB_TWEET_STATE_RETWEETED;

  if (usable_json_value (status, "possibly_sensitive") &&
      json_object_get_boolean_member (status, "possibly_sensitive"))
    tweet->state |= CB_TWEET_STATE_NSFW;

  cb_mini_tweet_parse (&tweet->source_tweet, status);
  has_media = json_array_size (json_object_get_object_member (status, "entities"), "media") > 0;

  if (json_object_has_member (status, "retweeted_status"))
    {
      JsonObject *rt      = json_object_get_object_member (status, "retweeted_status");
      JsonObject *rt_user = json_object_get_object_member (rt, "user");

      tweet->retweeted_tweet = g_malloc (sizeof(CbMiniTweet));
      cb_mini_tweet_init (tweet->retweeted_tweet);
      cb_mini_tweet_parse (tweet->retweeted_tweet, rt);
      cb_mini_tweet_parse_entities (tweet->retweeted_tweet, rt);

      tweet->avatar_url = g_strdup (json_object_get_string_member (rt_user, "profile_image_url"));
      if (json_object_get_boolean_member (rt_user, "protected"))
        tweet->state |= CB_TWEET_STATE_PROTECTED;

      if (json_object_get_boolean_member (rt_user, "verified"))
        tweet->state |= CB_TWEET_STATE_VERIFIED;

      if (!json_object_get_null_member (rt, "in_reply_to_status_id"))
        tweet->reply_id = json_object_get_int_member (rt, "in_reply_to_status_id");
    }
  else
    {
      cb_mini_tweet_parse_entities (&tweet->source_tweet, status);
      tweet->avatar_url = g_strdup (json_object_get_string_member (user, "profile_image_url"));

      if (json_object_get_boolean_member (user, "protected"))
        tweet->state |= CB_TWEET_STATE_PROTECTED;

      if (json_object_get_boolean_member (user, "verified"))
        tweet->state |= CB_TWEET_STATE_VERIFIED;

      if (!json_object_get_null_member (status, "in_reply_to_status_id"))
        tweet->reply_id = json_object_get_int_member (status, "in_reply_to_status_id");
    }

  if (json_object_has_member (status, "quoted_status") && !has_media)
    {
      JsonObject *quote = json_object_get_object_member (status, "quoted_status");
      tweet->quoted_tweet = g_malloc (sizeof (CbMiniTweet));
      cb_mini_tweet_init (tweet->quoted_tweet);
      cb_mini_tweet_parse (tweet->quoted_tweet, quote);
      cb_mini_tweet_parse_entities (tweet->quoted_tweet, quote);
    }
  else if (tweet->retweeted_tweet != NULL &&
           json_object_has_member (json_object_get_object_member (status, "retweeted_status"), "quoted_status"))
    {
      JsonObject *quote = json_object_get_object_member (json_object_get_object_member (status, "retweeted_status"),
                                                         "quoted_status");
      tweet->quoted_tweet = g_malloc (sizeof (CbMiniTweet));
      cb_mini_tweet_init (tweet->quoted_tweet);
      cb_mini_tweet_parse (tweet->quoted_tweet, quote);
      cb_mini_tweet_parse_entities (tweet->quoted_tweet, quote);
    }

  if (json_object_has_member (status, "current_user_retweet"))
    {
      JsonObject *cur_rt = json_object_get_object_member (status, "current_user_retweet");
      tweet->my_retweet = json_object_get_int_member (cur_rt, "id");
      tweet->state |= CB_TWEET_STATE_RETWEETED;
    }

#ifdef DEBUG
  {
    JsonGenerator *generator = json_generator_new ();
    json_generator_set_root (generator, status_node);
    json_generator_set_pretty (generator, TRUE);
    tweet->json_data = json_generator_to_data (generator, NULL);

    g_object_unref (generator);
  }
#endif
}

gboolean
cb_tweet_is_flag_set (CbTweet *tweet, guint flag)
{
  return (tweet->state & flag) > 0;
}

void
cb_tweet_set_flag (CbTweet *tweet, guint flag)
{
  guint prev_state;

  g_return_if_fail (CB_IS_TWEET (tweet));

  prev_state = tweet->state;

  tweet->state |= flag;

  if (tweet->state != prev_state)
    g_signal_emit (tweet, tweet_signals[STATE_CHANGED], 0);
}

void
cb_tweet_unset_flag (CbTweet *tweet, guint flag)
{
  guint prev_state;

  g_return_if_fail (CB_IS_TWEET (tweet));

  prev_state = tweet->state;

  tweet->state &= ~flag;

  if (tweet->state != prev_state)
    g_signal_emit (tweet, tweet_signals[STATE_CHANGED], 0);
}

char *
cb_tweet_get_formatted_text (CbTweet *tweet, guint transform_flags)
{
  g_return_val_if_fail (CB_IS_TWEET (tweet), NULL);

  if (tweet->retweeted_tweet != NULL)
    return cb_text_transform_tweet (tweet->retweeted_tweet, transform_flags, 0);
  else
    return cb_text_transform_tweet (&tweet->source_tweet, transform_flags, 0);
}

char *
cb_tweet_get_trimmed_text (CbTweet *tweet, guint transform_flags)
{
  gint64 quote_id;

  g_return_val_if_fail (CB_IS_TWEET (tweet), NULL);

  quote_id = tweet->quoted_tweet != NULL ? tweet->quoted_tweet->id : 0;

  if (tweet->retweeted_tweet != NULL)
    return cb_text_transform_tweet (tweet->retweeted_tweet, transform_flags, quote_id);
  else
    return cb_text_transform_tweet (&tweet->source_tweet, transform_flags, quote_id);
}

char *
cb_tweet_get_real_text (CbTweet *tweet)
{
  g_return_val_if_fail (CB_IS_TWEET (tweet), NULL);

  if (tweet->retweeted_tweet != NULL)
    return cb_text_transform_tweet (tweet->retweeted_tweet, CB_TEXT_TRANSFORM_EXPAND_LINKS, 0);
  else
    return cb_text_transform_tweet (&tweet->source_tweet, CB_TEXT_TRANSFORM_EXPAND_LINKS, 0);
}

gboolean
cb_tweet_get_seen (CbTweet *tweet)
{
  g_return_val_if_fail (CB_IS_TWEET (tweet), FALSE);

  return tweet->seen;
}

void
cb_tweet_set_seen (CbTweet *tweet, gboolean value)
{
  g_return_if_fail (CB_IS_TWEET (tweet));

  value = !!value;

  if (value && !tweet->seen && tweet->notification_id != NULL)
    {
      GApplication *app = g_application_get_default ();

      g_application_withdraw_notification (app, tweet->notification_id);
      tweet->notification_id = NULL;
    }

  tweet->seen = value;
}

CbTweet *
cb_tweet_new (void)
{
  return (CbTweet *)g_object_new (CB_TYPE_TWEET, NULL);
}

static void
cb_tweet_finalize (GObject *object)
{
  CbTweet *tweet = (CbTweet *)object;

  g_free (tweet->avatar_url);
  g_free (tweet->notification_id);
  cb_mini_tweet_free (&tweet->source_tweet);

  if (tweet->retweeted_tweet != NULL)
    {
      cb_mini_tweet_free (tweet->retweeted_tweet);
      g_free (tweet->retweeted_tweet);
    }

  if (tweet->quoted_tweet != NULL)
    {
      cb_mini_tweet_free (tweet->quoted_tweet);
      g_free (tweet->quoted_tweet);
    }

#ifdef DEBUG
  g_free (tweet->json_data);
#endif

  G_OBJECT_CLASS (cb_tweet_parent_class)->finalize (object);
}

static void
cb_tweet_init (CbTweet *tweet)
{
  tweet->state = 0;
  tweet->quoted_tweet = NULL;
  tweet->retweeted_tweet = NULL;
  tweet->reply_id = 0;
  tweet->notification_id = NULL;
  tweet->seen = TRUE;
}

static void
cb_tweet_class_init (CbTweetClass *class)
{
  GObjectClass *gobject_class = (GObjectClass *)class;

  gobject_class->finalize = cb_tweet_finalize;

  tweet_signals[STATE_CHANGED] = g_signal_new ("state-changed",
                                               G_OBJECT_CLASS_TYPE (gobject_class),
                                               G_SIGNAL_RUN_FIRST,
                                               0,
                                               NULL, NULL,
                                               NULL, G_TYPE_NONE, 0);
}
