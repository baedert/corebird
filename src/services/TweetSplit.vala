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

namespace TweetSplit {


  async void split_and_send (Account account,
                             string  text,
                             int64   reply_id = -1,
                             string  reply_screen_name = "",
                             string  media_uri = "") {

    string[] splits = text.split(" ");
    string reply_nick = null;
    if (reply_id != 0 && splits[0].has_prefix("@"))
      reply_nick = "@" + reply_screen_name + " ";

    int cur_length = 0;
    int split_pos = 0;
    int cur_split_count = 0; // #splits in the current tweet
    int num_tweets = 0;
    var cur_tweet = new StringBuilder ();

    while (split_pos < splits.length) {
      if (num_tweets > 0)
        media_uri = null;

      if (cur_length + splits[split_pos].length >= Tweet.MAX_LENGTH - 2) {
        if (cur_split_count == 0) {
          cur_tweet.append (splits[split_pos].substring(0, Tweet.MAX_LENGTH-2))
                   .append ("…");
          yield TweetUtils.send_tweet (account, cur_tweet.str, reply_id, media_uri);
          cur_tweet.erase ();
          num_tweets ++;
          splits[split_pos] = splits[split_pos].substring(Tweet.MAX_LENGTH-2);
          cur_tweet.append (reply_nick).append ("…");
        } else {
          // The tweet will be too long, so just append the ellipsis now and send it
          cur_tweet.append ("…");
          yield TweetUtils.send_tweet (account, cur_tweet.str, reply_id, media_uri);
          num_tweets ++;
          cur_tweet.erase ();
          cur_length = 0;
          cur_split_count = 0;
          cur_tweet.append (reply_nick).append ("…");
          // Leave split_pos how it is
        }
      } else {
        cur_tweet.append (splits[split_pos]).append (" ");
        cur_length += splits[split_pos].length + 1;
        split_pos ++;
        cur_split_count ++;
      }
    }
    // Send what's left
    if (cur_tweet.len > 0) {
      TweetUtils.send_tweet.begin (account, cur_tweet.str, reply_id);
    }

  }
}
