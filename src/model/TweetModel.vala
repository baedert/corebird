/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
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

public class TweetModel : GLib.Object, GLib.ListModel {
  private GLib.GenericArray<Cb.Tweet> tweets = new GLib.GenericArray<Cb.Tweet> ();
  public GLib.GenericArray<Cb.Tweet> hidden_tweets = new GLib.GenericArray<Cb.Tweet> ();
  private int64 min_id = int64.MAX;
  private int64 max_id = int64.MIN;
  public int64 lowest_id {
    get {
      return min_id;
    }
  }
  public int64 greatest_id {
    get {
      return max_id;
    }
  }

  public GLib.Type get_item_type () {
    return typeof (Cb.Tweet);
  }

  public GLib.Object? get_item (uint index) {
    assert (index >= 0);
    assert (index <  tweets.length);

    return tweets.get ((int)index);
  }

  public uint get_n_items () {
    return tweets.length;
  }

  /**
   * Removes @t from the list of tweets and adds it to the list of hidden tweets,
   * updates the min/max id fields.
   */
  private void hide_tweet_internal (Cb.Tweet t, uint pos) {
    tweets.remove (t);
    hidden_tweets.add (t);
    int64 id = t.id;

    if (id == this.max_id) {
      if (this.tweets.length > 0) {
       uint p = int.max ((int)pos - 1, 0);
        this.max_id = this.tweets.get (p).id;
      } else {
        this.max_id = int64.MIN;
      }
    }

    if (id == this.min_id) {
      if (this.tweets.length > 0) {
        uint p = uint.min (pos + 1, this.tweets.length - 1);
        this.min_id = this.tweets.get (p).id;
      } else {
        this.min_id = int64.MAX;
      }
    }
  }

  private void show_tweet_internal (Cb.Tweet t) {
    hidden_tweets.remove (t);
    this.insert_sorted (t);

    if (t.id > this.max_id)
      this.max_id = t.id;

    if (t.id < this.min_id)
      this.min_id = t.id;
  }

  /**
   * Returns true if a tweet was hidden, false otherwise.
   */
  public bool set_tweet_flag (Cb.Tweet t, Cb.TweetState flag) {
    if (t.is_hidden ()) {
#if DEBUG
      bool found = false;
      for (uint i  = 0; i < hidden_tweets.length; i ++)
        if (hidden_tweets.get (i) == t) {
          found = true;
          break;
        }

      assert (found);
#endif
      t.set_flag (flag);
    } else {
#if DEBUG
      bool found = false;
      for (uint i  = 0; i < tweets.length; i ++)
        if (tweets.get (i) == t) {
          found = true;
          break;
        }

      assert (found);
      assert (!t.is_hidden ());
#endif

      t.set_flag (flag);
      if (t.is_hidden ()) {
        for (uint i = 0; i < tweets.length; i ++) {
          if (tweets.get (i) == t) {
            hide_tweet_internal (tweets.get(i), i);
            this.items_changed (i, 1, 0);
            return true;
          }
        }
      }
    }

    return false;
  }

  public bool unset_tweet_flag (Cb.Tweet t, Cb.TweetState flag) {
    if (t.is_hidden ()) {
#if DEBUG
      bool found = false;
      for (uint i  = 0; i < hidden_tweets.length; i ++)
        if (hidden_tweets.get (i) == t) {
          found = true;
          break;
        }

      assert (found);
#endif
      t.unset_flag (flag);

      if (!t.is_hidden ()) {
        for (uint i = 0; i < hidden_tweets.length; i ++) {
          if (hidden_tweets.get (i) == t) {
            this.show_tweet_internal (hidden_tweets.get (i));
            return true;
          }
        }
      }
    } else {
#if DEBUG
      bool found = false;
      for (uint i  = 0; i < tweets.length; i ++)
        if (tweets.get (i) == t) {
          found = true;
          break;
        }

      assert (found);
      assert (!t.is_hidden ());
#endif

      t.unset_flag (flag);
    }

    return false;
  }

  private void remove_at_pos (int pos) {
    int64 id = this.tweets.get (pos).id;

    this.tweets.remove_index (pos);

    for (int i = 0; i < hidden_tweets.length; i ++) {
      Cb.Tweet tweet = hidden_tweets.get (i);
      if (tweet.id > id) {
        hidden_tweets.remove (tweet);
        i --;
      }
    }

    // Now we just need to update the min_id/max_id fields
    if (id == this.max_id) {
      if (this.tweets.length > 0) {
        int p = int.max (pos - 1, 0);
        this.max_id = this.tweets.get (p).id;
      } else {
        this.max_id = int64.MIN;
      }
    }

    if (id == this.min_id) {
      if (this.tweets.length > 0) {
        int p = int.min (pos + 1, this.tweets.length - 1);
        this.min_id = this.tweets.get (p).id;
      } else {
        this.min_id = int64.MAX;
      }
    }
  }

  private void insert_sorted (Cb.Tweet tweet) {
    /* Determine the end we start at.
       Higher IDs are at the beginning of the list */
    int insert_pos = -1;
    if (tweet.id > max_id) {
      insert_pos = 0;
    } else if (tweet.id < min_id) {
      insert_pos = tweets.length;
    } else {
      // This case is weird(?), but just estimate the starting point
      int64 half = (max_id - min_id) / 2;
      if (tweet.id > min_id + half) {
        // we start at the beginning
        for (int i = 0, p = tweets.length; i < p; i ++) {
          if (tweets.get (i).id <= tweet.id) {
            insert_pos = i;
            break;
          }
        }
      } else {
        // we start at the end
        for (int i = tweets.length - 1; i >= 0; i --) {
          if (tweets.get (i).id >= tweet.id) {
            insert_pos = i + 1;
            break;
          }
        }
      }
    }

    assert (insert_pos != -1);

    tweets.insert (insert_pos, tweet);

    this.items_changed (insert_pos, 0, 1);
  }

  public void add (Cb.Tweet tweet) {
    assert (tweet.id > 0);

    if (tweet.is_hidden ()) {
      hidden_tweets.add (tweet);
    } else {
      this.insert_sorted (tweet);

      if (tweet.id > this.max_id)
        this.max_id = tweet.id;

      if (tweet.id < this.min_id)
        this.min_id = tweet.id;
    }
  }

  public void remove_last_n_visible (uint amount) {
    assert (amount <= tweets.length);

    uint n_removed = 0;

    int size_before = tweets.length;
    int index = tweets.length - 1;
    while (index >= 0 && n_removed < amount) {
      this.remove_at_pos (index);
      index --;
      n_removed ++;
    }
    int removed = size_before - tweets.length;
    this.items_changed (size_before - removed, removed, 0);
  }

  public void clear () {
    int s = this.tweets.length;
    this.tweets.remove_range (0, tweets.length);
    this.hidden_tweets.remove_range (0, hidden_tweets.length);
    this.min_id = int64.MAX;
    this.max_id = int64.MIN;
    this.items_changed (0, s, 0);
  }

  public void remove_tweet (Cb.Tweet t) {
#if DEBUG
    if (!t.is_hidden ())
      assert (this.contains_id (t.id));
#endif

    if (t.is_hidden ()) {
      for (int i = 0; i < hidden_tweets.length; i ++) {
        Cb.Tweet tweet = hidden_tweets.get (i);
        if (t == tweet) {
          this.hidden_tweets.remove (t);
          break;
        }
      }
    } else {
      int pos = 0;
      for (int i = 0; i < tweets.length; i ++) {
        Cb.Tweet tweet = tweets.get (i);
        if (t == tweet) {
          pos = i;
          break;
        }
      }
      /* We only need to emit items-changes if the tweet was really in @tweets, not @hidden_tweets */
      this.remove_at_pos (pos);
      this.items_changed (pos, 1, 0);
      /* Remove hidden tweet(s) with an id greater than the one of the just removed tweet */
      if (tweets.length == 0) {
        hidden_tweets.remove_range (0, hidden_tweets.length);
      } else {
        for (int i = 0; i < hidden_tweets.length; i ++) {
          Cb.Tweet tweet = hidden_tweets.get (i);
          if (tweet.id > t.id) {
            hidden_tweets.remove (tweet);
            i --;
          }
        }
      }
    }
  }

  public void toggle_flag_on_tweet (int64 user_id, Cb.TweetState reason, bool active) {
    for (int i = 0; i < tweets.length; i ++) {
      Cb.Tweet tweet = tweets.get (i);
      if (tweet.get_user_id () == user_id) {
        if (active) {
          if (this.set_tweet_flag (tweet, reason))
            i --;
        } else {
          if (this.unset_tweet_flag (tweet, reason))
            i --;
        }
      }
    }

    // Do it a second time for hidden tweets
    for (int i = 0; i < hidden_tweets.length; i ++) {
      Cb.Tweet tweet = hidden_tweets.get (i);
      if (tweet.get_user_id () == user_id) {
        if (active) {
          if (this.set_tweet_flag (tweet, reason))
            i --;
        } else {
          if (this.unset_tweet_flag (tweet, reason))
            i --;
        }
      }
    }
  }

  /**
   * Hides all tweets where the given user is the RETWEETER
   */
  public void toggle_flag_on_retweet (int64 user_id, Cb.TweetState reason, bool active) {
    for (int i = 0; i < tweets.length; i ++) {
      Cb.Tweet tweet = tweets.get (i);

      if (tweet.retweeted_tweet != null &&
          tweet.source_tweet.author.id == user_id) {

        // TODO: (PERF) We iterate here to get the tweet from the user id, and in set_tweet_flag we iterate
        // again to get the position of the tweet, which we already have here...
        if (active) {
          if (this.set_tweet_flag (tweet, reason))
            i --;
        } else {
          if (this.unset_tweet_flag (tweet, reason))
            i --;
        }
      }
    }

    // Do it a second time for hidden tweets
    for (int i = 0; i < hidden_tweets.length; i ++) {
      Cb.Tweet tweet = hidden_tweets.get (i);
      if (tweet.retweeted_tweet != null &&
          tweet.source_tweet.author.id == user_id) {

        if (active) {
          if (this.set_tweet_flag (tweet, reason))
            i --;
        } else {
          if (this.unset_tweet_flag (tweet, reason))
            i --;
        }
      }
    }
  }

  public bool contains_id (int64 tweet_id) {
    for (int i = 0; i < tweets.length; i ++) {
      Cb.Tweet tweet = tweets.get (i);
      if (tweet.id == tweet_id)
        return true;
    }

    return false;
  }

  public void remove_tweets_above (int64 id) {
    while (tweets.length > 0 &&
           tweets.get (0).id >= id) {
      this.remove_at_pos (0);
      this.items_changed (0, 1, 0);
    }
  }

  public Cb.Tweet? get_from_id (int64 id, int diff = -1) {
    for (int i = 0; i < tweets.length; i ++) {
      if (tweets.get (i).id == id) {
        if (i + diff < tweets.length && i + diff >= 0)
          return tweets.get (i + diff);
        return null;
      }
    }
    return null;
  }

  public bool delete_id (int64 id, out bool seen) {
    for (int i = 0; i < tweets.length; i ++) {
      Cb.Tweet t = tweets.get (i);
      if (t.id == id) {
        seen = t.get_seen ();

        if (t.is_hidden ())
          this.remove_tweet (t);
        else
          t.set_flag (Cb.TweetState.DELETED);


        return true;

      } else if (t.is_flag_set (Cb.TweetState.RETWEETED) && t.my_retweet == id) {
        t.unset_flag (Cb.TweetState.RETWEETED);
      }
    }

    seen = false;
    return false;
  }
}
