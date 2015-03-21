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



  public GLib.Type get_item_type () {
    return typeof (Tweet);
  }

  public GLib.Object? get_item (uint index) {
    return tweets.get ((int)index);
  }

  public uint get_n_items () {
    return tweets.size;
  }


  private void insert_sorted (Tweet tweet) {
    /* Determine the end we start at.
       Higher IDs are at the beginning of the list */
    if (tweet.id > max_id) {
      tweets.insert (0, tweet);
    } else if (tweet.id < min_id) {
      tweets.insert (tweets.size, tweet); // XXX?
    } else {
      // This case is weird(?), but just estimate the starting point
      int64 half = (max_id - min_id) / 2;
      if (tweet.id > min_id + half) {
        // we start at the beginning
        for (int i = 0, p = tweets.size; i < p; i ++) {
          if (tweets.get (i).id < tweet.id) {
            tweets.insert (i, tweet);
            break;
          }
        }
      } else {
        // we start at the end
        for (int i = tweets.size; i >= 0; i --) {
          if (tweets.get (i).id < tweet.id) {
            tweets.insert (i, tweet);
            break;
          }
        }
      }
    }
  }

  public void add (Tweet tweet) {
    this.insert_sorted (tweet);

    if (tweet.id > this.max_id)
      this.max_id = tweet.id;
    else if (tweet.id < this.min_id)
      this.min_id = tweet.id;
  }
}
