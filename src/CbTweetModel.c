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

#include "CbTweetModel.h"

static void cb_tweet_model_iface_init (GListModelInterface *iface);

G_DEFINE_TYPE_WITH_CODE (CbTweetModel, cb_tweet_model, G_TYPE_OBJECT,
                         G_IMPLEMENT_INTERFACE (G_TYPE_LIST_MODEL, cb_tweet_model_iface_init));

static GType
cb_tweet_model_get_item_type (GListModel *model)
{
  return CB_TYPE_TWEET;
}

static guint
cb_tweet_model_get_n_items (GListModel *model)
{
  CbTweetModel *self = CB_TWEET_MODEL (model);

  return self->tweets->len;
}

static gpointer
cb_tweet_model_get_item (GListModel *model,
                         guint       index)
{
  CbTweetModel *self = CB_TWEET_MODEL (model);
  CbTweet *tweet;

  g_assert (index < self->tweets->len);

  tweet = g_ptr_array_index (self->tweets, index);

  return g_object_ref (tweet);
}

static void
cb_tweet_model_iface_init (GListModelInterface *iface)
{
  iface->get_item_type = cb_tweet_model_get_item_type;
  iface->get_n_items = cb_tweet_model_get_n_items;
  iface->get_item = cb_tweet_model_get_item;
}

static inline void
emit_items_changed (CbTweetModel *self,
                    guint         position,
                    guint         removed,
                    guint         added)
{
  g_list_model_items_changed (G_LIST_MODEL (self), position, removed, added);
}

static void
cb_tweet_model_init (CbTweetModel *self)
{
  self->tweets = g_ptr_array_new_with_free_func (g_object_unref);
  self->hidden_tweets = g_ptr_array_new_with_free_func (g_object_unref);
  self->min_id = G_MAXINT64;
  self->max_id = G_MININT64;
}

static void
cb_tweet_model_finalize (GObject *object)
{
  CbTweetModel *self = CB_TWEET_MODEL (object);

  g_ptr_array_unref (self->tweets);
  g_ptr_array_unref (self->hidden_tweets);

  G_OBJECT_CLASS (cb_tweet_model_parent_class)->finalize (object);
}

static void
cb_tweet_model_class_init (CbTweetModelClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_tweet_model_finalize;
}

CbTweetModel *
cb_tweet_model_new (void)
{
  return CB_TWEET_MODEL (g_object_new (CB_TYPE_TWEET_MODEL, NULL));
}

static inline void
update_min_max_id (CbTweetModel *self,
                   gint64        old_id)
{
  guint i;

#ifdef DEBUG
  /* This should be called *after* the
   * tweet has been removed from self->tweets! */
  for (i = 0; i < self->tweets->len; i ++)
    {
      CbTweet *t = g_ptr_array_index (self->tweets, i);

      g_assert (t->id != old_id);
    }
#endif

  if (old_id == self->max_id)
    {
      if (self->tweets->len > 0)
        {
          CbTweet *t = g_ptr_array_index (self->tweets, 0);

          self->max_id = t->id;

          /* We just removed the tweet with the max_id, so now remove all
           * hidden tweets that have a id greater than the now max id! */
          for (i = 0; i < self->hidden_tweets->len; i ++)
            {
              CbTweet *t = g_ptr_array_index (self->hidden_tweets, i);

              if (t->id > self->max_id)
                {
                  g_ptr_array_remove_index (self->hidden_tweets, i);
                  i --;
                }
            }
        }
      else
        {
          self->max_id = G_MININT64;
          g_ptr_array_remove_range (self->hidden_tweets, 0, self->hidden_tweets->len);
        }
    }

  if (old_id == self->min_id)
    {
      if (self->tweets->len > 0)
        {
          CbTweet *t = g_ptr_array_index (self->tweets, self->tweets->len - 1);

          self->min_id = t->id;
          /* We just removed the tweet with the min_id, so now remove all hidden tweets
           * with an id lower than the new min_id */
          for (i = 0; i < self->hidden_tweets->len; i ++)
            {
              CbTweet *t = g_ptr_array_index (self->hidden_tweets, i);

              if (t->id < self->min_id)
                {
                  g_ptr_array_remove_index (self->hidden_tweets, i);
                  i --;
                }
            }
        }
      else
        {
          self->min_id = G_MAXINT64;
          g_ptr_array_remove_range (self->hidden_tweets, 0, self->hidden_tweets->len);
        }
    }
}

static void
remove_tweet_at_pos (CbTweetModel *self,
                     guint         index)
{
  CbTweet *tweet = g_ptr_array_index (self->tweets, index);
  gint64 id = tweet->id;

  g_assert (index < self->tweets->len);

  g_ptr_array_remove_index (self->tweets, index);
  tweet = NULL; /* We just unreffed it, so potentially freed */

  /* TODO: If this tweet was the one with id == min_id or id == max_id,
   *       we should remove tweets from self->hidden_tweets with id
   *       greater or lower than its id. 
   */

  update_min_max_id (self, id);
  emit_items_changed (self, index, 1, 0);
}

static inline void
insert_sorted (CbTweetModel *self,
               CbTweet      *tweet)
{
  int insert_pos = -1;

  if (tweet->id > self->max_id)
    {
      insert_pos = 0;
    }
  else if (tweet->id < self->min_id)
    {
      insert_pos = self->tweets->len;
    }
  else
    {
      /* This case should be relatively rare in real life since
       * we only ever add tweets at the top or bottom of a list */
      guint i;

      for (i = 0; i < self->tweets->len - 1; i ++)
        {
          CbTweet *cur = g_ptr_array_index (self->tweets, i);
          CbTweet *next = g_ptr_array_index (self->tweets, i + 1);

          if (cur->id >= tweet->id && next->id <= tweet->id)
            {
              insert_pos = i + 1;
              break;
            }
        }
    }

  if (insert_pos == -1)
    {
      /* This can happen if the same tweet gets inserted into an empty model twice.
       * Generally, we'd like to ignore double insertions, at least right now I can't
       * think of a good use case for it. (2017-06-13) */
      return;
    }

  g_object_ref (tweet);
  g_ptr_array_insert (self->tweets, insert_pos, tweet);

  emit_items_changed (self, insert_pos, 0, 1);
}

static void
hide_tweet_internal (CbTweetModel *self,
                     guint         index)
{
  CbTweet *tweet = g_ptr_array_index (self->tweets, index);
  gint64 id = tweet->id;

  g_object_ref (tweet);
  g_ptr_array_remove_index (self->tweets, index);
  g_object_ref (tweet); /* Have to ref manually */
  g_ptr_array_add (self->hidden_tweets, tweet);
  g_object_unref (tweet);

  update_min_max_id (self, id);
}

static void
show_tweet_internal (CbTweetModel *self,
                     guint         index)
{
  CbTweet *tweet = g_ptr_array_index (self->hidden_tweets, index);

  g_object_ref (tweet);
  g_ptr_array_remove_index (self->hidden_tweets, index);
  insert_sorted (self, tweet);
  g_object_unref (tweet);

  if (tweet->id > self->max_id)
    self->max_id = tweet->id;

  if (tweet->id < self->min_id)
    self->min_id = tweet->id;
}

gboolean
cb_tweet_model_contains_id (CbTweetModel *self,
                            gint64        id)
{
  guint i;

  g_return_val_if_fail (CB_IS_TWEET_MODEL (self), FALSE);

  for (i = 0; i < self->tweets->len; i ++)
    {
      CbTweet *tweet = g_ptr_array_index (self->tweets, i);

      if (tweet->id == id)
        return TRUE;
    }

  return FALSE;
}

gboolean
cb_tweet_model_contains_rt_id (CbTweetModel *self,
                               gint64        id)
{
  guint i;

  g_return_val_if_fail (CB_IS_TWEET_MODEL (self), FALSE);

  for (i = 0; i < self->tweets->len; i ++)
    {
      CbTweet *tweet = g_ptr_array_index (self->tweets, i);

      if (tweet->retweeted_tweet != NULL &&
          tweet->retweeted_tweet->id == id)
        return TRUE;
    }

  return FALSE;
}



void
cb_tweet_model_clear (CbTweetModel *self)
{
  int l;
  g_return_if_fail (CB_IS_TWEET_MODEL (self));

  l = self->tweets->len;
  g_ptr_array_remove_range (self->tweets, 0, l);
  g_ptr_array_remove_range (self->hidden_tweets, 0, self->hidden_tweets->len);

  self->min_id = G_MAXINT64;
  self->max_id = G_MININT64;

  emit_items_changed (self, 0, l, 0);
}

CbTweet *
cb_tweet_model_get_for_id (CbTweetModel *self,
                           gint64        id,
                           int           diff)
{
  int i;
  g_return_val_if_fail (CB_IS_TWEET_MODEL (self), NULL);

  for (i = 0; i < (int)self->tweets->len; i ++)
    {
      CbTweet *tweet = g_ptr_array_index (self->tweets, i);

      if (tweet->id == id)
        {
          if (i + diff < (int)self->tweets->len && i + diff >= 0)
            return g_ptr_array_index (self->tweets, i + diff);

          return NULL;
        }
    }

  return NULL;
}

gboolean
cb_tweet_model_delete_id (CbTweetModel *self,
                          gint64        id,
                          gboolean     *seen)
{
  guint i;

  g_return_val_if_fail (CB_IS_TWEET_MODEL (self), FALSE);

  for (i = 0; i < self->tweets->len; i ++)
    {
      CbTweet *tweet = g_ptr_array_index (self->tweets, i);

      if (tweet->id == id)
        {
          *seen = tweet->seen;

          g_assert (!cb_tweet_is_hidden (tweet));

          cb_tweet_set_flag (tweet, CB_TWEET_STATE_DELETED);

          return TRUE;
        }
      else if (cb_tweet_is_flag_set (tweet, CB_TWEET_STATE_RETWEETED) &&
               tweet->my_retweet == id)
        {
          cb_tweet_unset_flag (tweet, CB_TWEET_STATE_RETWEETED);
        }
    }

  *seen = FALSE;
  return FALSE;
}

void
cb_tweet_model_remove_tweet (CbTweetModel *self,
                             CbTweet      *tweet)
{
  guint i;

  g_return_if_fail (CB_IS_TWEET_MODEL (self));
  g_return_if_fail (CB_IS_TWEET (tweet));

#ifdef DEBUG
  if (!cb_tweet_is_hidden (tweet))
    g_assert (cb_tweet_model_contains_id (self, tweet->id));
#endif

  if (cb_tweet_is_hidden (tweet))
    {
      for (i = 0; i < self->hidden_tweets->len; i ++)
        {
          CbTweet *t = g_ptr_array_index (self->hidden_tweets, i);
          if (t == tweet)
            {
              g_ptr_array_remove_index (self->hidden_tweets, i);
              break;
            }
        }
    }
  else
    {
      int pos = -1;

      for (i = 0; i < self->tweets->len; i ++)
        {
          CbTweet *t = g_ptr_array_index (self->tweets, i);

          if (t == tweet)
            {
              pos = i;
              break;
            }
        }

      g_assert (pos != -1);

      remove_tweet_at_pos (self, pos);
    }
}

void
cb_tweet_model_toggle_flag_on_user_tweets (CbTweetModel *self,
                                           gint64        user_id,
                                           CbTweetState  flag,
                                           gboolean      active)
{
  guint i;

  g_return_if_fail (CB_IS_TWEET_MODEL (self));

  for (i = 0; i < self->tweets->len; i ++)
    {
      CbTweet *t = g_ptr_array_index (self->tweets, i);

      if (cb_tweet_get_user_id (t) == user_id)
        {
          if (active)
            {
              if (cb_tweet_model_set_tweet_flag (self, t, flag))
                i --;
            }
          else
            {
              if (cb_tweet_model_unset_tweet_flag (self, t, flag))
                i --;
            }
        }
    }

  /* Aaaand now the same thing for hidden tweets */
  for (i = 0; i < self->hidden_tweets->len; i ++)
    {
      CbTweet *t = g_ptr_array_index (self->hidden_tweets, i);

      if (cb_tweet_get_user_id (t) == user_id)
        {
          if (active)
            {
              if (cb_tweet_model_set_tweet_flag (self, t, flag))
                i --;
            }
          else
            {
              if (cb_tweet_model_unset_tweet_flag (self, t, flag))
                i --;
            }
        }
    }
}

void
cb_tweet_model_toggle_flag_on_user_retweets (CbTweetModel *self,
                                             gint64        user_id,
                                             CbTweetState  flag,
                                             gboolean      active)
{
  guint i;

  g_return_if_fail (CB_IS_TWEET_MODEL (self));

  for (i = 0; i < self->tweets->len; i ++)
    {
      CbTweet *t = g_ptr_array_index (self->tweets, i);

      if (t->retweeted_tweet != NULL &&
          t->source_tweet.author.id == user_id)
        {
          if (active)
            {
              if (cb_tweet_model_set_tweet_flag (self, t, flag))
                i --;
            }
          else
            {
              if (cb_tweet_model_unset_tweet_flag (self, t, flag))
                i --;
            }
        }
    }

  /* Aaaand now the same thing for hidden tweets */
  for (i = 0; i < self->hidden_tweets->len; i ++)
    {
      CbTweet *t = g_ptr_array_index (self->hidden_tweets, i);

      if (t->retweeted_tweet != NULL &&
          t->source_tweet.author.id == user_id)
        {
          if (active)
            {
              if (cb_tweet_model_set_tweet_flag (self, t, flag))
                i --;
            }
          else
            {
              if (cb_tweet_model_unset_tweet_flag (self, t, flag))
                i --;
            }
        }
    }
}

gboolean
cb_tweet_model_set_tweet_flag (CbTweetModel *self,
                               CbTweet      *tweet,
                               CbTweetState  flag)
{
  guint i;

  if (cb_tweet_is_hidden (tweet))
    {
#ifdef DEBUG
      gboolean found = FALSE;
      /* Should be in hidden_tweets now, hu? */
      for (i = 0; self->hidden_tweets->len; i ++)
        {
          CbTweet *t = g_ptr_array_index (self->hidden_tweets, i);

          if (t == tweet)
            {
              found = TRUE;
              break;
            }
        }

      g_assert (found);
#endif

      cb_tweet_set_flag (tweet, flag);
    }
  else
    {
#ifdef DEBUG
      /* Now it should be is self->tweets */
      gboolean found = FALSE;
      /* Should be in hidden_tweets now, hu? */
      for (i = 0; self->tweets->len; i ++)
        {
          CbTweet *t = g_ptr_array_index (self->tweets, i);

          if (t == tweet)
            {
              found = TRUE;
              break;
            }
        }

      g_assert (found);
#endif

      cb_tweet_set_flag (tweet, flag);
      if (cb_tweet_is_hidden (tweet))
        {
          /* Could be hidden now. */
          for (i = 0; i < self->tweets->len; i ++)
            {
              CbTweet *t = g_ptr_array_index (self->tweets, i);

              if (t == tweet)
                {
                  hide_tweet_internal (self, i);
                  emit_items_changed (self, i, 1, 0);
                  break;
                }
            }

          return TRUE;
        }
    }

  return FALSE;
}

gboolean
cb_tweet_model_unset_tweet_flag (CbTweetModel *self,
                                 CbTweet      *tweet,
                                 CbTweetState  flag)
{
  guint i;

  if (cb_tweet_is_hidden (tweet))
    {
#ifdef DEBUG
      gboolean found = FALSE;
      /* Should be in hidden_tweets now, hu? */
      for (i = 0; self->hidden_tweets->len; i ++)
        {
          CbTweet *t = g_ptr_array_index (self->hidden_tweets, i);

          if (t == tweet)
            {
              found = TRUE;
              break;
            }
        }

      g_assert (found);
#endif

      cb_tweet_unset_flag (tweet, flag);
      if (!cb_tweet_is_hidden (tweet))
        {
          /* Tweet not hidden anymore. Move to self->tweets
           * and emit items-changed. */
          for (i = 0; i < self->hidden_tweets->len; i ++)
            {
              CbTweet *t = g_ptr_array_index (self->hidden_tweets, i);
              if (t == tweet)
                {
                  show_tweet_internal (self, i);
                  return TRUE;
                }
            }
        }
    }
  else
    {
#ifdef DEBUG
      /* Now it should be is self->tweets */
      gboolean found = FALSE;
      /* Should be in hidden_tweets now, hu? */
      for (i = 0; self->tweets->len; i ++)
        {
          CbTweet *t = g_ptr_array_index (self->tweets, i);

          if (t == tweet)
            {
              found = TRUE;
              break;
            }
        }

      g_assert (found);
#endif

      cb_tweet_unset_flag (tweet, flag);
    }

  return FALSE;
}

void
cb_tweet_model_add (CbTweetModel *self,
                    CbTweet      *tweet)
{

  g_return_if_fail (CB_IS_TWEET_MODEL (self));
  g_return_if_fail (CB_IS_TWEET (tweet));

  if (cb_tweet_is_hidden (tweet))
    {
      g_object_ref (tweet);
      g_ptr_array_add (self->hidden_tweets, tweet);
    }
  else
    {
      insert_sorted (self, tweet);

      if (tweet->id > self->max_id)
        self->max_id = tweet->id;

      if (tweet->id < self->min_id)
        self->min_id = tweet->id;
    }
}

void
cb_tweet_model_remove_last_n_visible (CbTweetModel *self,
                                     guint          amount)
{
  int size_before;

  g_return_if_fail (CB_IS_TWEET_MODEL (self));

  g_assert (amount <= self->tweets->len);

  size_before = self->tweets->len;

  g_ptr_array_remove_range (self->tweets,
                            size_before - amount,
                            amount);
  update_min_max_id (self, self->min_id);
  emit_items_changed (self, size_before - amount, amount, 0);
}

void
cb_tweet_model_remove_tweets_above (CbTweetModel *self,
                                    gint64        id)
{
  g_return_if_fail (CB_IS_TWEET_MODEL (self));

  while (self->tweets->len > 0)
    {
      CbTweet *first = g_ptr_array_index (self->tweets, 0);

      if (first->id < id)
        break;

      remove_tweet_at_pos (self, 0);
    }
}
