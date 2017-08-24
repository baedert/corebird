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
  private const string[] DOMAINS = {
     ".com",  ".net",  ".org",    ".xxx",  ".sexy", ".pro",
     ".biz",  ".name", ".info",   ".arpa", ".gov",  ".aero",
     ".asia", ".cat",  ".coop",   ".edu",  ".int",  ".jobs",
     ".mil",  ".mobi", ".museum", ".post", ".tel",  ".travel"
  };
  public const string NO_SPELL_CHECK = "gtksourceview:context-classes:no-spell-check";

  /**
   * Deletes the given tweet.
   *
   * @param account The account to delete the tweet from
   * @param tweet the tweet to delete
   */
  async void delete_tweet (Account account, Cb.Tweet tweet) {
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
   * (Un)favorites the given tweet.
   *
   * @param account The account to (un)favorite from
   * @param tweet The tweet to (un)favorite
   * @param status %true to favorite the tweet, %false to unfavorite it.
   */
  async void set_favorite_status (Account account, Cb.Tweet tweet, bool status) {
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
        tweet.set_flag (Cb.TweetState.FAVORITED);
      else
        tweet.unset_flag (Cb.TweetState.FAVORITED);

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
  async void set_retweet_status (Account account, Cb.Tweet tweet, bool status) {
    var call = account.proxy.new_call ();
    call.set_method ("POST");
    if (status)
      call.set_function (@"1.1/statuses/retweet/$(tweet.id).json");
    else
      call.set_function (@"1.1/statuses/destroy/$(tweet.my_retweet).json");

    debug (Cb.Utils.rest_proxy_call_to_string (call));
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
          tweet.set_flag (Cb.TweetState.RETWEETED);
        else
          tweet.unset_flag (Cb.TweetState.RETWEETED);
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
  async Gdk.Pixbuf? download_avatar (string avatar_url, int size = 48,
                                     GLib.Cancellable? cancellable = null) throws GLib.Error {
    Gdk.Pixbuf? avatar = null;
    var msg     = new Soup.Message ("GET", avatar_url);
    if (cancellable != null)
      cancellable.cancelled.connect (() => { SOUP_SESSION.cancel_message (msg, Soup.Status.CANCELLED); });

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

    return length;
  }

  private int get_word_length (string s) {
    if (s.has_prefix ("www.")    ||
        s.has_prefix ("http://") ||
        s.has_prefix ("https://"))
      return Twitter.short_url_length;

    string[] parts = s.split ("/");
    if (parts.length > 0) {
      foreach (unowned string tld in DOMAINS) {
        if (parts[0].has_suffix (tld))
          return Twitter.short_url_length; // Default to HTTP
      }
    }

    return s.char_count();
  }

  bool activate_link (string uri, MainWindow window) {
    debug ("Activating '%s'", uri);
    uri = uri._strip ();
    string term = uri.substring (1);

    if (uri.has_prefix ("@")) {
      int slash_index = uri.index_of ("/");
      var bundle = new Cb.Bundle ();
      if (slash_index == -1) {
        bundle.put_int64 (ProfilePage.KEY_USER_ID, int64.parse (term));
        window.main_widget.switch_page (Page.PROFILE, bundle);
      } else {
        bundle.put_int64 (ProfilePage.KEY_USER_ID, int64.parse (term.substring (0, slash_index - 1)));
        bundle.put_string (ProfilePage.KEY_SCREEN_NAME,
                           term.substring (slash_index + 1, term.length - slash_index - 1));
        window.main_widget.switch_page (Page.PROFILE, bundle);
      }
      return true;
    } else if (uri.has_prefix ("#")) {
      var bundle = new Cb.Bundle ();
      bundle.put_string (SearchPage.KEY_QUERY, uri);
      window.main_widget.switch_page (Page.SEARCH, bundle);
      return true;
    } else if (uri.has_prefix ("https://twitter.com/")) {
      // https://twitter.com/baedert/status/321423423423
      string[] parts = uri.split ("/");
      if (parts[4] == "status") {
        /* Treat it as a tweet link and hope it'll work out */
        int64 tweet_id = int64.parse (parts[5]);
        var bundle = new Cb.Bundle ();
        bundle.put_int (TweetInfoPage.KEY_MODE, TweetInfoPage.BY_ID);
        bundle.put_int64 (TweetInfoPage.KEY_TWEET_ID, tweet_id);
        bundle.put_string (TweetInfoPage.KEY_SCREEN_NAME, parts[3]);
        window.main_widget.switch_page (Page.TWEET_INFO,
                                        bundle);
        return true;
      }
    }
    return false;
  }


  void work_array (Json.Array   json_array,
                   TweetListBox tweet_list,
                   Account      account) {
    uint n_tweets = json_array.get_length ();
    /* If the request returned no results at all, we don't
       need to do all the later stuff */
    if (n_tweets == 0) {
      return;
    }

    var now = new GLib.DateTime.now_local ();
    for (uint i = 0; i < n_tweets; i++) {
      var tweet = new Cb.Tweet ();
      tweet.load_from_json (json_array.get_element (i), account.id, now);
      if (account.user_counter == null ||
          tweet_list == null ||
          !(tweet_list.get_toplevel () is Gtk.Window))
        break;

      account.user_counter.id_seen (ref tweet.source_tweet.author);
      if (tweet.retweeted_tweet != null)
        account.user_counter.id_seen (ref tweet.retweeted_tweet.author);

      if (account.filter_matches (tweet))
        tweet.set_flag (Cb.TweetState.HIDDEN_FILTERED);

      tweet_list.model.add (tweet);
    }
  }


  public void handle_media_click (Cb.Tweet   t,
                                  MainWindow window,
                                  int        index,
                                  double     px = 0.0,
                                  double     py = 0.0) {
    MediaDialog media_dialog = new MediaDialog (t, index, px, py);
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
    buffer.apply_tag_by_name (NO_SPELL_CHECK, word_start, iter1);
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
    buffer.apply_tag_by_name (NO_SPELL_CHECK, word_start, iter1);
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
    buffer.apply_tag_by_name (NO_SPELL_CHECK, word_start, iter1);
  }

  private void maybe_highlight_snippet (Gtk.TextBuffer buffer,
                                        Gtk.TextIter?  word_start,
                                        Gtk.TextIter?  word_end) {
    string word = buffer.get_text (word_start, word_end, false);

    if (word.length == 0)
      return;

    string? snippet;
    if ((snippet = Corebird.snippet_manager.get_snippet (word)) != null) {
      buffer.apply_tag_by_name ("snippet", word_start, word_end);
      buffer.apply_tag_by_name (NO_SPELL_CHECK, word_start, word_end);
    }
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
        } else {
          maybe_highlight_snippet (buffer, word_start_iter, next_iter);
        }
      }

      if (done)
        break;

      cur_iter = next_iter;
    }
  }

  public void sort_entities (ref Cb.TextEntity[] entities) {
    /* Just use bubblesort here. Our n is very small (< 15 maybe?) */

    for (int i = 0; i < entities.length; i ++) {
      for (int k = 0; k < entities.length; k ++) {
        if (entities[i].from < entities[k].from) {
          Cb.TextEntity c = entities[i];
          entities[i] = entities[k];
          entities[k] = c;
        }
      }
    }
  }
}
