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
  private Gee.ArrayList<Tweet> tweets = new Gee.ArrayList<Tweet> ();
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
    assert (index <  tweets.size);

    return tweets.get ((int)index);
  }

  public uint get_n_items () {
    return tweets.size;
  }

  private void remove_at_pos (int pos) {
    int64 id = this.tweets.get (pos).id;
    this.tweets.remove_at (pos);

    // Now we just need to update the min_id/max_id fields
    if (id == this.max_id) {
      if (this.tweets.size > 0) {
        int p = int.max (pos - 1, 0);
        this.max_id = this.tweets.get (p).id;
      } else {
        this.max_id = int64.MIN;
      }
    }

    if (id == this.min_id) {
      if (this.tweets.size > 0) {
        int p = int.min (pos + 1, this.tweets.size - 1);
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
      insert_pos = tweets.size;
    } else {
      // This case is weird(?), but just estimate the starting point
      int64 half = (max_id - min_id) / 2;
      if (tweet.id > min_id + half) {
        // we start at the beginning
        for (int i = 0, p = tweets.size; i < p; i ++) {
          if (tweets.get (i).id <= tweet.id) {
            insert_pos = i;
            break;
          }
        }
      } else {
        // we start at the end
        for (int i = tweets.size - 1; i >= 0; i --) {
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
    this.insert_sorted (tweet);

    if (tweet.id > this.max_id)
      this.max_id = tweet.id;

    if (tweet.id < this.min_id)
      this.min_id = tweet.id;
  }

  public void remove_last_n_visible (uint amount) {
    assert (amount < tweets.size);

    uint n_removed = 0;

    int size_before = tweets.size;
    int index = tweets.size - 1;
    while (index >= 0 && n_removed < amount) {
      Tweet tweet = tweets.get (index);

      if (!tweet.is_hidden)
        n_removed ++;

      this.remove_at_pos (index);
      index --;
    }
    int removed = size_before - tweets.size;
    this.items_changed (size_before - removed, removed, 0);
  }

  public void clear () {
    int s = this.tweets.size;
    this.tweets.clear ();
    this.min_id = int64.MAX;
    this.max_id = int64.MIN;
    this.items_changed (0, s, 0);
  }

  public void remove (int64 tweet_id) {
    for (int i = 0, p = tweets.size; i < p; i ++) {
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

    int pos = this.tweets.index_of (t);
    this.remove_at_pos (pos);
    this.items_changed (pos, 1, 0);
  }

  public void toggle_flag_on_tweet (int64 user_id, uint reason, bool active) {
    foreach (Tweet tweet in tweets) {
      if (tweet.user_id == user_id) {
        if (active)
          tweet.hidden_flags |= reason;
        else
          tweet.hidden_flags &= ~reason;

        tweet.hidden_flags_changed ();
      }
    }
  }

  public void toggle_flag_on_retweet (int64 user_id, uint reason, bool active) {
    foreach (Tweet tweet in tweets) {
      if (tweet.retweeted_tweet != null &&
          tweet.source_tweet.author.id == user_id) {

        if (active)
          tweet.hidden_flags |= reason;
        else
          tweet.hidden_flags &= ~reason;

        tweet.hidden_flags_changed ();
      }
    }
  }

  public bool contains_id (int64 tweet_id) {
    foreach (Tweet t in tweets)
      if (t.id == tweet_id)
        return true;

    return false;
  }

  public void remove_tweets_above (int64 id) {
    while (tweets.size > 0 &&
           tweets.get (0).id >= id) {
      this.remove_at_pos (0);
      this.items_changed (0, 1, 0);
    }
  }

  public Tweet? get_from_id (int64 id, int diff) {
    for (int i = 0; i < tweets.size; i ++) {
      if (tweets.get (i).id == id) {
        if (i + diff < tweets.size && i + diff >= 0)
          return tweets.get (i + diff);
        return null;
      }
    }
    return null;
  }

  public bool delete_id (int64 id, out bool seen) {
    for (int i = 0; i < tweets.size; i ++) {
      Tweet t = tweets.get (i);
      if (t.id == id) {
        seen = t.seen;

        if (t.is_hidden)
          this.remove_tweet (t);
        else
          t.deleted = true;


        return true;

      } else if (t.retweeted && t.my_retweet == id) {
        t.retweeted = false;
      }
    }

    seen = false;
    return false;
  }
}
