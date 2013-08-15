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





namespace TweetUtils {
  /* A 'sequence' in a text. Name sucks */
  struct Sequence {
    int start;
    int end;
    string url;
    string display_url;
  }

  /**
   * Formats the given Tweet, using the given url list to insert
   * links(i.e. <a> tags).
   *
   * @param tweet_text The text to format
   * @param urls The urls to insert
   *
   * @return The formatted text
   */
  string get_formatted_text (string tweet_text, GLib.SList<Sequence?> urls) {
    string formatted_text = tweet_text;
    int char_diff = 0;
    urls.sort ((a, b) => {
      if (a.start < b.start)
        return -1;
      return 1;
    });
    foreach (Sequence s in urls) {
      int length_before = formatted_text.char_count ();
      int from = formatted_text.index_of_nth_char (s.start + char_diff);
      int to   = formatted_text.index_of_nth_char (s.end + char_diff);
      formatted_text = formatted_text.splice (from, to,
           "<a href='%s'>%s</a>".printf(s.url, s.display_url));
      char_diff += formatted_text.char_count () - length_before;
    }

    return formatted_text;
  }


  async void delete_tweet (Account account, Tweet tweet) {
    var call = account.proxy.new_call ();
    call.set_method ("POST");
    call.set_function ("1.1/statuses/destroy/"+tweet.id.to_string ()+".json");
    call.add_param ("id", tweet.id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try { call.invoke_async.end (res);} catch (GLib.Error e) { critical (e.message);}
      delete_tweet.callback ();
    });
    yield;
  }

  async void reply_to_tweet (Account account, Tweet tweet, string text) {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/statuses/update.json");
    call.set_method ("POST");
    call.add_param ("in_reply_to_status_id", tweet.id.to_string ());
    call.add_param ("status", text);
    call.invoke_async.begin (null, () => {
      reply_to_tweet.callback ();
    });
    yield;
  }

  async void toggle_favorite_tweet (Account account, Tweet tweet, bool unfavorite = false) {
    var call = account.proxy.new_call();
    if (!unfavorite)
      call.set_function ("1.1/favorites/create.json");
    else
      call.set_function ("1.1/favorites/destroy.json");

    call.set_method ("POST");
    call.add_param ("id", tweet.id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        critical(e.message);
      }
      toggle_favorite_tweet.callback ();
    });
    yield;
  }

  async void toggle_retweet_tweet (Account account, Tweet tweet, bool unretweet = false) {
  var call = account.proxy.new_call ();
    call.set_method ("POST");
    if (!unretweet)
      call.set_function (@"1.1/statuses/retweet/$(tweet.id).json");
    else
      call.set_function (@"1.1/statuses/destroy/$(tweet.rt_id).json");

    call.invoke_async.begin (null, (obj, res) => {
      try{
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_dialog (e.message);
      }
      string back = call.get_payload();
      stdout.printf (back+"\n");
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (back);
        if (!unretweet) {
          int64 new_id = parser.get_root ().get_object ().get_int_member ("id");
          message (new_id.to_string ());
          tweet.rt_id = new_id;
        } else {
          tweet.rt_id = 0;
        }
      } catch (GLib.Error e) {
        critical (e.message);
        critical (back);
      }
      toggle_retweet_tweet.callback ();
    });
    yield;
  }
}
