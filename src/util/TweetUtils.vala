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
    bool visual_display_url;
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
  string get_formatted_text (string tweet_text, GLib.SList<Sequence?> urls) { // {{{
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
           "<a href=\"%s\">%s</a>".printf(s.url.replace ("&", "&amp;"),
                                        s.display_url.replace ("&", "&amp;")));
      char_diff += formatted_text.char_count () - length_before;
    }

    return formatted_text;
  } // }}}


  /**
   * Formats the given Tweet, using the given url list to insert
   * links(the real urls, protocol etc. included).
   *
   * @param tweet_text The text to format
   * @param urls The urls to insert
   *
   * @return The formatted text
   */
  string get_real_text (string tweet_text, GLib.SList<Sequence?> urls) {
    string formatted_text = tweet_text;
    int char_diff = 0;
    urls.sort ((a, b) => {
      if (a.start < b.start)
        return -1;
      return 1;
    });
    foreach (Sequence s in urls) {
      if (s.visual_display_url)
        continue;
      int length_before = formatted_text.char_count ();
      int from = formatted_text.index_of_nth_char (s.start + char_diff);
      int to   = formatted_text.index_of_nth_char (s.end + char_diff);
      formatted_text = formatted_text.splice (from, to, s.url);
      char_diff += formatted_text.char_count () - length_before;
    }

    return formatted_text;
  }

  /**
   * Deletes the given tweet.
   *
   * @param account The account to delete the tweet from
   * @param tweet the tweet to delete
   */
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


  /**
   * Replies to the given tweet. This intended for quick/easy replies, without any
   * additional data such as media.
   *
   * @param account The account to reply from
   * @param tweet The tweet to reply to
   * @param text The text to reply
   */
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


  /**
   * (Un)favorites the given tweet.
   *
   * @param account The account to (un)favorite from
   * @param tweet The tweet to (un)favorite
   * @param unfavorite If set to true, this function will unfavorite the tiven tweet,
   *                   else it will favorite it.
   */
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
        Utils.show_error_object (call.get_payload (), e.message);
      }
      tweet.favorited = !unfavorite;
      toggle_favorite_tweet.callback ();
    });
    yield;
  }

  /**
   * (Un)retweets the given tweet.
   *
   * @param account The account to (un)retweet from
   * @param tweet The tweet to (un)retweet
   * @param unretweet If set to true, this function will delete te retweet of #tweet,
   *                  else it will retweet it.
   */
  async void toggle_retweet_tweet (Account account, Tweet tweet, bool unretweet = false) {
  var call = account.proxy.new_call ();
    call.set_method ("POST");
    if (!unretweet)
      call.set_function (@"1.1/statuses/retweet/$(tweet.id).json");
    else
      call.set_function (@"1.1/statuses/destroy/$(tweet.my_retweet).json");

    call.invoke_async.begin (null, (obj, res) => {
      try{
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message);
      }
      string back = call.get_payload();
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (back);
        if (!unretweet) {
          int64 new_id = parser.get_root ().get_object ().get_int_member ("id");
          tweet.my_retweet = new_id;
        } else {
          tweet.my_retweet = 0;
        }
        tweet.retweeted = !unretweet;
      } catch (GLib.Error e) {
        critical (e.message);
        critical (back);
      }
      toggle_retweet_tweet.callback ();
    });
    yield;
  }

  /**
   * Downloads the avatar from the given url.
   *
   * @param avatar_url The avatar url to download
   *
   * @return The loaded avatar.
   */
  async Gdk.Pixbuf download_avatar (string avatar_url) {
    string avatar_name = Utils.get_avatar_name (avatar_url);
    Gdk.Pixbuf avatar = null;
    var session = new Soup.Session ();
    var msg     = new Soup.Message ("GET", avatar_url);
    session.queue_message (msg, (s, _msg) => {
      string dest = Utils.user_file ("assets/avatars/" + avatar_name);
      var memory_stream = new MemoryInputStream.from_data(
                                         _msg.response_body.data,
                                         null);
      try {
        avatar = new Gdk.Pixbuf.from_stream_at_scale (memory_stream,
                                                      48, 48,
                                                      false);
        avatar.save (dest, "png");
        download_avatar.callback ();
      } catch (GLib.Error e) {
        critical (e.message + " for " + avatar_url);
      }
      debug ("Loaded avatar %s", avatar_url);
      debug ("Dest: %s", dest);
    });
    yield;
    return avatar;
  }


  /**
   * Creates a new tweet.
   *
   * @param text The text of the tweet. Must not exceed 140 characters.
   * @param reply_id The id of the tweet this new tweet is a reply to, or -1
   *                 if this tweet it not a reply.
   * @param media_uri The image to upload alongside this tweet or "" if no image
   *                  should be uploaded.
   */
  async void send_tweet (Account account,
                         string  text,
                         int64   reply_id = -1,
                         string  media_uri = "") {
    var call = account.proxy.new_call ();
    call.set_method ("POST");
    call.add_param ("status", text);

    Rest.Param media_param;
    if (media_uri == "" || media_uri == null)
      call.set_function ("1.1/statuses/update.json");
    else {
      call.set_function ("1.1/statuses/update_with_media.json");
      uint8[] media_content;
      var media_file = GLib.File.new_for_path (media_uri);
      try {
        yield media_file.load_contents_async (null, out media_content, null);
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }
      media_param = new Rest.Param.full ("media[]", Rest.MemoryUse.COPY,
                                         media_content, "multipart/form-data",
                                         media_uri);
      call.add_param_full (media_param);
    }

    if (reply_id != -1) {
      call.add_param ("in_reply_to_status_id", reply_id.to_string ());
    }

    try {
      yield call.invoke_async (null);
    } catch (GLib.Error e) {
      Utils.show_error_object (call.get_payload (), e.message);
    }
  }


  /**
   * Calculates the length of a tweet.
   * See https://dev.twitter.com/docs/faq#5810 for details
   *
   * @param text The text to calculate the length for
   *
   * @return The length of the tweet, taking Twitter's rules for
   *         tweet length into account.
   */
  int calc_tweet_length (string text) {
    string[] words = text.split (" ");
    int length = 0;

    foreach (string s in words) {
      if (s.has_prefix ("http://") || s.has_prefix ("www."))
        length += Twitter.short_url_length;
      else if (s.has_prefix ("https://"))
        length += Twitter.short_url_length_https;
      else
        length += s.char_count ();
    }

    // Don't forget the n-1 whitespaces
    length += words.length - 1;

    return length;
  }

  bool activate_link (string uri, MainWindow window) {
    uri = uri._strip();
    string term = uri.substring(1);

    if(uri.has_prefix("@")){
      window.switch_page(MainWindow.PAGE_PROFILE,
                         int64.parse (term));
      return true;
    }else if(uri.has_prefix("#")){
      window.switch_page(MainWindow.PAGE_SEARCH, uri);
      return true;
    }
    return false;

  }
}
