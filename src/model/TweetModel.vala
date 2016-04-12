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
  private GLib.GenericArray<Tweet> tweets = new GLib.GenericArray<Tweet> ();
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
    return typeof (Tweet);
  }

  public GLib.Object? get_item (uint index) {
    assert (index >= 0);
    assert (index <  tweets.length);

    return tweets.get ((int)index);
  }

  public uint get_n_items () {
    return tweets.length;
  }

  private void remove_at_pos (int pos) {
    int64 id = this.tweets.get (pos).id;
    //this.tweets.remove_at (pos);
    this.tweets.remove_index (pos);

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

  private void insert_sorted (Tweet tweet) {
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

  public void add (Tweet tweet) {
    assert (tweet.id > 0);
    this.insert_sorted (tweet);

    if (tweet.id > this.max_id)
      this.max_id = tweet.id;

    if (tweet.id < this.min_id)
      this.min_id = tweet.id;
  }

  public void remove_last_n_visible (uint amount) {
    assert (amount < tweets.length);

    uint n_removed = 0;

    int size_before = tweets.length;
    int index = tweets.length - 1;
    while (index >= 0 && n_removed < amount) {
      Tweet tweet = tweets.get (index);

      if (!tweet.is_hidden)
        n_removed ++;

      this.remove_at_pos (index);
      index --;
    }
    int removed = size_before - tweets.length;
    this.items_changed (size_before - removed, removed, 0);
  }

  public void clear () {
    int s = this.tweets.length;
    this.tweets.remove_range (0, tweets.length);
    this.min_id = int64.MAX;
    this.max_id = int64.MIN;
    this.items_changed (0, s, 0);
  }

  public void remove (int64 tweet_id) {
    for (int i = 0, p = tweets.length; i < p; i ++) {
      if (tweets.get(i).id == tweet_id) {
        this.remove_at_pos (i);
        this.items_changed (i, 1, 0);
        break;
      }
    }
  }

  public void remove_tweet (Tweet t) {
#if DEBUG
  assert (this.contains_id (t.id));
#endif

    int pos = 0;
    for (int i = 0; i < tweets.length; i ++) {
      Tweet tweet = tweets.get (i);
      if (t == tweet) {
        pos = i;
        break;
      }
    }

    this.remove_at_pos (pos);
    this.items_changed (pos, 1, 0);
  }

  public void toggle_flag_on_tweet (int64 user_id, TweetState reason, bool active) {
    for (int i = 0; i < tweets.length; i ++) {
      Tweet tweet = tweets.get (i);
      if (tweet.user_id == user_id) {
        if (active)
          tweet.set_flag (reason);
        else
          tweet.unset_flag (reason);
      }
    }
  }

  public void toggle_flag_on_retweet (int64 user_id, TweetState reason, bool active) {
    for (int i = 0; i < tweets.length; i ++) {
      Tweet tweet = tweets.get (i);
      if (tweet.retweeted_tweet != null &&
          tweet.source_tweet.author.id == user_id) {

        if (active)
          tweet.set_flag (reason);
        else
          tweet.unset_flag (reason);
      }
    }
  }

  public bool contains_id (int64 tweet_id) {
    for (int i = 0; i < tweets.length; i ++) {
      Tweet tweet = tweets.get (i);
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

  public Tweet? get_from_id (int64 id, int diff = -1) {
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
      Tweet t = tweets.get (i);
      if (t.id == id) {
        seen = t.seen;

        if (t.is_hidden)
          this.remove_tweet (t);
        else
          t.set_flag (TweetState.DELETED);


        return true;

      } else if (t.is_flag_set (TweetState.RETWEETED) && t.my_retweet == id) {
        t.unset_flag (TweetState.RETWEETED);
      }
    }

    seen = false;
    return false;
  }
}
