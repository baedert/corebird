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

using Gtk;
[GtkTemplate (ui = "/org/baedert/corebird/ui/tweet-info-page.ui")]
class TweetInfoPage : IPage , ScrollWidget {
  public static const uint BY_INSTANCE = 1;
  public static const uint BY_ID       = 2;

  public int unread_count { get{return 0;} set {} }
  public int id                         { get; set; }
  public unowned MainWindow main_window { get; set; }
  public unowned Account account { get; set; }
  private int64 tweet_id;
  private bool values_set = false;
  private Tweet tweet;
  private bool following;
  private string tweet_media;

  [GtkChild]
  private Label text_label;
  [GtkChild]
  private TextButton name_button;
  [GtkChild]
  private Label screen_name_label;
  [GtkChild]
  private Image avatar_image;
  [GtkChild]
  private Label rt_fav_label;
  [GtkChild]
  private Label location_label;
  [GtkChild]
  private Gtk.Box location_box;
  [GtkChild]
  private ListBox bottom_list_box;
  [GtkChild]
  private ListBox top_list_box;
  [GtkChild]
  private Spinner progress_spinner;
  [GtkChild]
  private ToggleButton favorite_button;
  [GtkChild]
  private ToggleButton retweet_button;
  [GtkChild]
  private Button follow_button;
  [GtkChild]
  private Label time_label;
  [GtkChild]
  private Gtk.Label source_label;
  [GtkChild]
  private PixbufButton media_button;
  [GtkChild]
  private Gtk.MenuItem delete_menu_item;
  [GtkChild]
  private MaxSizeContainer max_size_container;

  public TweetInfoPage (int id) {
    this.id = id;
    media_button.clicked.connect (() => {
      ImageDialog img_dialog = new ImageDialog (main_window, tweet_media);
      img_dialog.show_all ();
    });
    this.scroll_event.connect ((evt) => {
      if (evt.delta_y < 0 && this.vadjustment.value == 0) {
        int inc = (int)(vadjustment.step_increment * (-evt.delta_y));
        max_size_container.max_size += inc;
        max_size_container.queue_resize ();
        return true;
      }
      return false;
    });
    top_list_box.set_sort_func (ITwitterItem.sort_func_inv);
    bottom_list_box.row_activated.connect ((row) => {
      main_window.switch_page (MainWindow.PAGE_TWEET_INFO,
                               TweetInfoPage.BY_INSTANCE,
                               ((TweetListEntry)row).tweet);
    });
    top_list_box.row_activated.connect ((row) => {
      main_window.switch_page (MainWindow.PAGE_TWEET_INFO,
                               TweetInfoPage.BY_INSTANCE,
                               ((TweetListEntry)row).tweet);
    });
  }

  public void on_join (int page_id, va_list args){
    uint mode = args.arg ();

    if (mode == 0)
      return;

    values_set = false;


    bottom_list_box.foreach ((w) => {bottom_list_box.remove (w);});
    bottom_list_box.hide ();
    top_list_box.foreach ((w) => {top_list_box.remove (w);});
    top_list_box.hide ();
    max_size_container.max_size = 0;
    max_size_container.queue_resize ();

    progress_spinner.hide ();
    media_button.hide ();


    if (mode == BY_INSTANCE) {
      this.tweet = args.arg ();
      this.tweet_id = tweet.id;
      set_tweet_data (tweet);
      set_source_link (tweet.id, tweet.screen_name);
    } else if (mode == BY_ID) {
      this.tweet_id = args.arg ();
    }

    query_tweet_info ();
  }

  public void on_leave () {
  }


  [GtkCallback]
  private void favorite_button_toggled_cb () {
    if (!values_set)
      return;

    favorite_button.sensitive = false;
    TweetUtils.toggle_favorite_tweet.begin (account, tweet, !favorite_button.active, () => {
        favorite_button.sensitive = true;
    });
  }

  [GtkCallback]
  private void retweet_button_toggled_cb () {
    if (!values_set)
      return;
    retweet_button.sensitive = false;
    TweetUtils.toggle_retweet_tweet.begin (account, tweet, !retweet_button.active, () => {
      retweet_button.sensitive = true;
    });
  }

  [GtkCallback]
  private void reply_button_clicked_cb () {
    ComposeTweetWindow ctw = new ComposeTweetWindow(main_window, this.account, this.tweet,
                                                    ComposeTweetWindow.Mode.REPLY);
    ctw.show ();
  }

  [GtkCallback]
  private void quote_item_activate_cb () {
    ComposeTweetWindow ctw = new ComposeTweetWindow(main_window, this.account, this.tweet,
                                                    ComposeTweetWindow.Mode.QUOTE);
    ctw.show ();
  }

  [GtkCallback]
  private void delete_item_activate_cb () {
    critical ("Implement");
  }

  [GtkCallback]
  private void follow_button_clicked_cb () { // {{{
    var call = account.proxy.new_call();
    if (following)
      call.set_function ("1.1/friendships/destroy.json");
    else
      call.set_function( "1.1/friendships/create.json");
    call.set_method ("POST");
    call.add_param ("follow", "true");
    call.add_param ("id", tweet.user_id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try {
        set_follow_button_state (!following);
        following = !following;
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        critical (e.message);
        Utils.show_error_object (call.get_payload (), e.message);
      }
    });
  } //}}}

  [GtkCallback]
  private bool link_activated_cb (string uri) {
    return TweetUtils.activate_link (uri, main_window);
  }

  [GtkCallback]
  private void name_button_clicked_cb () {
    main_window.switch_page (MainWindow.PAGE_PROFILE,
                             tweet.user_id);
  }

  /**
   * Loads the data of the tweet with the id tweet_id from the Twitter server.
   */
  private void query_tweet_info () { //{{{
    follow_button.sensitive = false;

    var now = new GLib.DateTime.now_local ();
    var call = account.proxy.new_call ();
    call.set_method ("GET");
    call.set_function ("1.1/statuses/show.json");
    call.add_param ("id", tweet_id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      }catch (GLib.Error e) {
        critical(e.message);
        Utils.show_error_object (call.get_payload (), e.message);
        return;
      }
      this.tweet = new Tweet ();
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }
      tweet.load_from_json (parser.get_root (), now, account);
      Json.Object root_object = parser.get_root ().get_object ();
      if (root_object.has_member ("retweeted_status"))
        this.following = root_object.get_object_member ("retweeted_status")
                                    .get_object_member ("user").get_boolean_member ("following");
      else
        this.following = root_object.get_object_member ("user").get_boolean_member ("following");

      string with = root_object.get_string_member ("source");
      with = extract_source (with);
      set_tweet_data (tweet, following, with);
      if (!root_object.get_null_member ("place")) {
        var place = root_object.get_object_member ("place");
        location_box.show ();
        location_label.label = place.get_string_member ("name");
      } else
        location_box.hide ();

      if (tweet.reply_id == 0) {
        progress_spinner.stop ();
        load_replied_to_tweet (tweet.reply_id);
      } else
        load_replied_to_tweet (tweet.reply_id);
      values_set = true;
    });


    //
    var reply_call = account.proxy.new_call ();
    reply_call.set_method ("GET");
    reply_call.set_function ("1.1/search/tweets.json");
    reply_call.add_param ("q", "to:" + tweet.screen_name);
    reply_call.add_param ("since_id", tweet_id.to_string ());
    reply_call.add_param ("count", "200");
    reply_call.invoke_async.begin (null, (o, res) => {
      try { reply_call.invoke_async.end (res); }
      catch (GLib.Error e) {
        warning (e.message);
        Utils.show_error_object (reply_call.get_payload (), e.message);
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (reply_call.get_payload ());
      } catch (GLib.Error e) {
        warning (e.message);
        debug (reply_call.get_payload ());
        return;
      }
      var statuses_node = parser.get_root ().get_object ().get_array_member ("statuses");
      int n_replies = 0;
      statuses_node.foreach_element ((arr, index, node) => {
        if (n_replies >= 5)
          return;

        var obj = node.get_object ();
        if (!obj.has_member ("in_reply_to_status_id") || obj.get_null_member ("in_reply_to_status_id"))
          return;

        int64 reply_id = obj.get_int_member ("in_reply_to_status_id");
        if (reply_id != tweet_id) {
          return;
        }

        Tweet t = new Tweet ();
        t.load_from_json (node, now, account);
        var tle = new TweetListEntry (t, main_window, account);
        tle.show_all ();
        top_list_box.add (tle);
        n_replies ++;
      });

      if (n_replies > 0) {
        top_list_box.show ();
      }
    });

  } //}}}

  /**
   * Loads the tweet this tweet is a reply to.
   * This will recursively call itself until the end of the chain is reached.
   *
   * @param reply_id The id of the tweet the previous tweet was a reply to.
   */
  private void load_replied_to_tweet (int64 reply_id) { //{{{
    if (reply_id == 0) {
      progress_spinner.stop ();
      progress_spinner.hide ();
      return;
    }

    bottom_list_box.show ();
    var call = account.proxy.new_call ();
    call.set_function ("1.1/statuses/show.json");
    call.set_method ("GET");
    call.add_param ("id", reply_id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      }catch (GLib.Error e) {
        critical(e.message);
        Utils.show_error_object (call.get_payload (), e.message);
        progress_spinner.hide ();
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }
      bool user_protected = parser.get_root ().get_object ().get_object_member ("user")
                                                            .get_boolean_member ("protected");
      if (user_protected) {
        load_replied_to_tweet (parser.get_root ().get_object ().get_int_member ("in_reply_to_status_id"));
      } else {
        Tweet tweet = new Tweet ();
        tweet.load_from_json (parser.get_root (), new GLib.DateTime.now_local (), account);
        bottom_list_box.add (new TweetListEntry (tweet, main_window, account));
        load_replied_to_tweet (tweet.reply_id);
      }
    });
  } //}}}

  /**
   *
   */
  private void set_tweet_data (Tweet tweet, bool following = false, string? with = null) {//{{{
    account.user_counter.user_seen (tweet.user_id, tweet.screen_name, tweet.user_name);
    GLib.DateTime created_at = new GLib.DateTime.from_unix_local (tweet.created_at);
    string time_format = created_at.format ("%x, %X");
    if (with != null) {
      time_format += " via " + with;
    }

    text_label.label = "<b><big><big><big>"+tweet.get_formatted_text ()+"</big></big></big></b>";
    name_button.label = tweet.user_name;
    screen_name_label.label = "@" + tweet.screen_name;
    avatar_image.pixbuf = tweet.avatar;
    rt_fav_label.label = "<big><b>%'d</b></big> Retweets  <big><b>%'d</b></big> Favorites"
                         .printf (tweet.retweet_count, tweet.favorite_count);
    time_label.label = time_format;
    retweet_button.active = tweet.retweeted;
    favorite_button.active = tweet.favorited;

    set_source_link (tweet.id, tweet.screen_name);

    // TODO: Also do this on inline_media_added signal
    if (tweet.media != null) {
      tweet_media = tweet.media;
      media_button.show ();
      media_button.set_bg (tweet.inline_media);
    }

    if (tweet.user_id == account.id) {
      follow_button.hide ();
      delete_menu_item.show ();
      retweet_button.hide ();
    } else {
      set_follow_button_state (following);
      follow_button.show ();
      delete_menu_item.hide ();
      retweet_button.show ();
    }
  } //}}}

  private void set_follow_button_state (bool following) { //{{{
    var sc = follow_button.get_style_context ();
    follow_button.sensitive = true;
    if (following) {
      sc.remove_class ("suggested-action");
      sc.add_class ("destructive-action");
      follow_button.label = _("Unfollow");
    } else {
      sc.remove_class ("destructive-action");
      sc.add_class ("suggested-action");
      follow_button.label = _("Follow");
    }
    this.following = following;
  } //}}}


  private void set_source_link (int64 id, string screen_name) {
    var link = "https://twitter.com/%s/status/%s".printf (screen_name,
                                                          id.to_string());
    source_label.label = "<span underline='none'><a href='%s' title='Open in Browser'>Source</a></span>".printf (link);
  }

  /**
   * Twitter's source parameter of tweets includes a 'rel' parameter
   * that doesn't work as pango markup, so we just remove it here.
   *
   * Example string:
   *   <a href=\"http://www.tweetdeck.com\" rel=\"nofollow\">TweetDeck</a>
   *
   * @param source_str The source string from twitter
   *
   * @return The #source_string without the rel parameter
   */
  private string extract_source (string source_str) { //{{{
    int from, to;
    int tmp = 0;
    tmp = source_str.index_of_char ('"');
    tmp = source_str.index_of_char ('"', tmp + 1);
    from = source_str.index_of_char ('"', tmp + 1);
    to = source_str.index_of_char ('"', from + 1);
    if (to == -1 || from == -1)
      return source_str;
    return source_str.substring (0, from-5) + source_str.substring(to + 1);
  } //}}}

  public void create_tool_button (Gtk.RadioToolButton? group) {}
  public Gtk.RadioToolButton? get_tool_button () {
    return null;
  }
}
