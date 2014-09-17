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
  private static const string[] DOMAINS = {
     ".com",  ".net",  ".org",    ".xxx",  ".sexy", ".pro",
     ".biz",  ".name", ".info",   ".arpa", ".gov",  ".aero",
     ".asia", ".cat",  ".coop",   ".edu",  ".int",  ".jobs",
     ".mil",  ".mobi", ".museum", ".post", ".tel",  ".travel"
  };

  /* A 'sequence' in a text. Name sucks */
  public struct Sequence {
    int start;
    int end;
    string url;
    string display_url;
    bool visual_display_url;
    string title;
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

    foreach (Sequence s in urls) {
      int length_before = formatted_text.char_count ();
      int from = formatted_text.index_of_nth_char (s.start + char_diff);
      int to   = formatted_text.index_of_nth_char (s.end + char_diff);
      string? title = null;
      if (s.title != null) {
        title = s.title.replace ("&", "&amp;amp;");
      } else
        title = s.url.replace ("&", "&amp;");

      formatted_text = formatted_text.splice (from, to,
           "<span underline='none'><a href=\"%s\" title=\"%s\">%s</a></span>".printf(s.url,
                                                       title,
                                                       s.display_url.replace ("&", "&amp;")));
      char_diff += formatted_text.char_count () - length_before;
    }

    return formatted_text;
  } // }}}




  /**
   * Basically the same as get_formatted_text *BUT* it removes pic.twitter.com links.
   */
  string get_trimmed_text (string tweet_text, GLib.SList<Sequence?> urls, int media_count) { // {{{
    string formatted_text = tweet_text;
    int char_diff = 0;

    foreach (Sequence s in urls) {
      int length_before = formatted_text.char_count ();
      int from = formatted_text.index_of_nth_char (s.start + char_diff);
      int to   = formatted_text.index_of_nth_char (s.end + char_diff);

      if (s.display_url.has_prefix ("pic.twitter.com/") ||
          (media_count == 1 && InlineMediaDownloader.is_media_candidate (s.url))) {
        formatted_text = formatted_text.splice (from, to, "");
      } else {
        string? title = null;
        if (s.title != null) {
          title = s.title.replace ("&", "&amp;amp;");
        } else
          title = s.url.replace ("&", "&amp;");

        formatted_text = formatted_text.splice (from, to,
             "<span underline='none'><a href=\"%s\" title=\"%s\">%s</a></span>".printf(s.url,
                                                         title,
                                                         s.display_url.replace ("&", "&amp;")));
      }
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
  public string get_real_text (string tweet_text, GLib.SList<Sequence?> urls) {
    string formatted_text = tweet_text;
    int char_diff = 0;

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
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE);
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
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE);
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
  private Soup.Session avatar_session = null;
  async Gdk.Pixbuf download_avatar (string avatar_url) {
    if (avatar_session == null) {
      avatar_session = new Soup.Session ();
    }
    string avatar_name = Utils.get_avatar_name (avatar_url);
    Gdk.Pixbuf avatar = null;
    var msg     = new Soup.Message ("GET", avatar_url);
    avatar_session.queue_message (msg, (s, _msg) => {
      string dest = Dirs.cache ("assets/avatars/" + avatar_name);
      var memory_stream = new MemoryInputStream.from_data(_msg.response_body.data,
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
   * Calculates the length of a tweet.
   * See https://dev.twitter.com/docs/faq#5810 for details
   *
   * @param text The text to calculate the length for
   *
   * @return The length of the tweet, taking Twitter's rules for
   *         tweet length into account.
   */
  public int calc_tweet_length (string text, int media_count = 0) {
    string[] words = text.split (" ");
    int length = 0;

    foreach (string s in words) {
      length += get_word_length (s);
    }

    // Don't forget the n-1 whitespaces
    length += words.length - 1;

    if (length < 0) {
      return Twitter.short_url_length_https * media_count;
    }

    length += Twitter.short_url_length_https * media_count;

    return length;
  }

  private int get_word_length (string s) {
    if (s.has_prefix ("www.") || s.has_prefix ("http://"))
      return Twitter.short_url_length;

    if (s.has_prefix ("https://"))
      return Twitter.short_url_length_https;

    foreach (string tld in DOMAINS) {
      if (s.has_suffix (tld))
        return Twitter.short_url_length; // Default to HTTP
    }

    return s.char_count();
  }

  bool activate_link (string uri, MainWindow window) {
    uri = uri._strip ();
    string term = uri.substring (1);

    if (uri.has_prefix ("@")) {
      int slash_index = uri.index_of ("/");
      if (slash_index == -1) {
        window.main_widget.switch_page (Page.PROFILE,
                                         int64.parse (term));
      } else {
        window.main_widget.switch_page (Page.PROFILE,
                                        int64.parse (term.substring (0, slash_index - 1)),
                                        term.substring (slash_index + 1, term.length - slash_index - 1));
      }
      return true;
    } else if (uri.has_prefix ("#")) {
      window.main_widget.switch_page (Page.SEARCH, uri);
      return true;
    }
    return false;
  }


  struct WorkerResult {
    int64 max_id;
    int64 min_id;
  }

  async WorkerResult work_array (Json.Array json_array,
                                 DeltaUpdater delta_updater,
                                 Gtk.ListBox tweet_list,
                                 MainWindow main_window,
                                 Account account) {
    int64 max = 0;
    int64 min = int64.MAX;
    new Thread<void*> ("TweetWorker", () => {
      Tweet[] tweet_array = new Tweet[json_array.get_length ()];

      /* If the request returned no results at all, we don't
         need to do all the later stuff */
      if (tweet_array.length == 0) {
        GLib.Idle.add (() => {
          work_array.callback ();
          return false;
        });
        return null;
      }

      var now = new GLib.DateTime.now_local ();
      json_array.foreach_element ((array, index, node) => {
        Tweet t = new Tweet ();
        t.load_from_json (node, now, account);
        if (t.id > max)
          max = t.id;

        if (t.id < min)
          min = t.id;

        tweet_array[index] = t;
      });


      int index = 0;
      GLib.Idle.add (() => {
        Tweet tweet = tweet_array[index];
        var entry = new TweetListEntry (tweet, main_window, account);
        if (!account.filter_matches (entry.tweet)) {
          account.user_counter.user_seen (entry.tweet.user_id,
                                          entry.tweet.screen_name,
                                          entry.tweet.user_name);
          delta_updater.add (entry);
          tweet_list.add (entry);
        }
        index ++;
        if (index == tweet_array.length) {
          if (tweet_list is TweetListBox) {
            ((TweetListBox)tweet_list).add_progress_entry ();
          }
          work_array.callback ();
          return false;
        }
        return true;
      });
      return null;
    });
    yield;
    return {max, min};
  }


  public void handle_media_click (Tweet t, MainWindow window, int index) {
    MediaDialog media_dialog = new MediaDialog (t, index);
    media_dialog.set_transient_for (window);
    media_dialog.set_modal (true);
    media_dialog.show ();
  }



  public bool is_link (string word) {
    if (word.has_prefix ("http://") && word.length > 7)
      return true;

    if (word.has_prefix ("https://") && word.length > 8)
      return true;

    foreach (string tld in DOMAINS)
      if (word.has_suffix (tld))
          return true;


    return false;
  }

  public bool is_mention (string word) {
    return word[0] == '@' && word.length > 1;
  }

  public bool is_hashtag (string word) {
    return word[0] == '#' && word.length > 1;
  }


  private void highlight_link (Gtk.TextBuffer buffer,
                               Gtk.TextIter? word_start,
                               Gtk.TextIter? word_end) {
    Gtk.TextIter? iter1 = word_start;
    Gtk.TextIter? iter2 = word_start;
    iter1.forward_char ();
    iter2.forward_chars (2);

    while (iter1.compare (word_end) < 0) {
      string t = buffer.get_text (iter1, iter2, false);
      unichar c = t.get_char (0);

      if (c == '"' || c == '“') {
        break;
      }
      iter1.forward_char ();
      iter2.forward_char ();

    }
    buffer.apply_tag_by_name ("link", word_start, iter1);
  }

  /** Invariant: The word passed to this function starts with a @ */
  private void highlight_mention (Gtk.TextBuffer buffer,
                                  Gtk.TextIter? word_start,
                                  Gtk.TextIter? word_end) {
    Gtk.TextIter? iter1 = word_start;
    Gtk.TextIter? iter2 = word_start;
    iter1.forward_char ();
    iter2.forward_chars (2);

    while (iter1.compare (word_end) < 0) {
      string t = buffer.get_text (iter1, iter2, false);
      unichar c = t.get_char (0);

      if ((c.ispunct () && c != '_') || c == '"' || c == '“') {
        break;
      }
      iter1.forward_char ();
      iter2.forward_char ();

    }
    buffer.apply_tag_by_name ("mention", word_start, iter1);
  }


  /** Invariant: the word passed to this function starts with a # */
  private void highlight_hashtag (Gtk.TextBuffer buffer,
                                  Gtk.TextIter? word_start,
                                  Gtk.TextIter? word_end) {
    Gtk.TextIter? iter1 = word_start;
    Gtk.TextIter? iter2 = word_start;
    iter1.forward_char ();
    iter2.forward_chars (2);

    while (iter1.compare (word_end) < 0) {
      string t = buffer.get_text (iter1, iter2, false);
      unichar c = t.get_char (0);
      if ((c.ispunct () && c != '_') || c == '”') {
        break;
      }
      iter1.forward_char ();
      iter2.forward_char ();

    }
    buffer.apply_tag_by_name ("hashtag", word_start, iter1);
  }


  public void annotate_text (Gtk.TextBuffer buffer) {
    Gtk.TextIter? start_iter;
    Gtk.TextIter? cur_iter;
    Gtk.TextIter? word_start_iter;
    Gtk.TextIter? next_iter;


    buffer.get_start_iter (out start_iter);


    cur_iter = start_iter;
    word_start_iter = cur_iter;

    while (true) {
      /* If we are at a space, we just drag the start_iter with us */
      if (cur_iter.get_char ().isspace()) {
        word_start_iter = cur_iter;
        word_start_iter.forward_char ();
      }

      next_iter = cur_iter;
      bool done = !next_iter.forward_char ();

      bool word_end = done || (next_iter.get_char ().isspace() &&
                               !cur_iter.get_char ().isspace());


      if (word_end) {
        // We are at the end of a word so highlight it accordingly
        string w = buffer.get_text (word_start_iter, next_iter, false);
        if (is_link (w))
          highlight_link (buffer, word_start_iter, next_iter);
        else if (is_mention (w))
          highlight_mention (buffer, word_start_iter, next_iter);
        else if (is_hashtag (w))
          highlight_hashtag (buffer, word_start_iter, next_iter);
      }

      if (done)
        break;

      cur_iter = next_iter;
    }
  }

}
