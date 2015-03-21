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

[GtkTemplate (ui = "/org/baedert/corebird/ui/tweet-info-page.ui")]
class TweetInfoPage : IPage , ScrollWidget {
  public static const int BY_INSTANCE = 1;
  public static const int BY_ID       = 2;

  private const GLib.ActionEntry[] action_entries = {
    {"quote",  quote_activated},
  };

  public int unread_count { get{return 0;} set {} }
  public int id                         { get; set; }
  public unowned MainWindow main_window { get; set; }
  public unowned Account account { get; set; }
  private int64 tweet_id;
  private string screen_name;
  private bool values_set = false;
  private Tweet tweet;

  [GtkChild]
  private MultiMediaWidget mm_widget;
  [GtkChild]
  private Gtk.Label text_label;
  [GtkChild]
  private TextButton name_button;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Label rt_label;
  [GtkChild]
  private Gtk.Label fav_label;
  [GtkChild]
  private Gtk.ListBox bottom_list_box;
  [GtkChild]
  private Gtk.ListBox top_list_box;
  [GtkChild]
  private Gtk.ToggleButton favorite_button;
  [GtkChild]
  private Gtk.ToggleButton retweet_button;
  [GtkChild]
  private Gtk.Label time_label;
  [GtkChild]
  private Gtk.Label source_label;
  [GtkChild]
  private MaxSizeContainer max_size_container;
  [GtkChild]
  private ReplyIndicator reply_indicator;

  public TweetInfoPage (int id) {
    this.id = id;
    mm_widget.media_clicked.connect ((m, i) => TweetUtils.handle_media_click (tweet, main_window, i));
    this.scroll_event.connect ((evt) => {
      if (evt.delta_y < 0 && this.vadjustment.value == 0 && reply_indicator.replies_available) {
        int inc = (int)(vadjustment.step_increment * (-evt.delta_y));
        max_size_container.max_size += inc;
        max_size_container.queue_resize ();
        return true;
      }
      return false;
    });
    top_list_box.set_sort_func (ITwitterItem.sort_func_inv);
    bottom_list_box.row_activated.connect ((row) => {
      var bundle = new Bundle ();
      bundle.put_int ("mode", TweetInfoPage.BY_INSTANCE);
      bundle.put_object ("tweet", ((TweetListEntry)row).tweet);
      main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
    });
    top_list_box.row_activated.connect ((row) => {
      var bundle = new Bundle ();
      bundle.put_int ("mode", TweetInfoPage.BY_INSTANCE);
      bundle.put_object ("tweet", ((TweetListEntry)row).tweet);
      main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
    });

    GLib.SimpleActionGroup actions = new GLib.SimpleActionGroup ();
    actions.add_action_entries (action_entries, this);
    this.insert_action_group ("tweet", actions);
  }

  public void on_join (int page_id, Bundle? args) {
    int mode = args.get_int ("mode");

    if (mode == 0)
      return;

    values_set = false;

    if (mode == BY_INSTANCE) {
      Tweet tweet = (Tweet)args.get_object ("tweet");

      if (tweet.is_retweet)
        this.tweet_id = tweet.rt_id;
      else
        this.tweet_id = tweet.id;

      this.screen_name = tweet.screen_name;
      this.tweet = tweet;
      set_tweet_data (tweet);
    } else if (mode == BY_ID) {
      this.tweet_id = args.get_int64 ("tweet_id");
      this.screen_name = args.get_string ("screen_name");
    }

    bottom_list_box.foreach ((w) => {bottom_list_box.remove (w);});
    bottom_list_box.hide ();
    top_list_box.foreach ((w) => {top_list_box.remove (w);});
    top_list_box.hide ();
    reply_indicator.replies_available = false;
    max_size_container.max_size = 0;
    max_size_container.queue_resize ();


    query_tweet_info ();
  }

  public void on_leave () {}


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
  private bool link_activated_cb (string uri) {
    return TweetUtils.activate_link (uri, main_window);
  }

  [GtkCallback]
  private void name_button_clicked_cb () {
    var bundle = new Bundle ();
    bundle.put_int64 ("user_id", tweet.user_id);
    bundle.put_string ("screen_name", tweet.screen_name);
    main_window.main_widget.switch_page (Page.PROFILE, bundle);
  }

  /**
   * Loads the data of the tweet with the id tweet_id from the Twitter server.
   */
  private void query_tweet_info () { //{{{

    var now = new GLib.DateTime.now_local ();
    var call = account.proxy.new_call ();
    call.set_method ("GET");
    call.set_function ("1.1/statuses/show.json");
    call.add_param ("id", tweet_id.to_string ());
    TweetUtils.load_threaded.begin (call, (_, res) => {
      Json.Node? root = TweetUtils.load_threaded.end (res);

      if (root == null)
        return;

      this.tweet = new Tweet ();
      tweet.load_from_json (root, now, account);
      Json.Object root_object = root.get_object ();

      string with = root_object.get_string_member ("source");
      with = "<span underline='none'>" + extract_source (with) + "</span>";
      set_tweet_data (tweet, with);

      load_replied_to_tweet (tweet.reply_id);

      values_set = true;
    });


    //
    var reply_call = account.proxy.new_call ();
    reply_call.set_method ("GET");
    reply_call.set_function ("1.1/search/tweets.json");
    reply_call.add_param ("q", "to:" + this.screen_name);
    reply_call.add_param ("since_id", tweet_id.to_string ());
    reply_call.add_param ("count", "200");
    TweetUtils.load_threaded.begin (reply_call, (_, res) => {
      Json.Node? root = TweetUtils.load_threaded.end (res);

      if (root == null)
        return;

      var statuses_node = root.get_object ().get_array_member ("statuses");
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
        top_list_box.add (tle);
        n_replies ++;
      });

      if (n_replies > 0) {
        top_list_box.show ();
        reply_indicator.replies_available = true;
      } else {
        top_list_box.hide ();
        reply_indicator.replies_available = false;
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
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE);
        bottom_list_box.visible = (bottom_list_box.get_children ().length () > 0);
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }

      /* If we get here, the tweet is not protected so we can just use it */
      Tweet tweet = new Tweet ();
      tweet.load_from_json (parser.get_root (), new GLib.DateTime.now_local (), account);
      bottom_list_box.add (new TweetListEntry (tweet, main_window, account));
      load_replied_to_tweet (tweet.reply_id);
    });
  } //}}}

  /**
   *
   */
  private void set_tweet_data (Tweet tweet, string? with = null) {//{{{
    account.user_counter.user_seen (tweet.user_id, tweet.screen_name, tweet.user_name);
    GLib.DateTime created_at = new GLib.DateTime.from_unix_local (tweet.created_at);
    string time_format = created_at.format ("%x, %X");
    if (with != null) {
      time_format += " via " + with;
    }

    text_label.label = tweet.get_formatted_text ();
    name_button.label = tweet.user_name;
    screen_name_label.label = "@" + tweet.screen_name;
    avatar_image.pixbuf = tweet.avatar;
    rt_label.label = "<big><b>%'d</b></big> %s".printf (tweet.retweet_count, _("Retweets"));
    fav_label.label = "<big><b>%'d</b></big> %s".printf (tweet.favorite_count, _("Favorites"));
    time_label.label = time_format;
    retweet_button.active = tweet.retweeted;
    favorite_button.active = tweet.favorited;
    avatar_image.verified = tweet.verified;

    set_source_link (tweet.id, tweet.screen_name);

    if (tweet.has_inline_media) {
      mm_widget.set_all_media (tweet.medias);
      mm_widget.show ();
    } else {
      mm_widget.hide ();
    }

    if (tweet.user_id == account.id || tweet.protected) {
      retweet_button.hide ();
    } else {
      retweet_button.show ();
    }
  } //}}}

  private void set_source_link (int64 id, string screen_name) {
    var link = "https://twitter.com/%s/status/%s".printf (screen_name,
                                                          id.to_string ());

    source_label.label = "<span underline='none'><a href='%s' title='%s'>%s</a></span>"
                         .printf (link, _("Open in Browser"), _("Source"));
  }


  private void quote_activated () {
    ComposeTweetWindow ctw = new ComposeTweetWindow(main_window, this.account, this.tweet,
                                                    ComposeTweetWindow.Mode.QUOTE);
    ctw.show ();
  }

  public string? get_title () {
    return _("Tweet Details");
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

  public void create_tool_button (Gtk.RadioButton? group) {}
  public Gtk.RadioButton? get_tool_button () {
    return null;
  }
}
