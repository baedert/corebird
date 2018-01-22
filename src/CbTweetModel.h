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

#ifndef CB_TWEET_MODEL_H
#define CB_TWEET_MODEL_H

#include <glib-object.h>
#include <gio/gio.h>

#include "CbTweet.h"


typedef struct _CbTweetModel      CbTweetModel;
typedef struct _CbTweetModelClass CbTweetModelClass;

#define CB_TYPE_TWEET_MODEL           (cb_tweet_model_get_type ())
#define CB_TWEET_MODEL(obj)           (G_TYPE_CHECK_INSTANCE_CAST(obj, CB_TYPE_TWEET_MODEL, CbTweetModel))
#define CB_TWEET_MODEL_CLASS(cls)     (G_TYPE_CHECK_CLASS_CAST(cls, CB_TYPE_TWEET_MODEL, CbTweetModelClass))
#define CB_IS_TWEET_MODEL(obj)        (G_TYPE_CHECK_INSTANCE_TYPE(obj, CB_TYPE_TWEET_MODEL))
#define CB_IS_TWEET_MODEL_CLASS(cls)   (G_TYPE_CHECK_CLASS_TYPE(cls, CB_TYPE_TWEET_MODEL))
#define CB_TWEET_MODEL_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS(obj, CB_TYPE_TWEET_MODEL, CbTweetModelClass))

struct _CbTweetModel
{
  GObject parent_instance;

  GPtrArray *tweets;
  GPtrArray *hidden_tweets;
  gint64 min_id;
  gint64 max_id;
};

struct _CbTweetModelClass
{
  GObjectClass parent_class;
};

GType          cb_tweet_model_get_type                     (void) G_GNUC_CONST;
CbTweetModel * cb_tweet_model_new                          (void);
gboolean       cb_tweet_model_contains_id                  (CbTweetModel *self,
                                                            gint64        id);
gboolean       cb_tweet_model_contains_rt_id               (CbTweetModel *self,
                                                            gint64        rt_id);
void           cb_tweet_model_clear                        (CbTweetModel *self);
CbTweet *      cb_tweet_model_get_for_id                   (CbTweetModel *self,
                                                            gint64        id,
                                                            int           diff);
gboolean       cb_tweet_model_delete_id                    (CbTweetModel *self,
                                                            gint64        id,
                                                            gboolean     *seen);
void           cb_tweet_model_remove_tweet                 (CbTweetModel *self,
                                                            CbTweet      *tweet);
void           cb_tweet_model_toggle_flag_on_user_tweets   (CbTweetModel *self,
                                                            gint64        user_id,
                                                            CbTweetState  flag,
                                                            gboolean      active);
void           cb_tweet_model_toggle_flag_on_user_retweets (CbTweetModel *self,
                                                            gint64        user_id,
                                                            CbTweetState  flag,
                                                            gboolean      active);
gboolean       cb_tweet_model_set_tweet_flag               (CbTweetModel *self,
                                                            CbTweet      *tweet,
                                                            CbTweetState  flag);
gboolean       cb_tweet_model_unset_tweet_flag             (CbTweetModel *self,
                                                            CbTweet      *tweet,
                                                            CbTweetState  flag);
void           cb_tweet_model_add                          (CbTweetModel *self,
                                                            CbTweet      *tweet);
void           cb_tweet_model_remove_last_n_visible        (CbTweetModel *self,
                                                            guint         amount);
void           cb_tweet_model_remove_tweets_above          (CbTweetModel *self,
                                                            gint64        id);


#endif
