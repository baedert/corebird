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
   * @param status %true to favorite the tweet, %false to unfavorite it.
   */
  async void set_favorite_status (Account account, Tweet tweet, bool status) {
    var call = account.proxy.new_call();
    if (status)
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
      if (status)
        tweet.set_flag (TweetState.FAVORITED);
      else
        tweet.unset_flag (TweetState.FAVORITED);
      set_favorite_status.callback ();
    });
    yield;
  }

  /**
   * (Un)retweets the given tweet.
   *
   * @param account The account to (un)retweet from
   * @param tweet The tweet to (un)retweet
   * @param status %true to retweet it, false to unretweet it.
   */
  async void set_retweet_status (Account account, Tweet tweet, bool status) {
    var call = account.proxy.new_call ();
    call.set_method ("POST");
    if (status)
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
      unowned string back = call.get_payload();
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (back);
        if (status) {
          int64 new_id = parser.get_root ().get_object ().get_int_member ("id");
          tweet.my_retweet = new_id;
        } else {
          tweet.my_retweet = 0;
        }
        if (status)
          tweet.set_flag (TweetState.RETWEETED);
        else
          tweet.unset_flag (TweetState.RETWEETED);
      } catch (GLib.Error e) {
        critical (e.message);
        critical (back);
      }
      set_retweet_status.callback ();
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
  async Gdk.Pixbuf? download_avatar (string avatar_url, int size = 48) throws GLib.Error {
    Gdk.Pixbuf? avatar = null;
    var msg     = new Soup.Message ("GET", avatar_url);
    GLib.Error? err = null;
    SOUP_SESSION.queue_message (msg, (s, _msg) => {
      if (_msg.status_code != Soup.Status.OK) {
        avatar = null;
        download_avatar.callback ();
        return;
      }
      var memory_stream = new MemoryInputStream.from_data(_msg.response_body.data,
                                                          GLib.g_free);
      try {
        avatar = new Gdk.Pixbuf.from_stream_at_scale (memory_stream,
                                                      size, size,
                                                      false);
      } catch (GLib.Error e) {
        err = e;
      }
      download_avatar.callback ();
    });
    yield;
    if (err != null) {
      throw err;
    }
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
    int length = 0;

    unichar c;
    int last_word_start = 0;
    int n_chars = text.char_count ();
    int cur = 0; /* Byte Index */

    for (int next = 0, c_n = 0; text.get_next_char (ref next, out c); c_n ++) {
      bool splits = (c == ' ' || c == '\n' || c == '(' || c == ')' || c == '[' ||
                     c == ']' || c == '{' || c == '}');

      if (splits || c_n == n_chars - 1) {

        /* Include the current character only if it's not whitespace since we are
           later accounting for whitespace characters anyway */
        if (!splits && c_n == n_chars - 1)
          cur = next;

        string word = text.substring (last_word_start,
                                      cur - last_word_start);

        if (word.length > 0)
          length += get_word_length (word);

        if (splits)
          length += 1;

        // Just adding one here is save since we made sure c is either ' ' or \n
        last_word_start = cur + 1;
      }
      cur = next;
    }

    if (length < 0) {
      return Twitter.characters_reserved_per_media * media_count;
    }

    length += Twitter.characters_reserved_per_media * media_count;

    return length;
  }

  private int get_word_length (string s) {
    if (s.has_prefix ("www.") || s.has_prefix ("http://"))
      return Twitter.short_url_length;

    if (s.has_prefix ("https://"))
      return Twitter.short_url_length_https;


    string[] parts = s.split ("/");
    if (parts.length > 0) {
      foreach (string tld in DOMAINS) {
        if (parts[0].has_suffix (tld))
          return Twitter.short_url_length; // Default to HTTP
      }
    }

    return s.char_count();
  }

  bool activate_link (string uri, MainWindow window) {
    uri = uri._strip ();
    string term = uri.substring (1);

    if (uri.has_prefix ("@")) {
      int slash_index = uri.index_of ("/");
      var bundle = new Bundle ();
      if (slash_index == -1) {
        bundle.put_int64 ("user_id", int64.parse (term));
        window.main_widget.switch_page (Page.PROFILE, bundle);
      } else {
        bundle.put_int64 ("user_id", int64.parse (term.substring (0, slash_index - 1)));
        bundle.put_string ("screen_name", term.substring (slash_index + 1, term.length - slash_index - 1));
        window.main_widget.switch_page (Page.PROFILE, bundle);
      }
      return true;
    } else if (uri.has_prefix ("#")) {
      var bundle = new Bundle ();
      bundle.put_string ("query", uri);
      window.main_widget.switch_page (Page.SEARCH, bundle);
      return true;
    } else if (uri.has_prefix ("https://twitter.com/")) {
      // https://twitter.com/baedert/status/321423423423
      string[] parts = uri.split ("/");
      if (parts[4] == "status") {
        /* Treat it as a tweet link and hope it'll work out */
        int64 tweet_id = int64.parse (parts[5]);
        var bundle = new Bundle ();
        bundle.put_int ("mode", TweetInfoPage.BY_ID);
        bundle.put_int64 ("tweet_id", tweet_id);
        bundle.put_string ("screen_name", parts[3]);
        window.main_widget.switch_page (Page.TWEET_INFO,
                                        bundle);
        return true;
      }
    }
    return false;
  }


  async void work_array (Json.Array   json_array,
                         TweetListBox tweet_list,
                         MainWindow   main_window,
                         Account      account) {
    new Thread<void*> ("TweetWorker", () => {
      Tweet[] tweet_array = new Tweet[json_array.get_length ()];

      /* If the request returned no results at all, we don't
         need to do all the later stuff */
      if (tweet_array.length == 0) {
        GLib.Idle.add (() => {
          work_array.callback ();
          return GLib.Source.REMOVE;
        });
        return null;
      }

      var now = new GLib.DateTime.now_local ();
      json_array.foreach_element ((array, index, node) => {
        Tweet t = new Tweet ();
        t.load_from_json (node, now, account);

        tweet_array[index] = t;
      });


      int index = 0;
      GLib.Idle.add (() => {
        Tweet tweet = tweet_array[index];
        if (account.user_counter == null ||
            tweet_list == null)
          return GLib.Source.REMOVE;

        account.user_counter.id_seen (ref tweet.source_tweet.author);
        if (tweet.retweeted_tweet != null)
          account.user_counter.id_seen (ref tweet.retweeted_tweet.author);

        if (account.filter_matches (tweet))
          tweet.set_flag (TweetState.HIDDEN_FILTERED);

        tweet_list.model.add (tweet);

        index ++;
        if (index == tweet_array.length) {
          work_array.callback ();
          return GLib.Source.REMOVE;
        }
        return GLib.Source.CONTINUE;
      });
      return null;
    });
    yield;
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

    foreach (unowned string tld in DOMAINS)
      if (word.has_suffix (tld))
          return true;


    return false;
  }

  private const unichar[] non_mention_chars = {
    '“', '"', '-', '`', ',', '.', '^', '(', ')', '[', ']', '{', '}', '+', '='
  };
  public bool is_mention (string  word,
                          out int at_pos) {
    int k = 0;
    while (word.get_char (k) in non_mention_chars)
      k ++;

    at_pos = k;

    return word.get_char (word.index_of_nth_char (k)) == '@' &&
           word.length > 1 &&
           word.length - k > 1;
  }

  public bool is_hashtag (string word) {
    return word[0] == '#' && word.length > 1;
  }


  private void highlight_link (Gtk.TextBuffer buffer,
                               Gtk.TextIter?  word_start,
                               Gtk.TextIter?  word_end) {
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
                                  Gtk.TextIter?  word_start,
                                  Gtk.TextIter?  word_end) {
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
                                  Gtk.TextIter?  word_start,
                                  Gtk.TextIter?  word_end) {
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
        int k;
        string w = buffer.get_text (word_start_iter, next_iter, false);
        if (is_link (w)) {
          highlight_link (buffer, word_start_iter, next_iter);
        } else if (is_mention (w, out k)) {
          word_start_iter.forward_chars (k);
          highlight_mention (buffer, word_start_iter, next_iter);
        } else if (is_hashtag (w)) {
          highlight_hashtag (buffer, word_start_iter, next_iter);
        }
      }

      if (done)
        break;

      cur_iter = next_iter;
    }
  }

  public async Json.Node? load_threaded (Rest.ProxyCall    call,
                                         GLib.Cancellable? cancellable) throws GLib.Error
  {
    Json.Node? result = null;
    GLib.Error? err   = null;
    GLib.SourceFunc callback = load_threaded.callback;

    new Thread<void*> ("json parser", () => {
      try {
        call.sync ();
      } catch (GLib.Error e) {
        err = e;
        GLib.Idle.add (() => { callback (); return GLib.Source.REMOVE; });
        return null;
      }

      if (cancellable != null && cancellable.is_cancelled ()) {
        GLib.Idle.add (() => { callback (); return GLib.Source.REMOVE; });
        return null;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        err = e;
        GLib.Idle.add (() => { callback (); return GLib.Source.REMOVE; });
        return null;
      }

      if (cancellable != null && cancellable.is_cancelled ()) {
        GLib.Idle.add (() => { callback (); return GLib.Source.REMOVE; });
        return null;
      }

      result = parser.get_root ();
      GLib.Idle.add (() => { callback (); return GLib.Source.REMOVE; });
      return null;
    });
    yield;

    if (err != null)
      throw err;

    return result;
  }

  public void sort_entities (ref TextEntity[] entities) {
    /* Just use bubblesort here. Our n is very small (< 15 maybe?) */

    for (int i = 0; i < entities.length; i ++) {
      for (int k = 0; k < entities.length; k ++) {
        if (entities[i].from < entities[k].from) {
          TextEntity c = entities[i];
          entities[i] = entities[k];
          entities[k] = c;
        }
      }
    }
  }
}
