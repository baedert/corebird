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
class TweetInfoPage : IPage, ScrollWidget, IMessageReceiver {
  public const int BY_INSTANCE = 1;
  public const int BY_ID       = 2;

  private const GLib.ActionEntry[] action_entries = {
    {"quote",    quote_activated   },
    {"reply",    reply_activated   },
    {"favorite", favorite_activated}
  };

  public int unread_count { get {return 0;} }
  public int id           { get; set; }
  public unowned MainWindow window {
    set {
      main_window = value;
    }
  }
  public unowned Account account;
  private int64 tweet_id;
  private string screen_name;
  private bool values_set = false;
  private Cb.Tweet tweet;
  private GLib.SimpleActionGroup actions;
  private unowned MainWindow main_window;
  private GLib.Cancellable? cancellable = null;

  [GtkChild]
  private Gtk.Grid grid;
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
  private TweetListBox bottom_list_box;
  [GtkChild]
  private TweetListBox top_list_box;
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
  [GtkChild]
  private Gtk.Stack main_stack;
  [GtkChild]
  private Gtk.Label error_label;

  public TweetInfoPage (int id, Account account, DeltaUpdater delta_updater) {
    this.id = id;
    this.account = account;
    this.top_list_box.account = account;
    this.bottom_list_box.account = account;
    this.top_list_box.delta_updater = delta_updater;
    this.bottom_list_box.delta_updater = delta_updater;


    mm_widget.media_clicked.connect ((m, i) => TweetUtils.handle_media_click (tweet, main_window, i));
    this.scroll_event.connect ((evt) => {
      if (evt.delta_y < 0 && this.vadjustment.value == 0 && reply_indicator.replies_available) {
        int inc = (int)(vadjustment.step_increment * (-evt.delta_y));
        max_size_container.max_size += inc;
        return true;
      }
      return false;
    });
    bottom_list_box.row_activated.connect ((row) => {
      var bundle = new Bundle ();
      bundle.put_int ("mode", TweetInfoPage.BY_INSTANCE);
      bundle.put_object ("tweet", ((TweetListEntry)row).tweet);
      bundle.put_bool ("existing", true);
      main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
    });
    top_list_box.row_activated.connect ((row) => {
      var bundle = new Bundle ();
      bundle.put_int ("mode", TweetInfoPage.BY_INSTANCE);
      bundle.put_object ("tweet", ((TweetListEntry)row).tweet);
      bundle.put_bool ("existing", true);
      main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
    });

    this.actions = new GLib.SimpleActionGroup ();
    this.actions.add_action_entries (action_entries, this);
    this.insert_action_group ("tweet", this.actions);

    Settings.get ().changed["media-visibility"].connect (media_visiblity_changed_cb);
    this.mm_widget.visible = (Settings.get_media_visiblity () != MediaVisibility.HIDE);
  }

  private void media_visiblity_changed_cb () {
    if (Settings.get_media_visiblity () == MediaVisibility.HIDE)
      this.mm_widget.hide ();
    else
      this.mm_widget.show ();
  }

  public void on_join (int page_id, Bundle? args) {
    int mode = args.get_int ("mode");

    if (mode == 0)
      return;

    values_set = false;

    bool existing = args.get_bool ("existing", false);

    reply_indicator.replies_available = false;
    max_size_container.max_size = 0;
    main_stack.visible_child = grid;


    if (existing) {
      // Only possible BY_INSTANCE
      var tweet = (Cb.Tweet) args.get_object ("tweet");
      rearrange_tweets (tweet.id);
    } else {
      bottom_list_box.model.clear ();
      bottom_list_box.hide ();
      top_list_box.model.clear ();
      top_list_box.hide ();
    }

    if (mode == BY_INSTANCE) {
      Cb.Tweet tweet = (Cb.Tweet)args.get_object ("tweet");

      if (tweet.retweeted_tweet != null)
        this.tweet_id = tweet.retweeted_tweet.id;
      else
        this.tweet_id = tweet.id;

      this.screen_name = tweet.get_screen_name ();
      this.tweet = tweet;
      set_tweet_data (tweet);
    } else if (mode == BY_ID) {
      this.tweet = null;
      this.tweet_id = args.get_int64 ("tweet_id");
      this.screen_name = args.get_string ("screen_name");
    }


    query_tweet_info (existing);
  }

  private void rearrange_tweets (int64 new_id) {
    //assert (new_id != this.tweet_id);

    if (top_list_box.model.contains_id (new_id)) {
      // Move the current tweet down into bottom_list_box
      bottom_list_box.model.add (this.tweet);
      bottom_list_box.show ();
      top_list_box.model.clear ();
      top_list_box.hide ();
    } else if (bottom_list_box.model.contains_id (new_id)) {
      // Remove all tweets above the new one from the bottom list box,
      // add the direct successor to the top_list
      top_list_box.model.clear ();
      top_list_box.show ();
      var t = bottom_list_box.model.get_from_id (new_id, -1);
      if (t != null) {
        top_list_box.model.add (t);
      } else {
        top_list_box.model.add (this.tweet);
      }

      reply_indicator.replies_available = true;

      bottom_list_box.model.remove_tweets_above (new_id);
      if (bottom_list_box.model.get_n_items () == 0)
        bottom_list_box.hide ();
    }
    //else
      //error ("wtf");
  }

  public void on_leave () {}


  [GtkCallback]
  private void favorite_button_toggled_cb () {
    if (!values_set)
      return;

    favorite_button.sensitive = false;

    if (favorite_button.active)
      this.tweet.favorite_count ++;
    else
      this.tweet.favorite_count --;

    this.update_rt_fav_labels ();

    TweetUtils.set_favorite_status.begin (account, tweet, favorite_button.active, () => {
      favorite_button.sensitive = true;
    });
  }

  [GtkCallback]
  private void retweet_button_toggled_cb () {
    if (!values_set)
      return;

    retweet_button.sensitive = false;
    if (retweet_button.active)
      this.tweet.retweet_count ++;
    else
      this.tweet.retweet_count --;
    this.update_rt_fav_labels ();

    TweetUtils.set_retweet_status.begin (account, tweet, retweet_button.active, () => {
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
    int64 id;
    string screen_name;

    if (this.tweet.retweeted_tweet != null) {
      id = this.tweet.retweeted_tweet.author.id;
      screen_name = this.tweet.retweeted_tweet.author.screen_name;
    } else {
      id = this.tweet.source_tweet.author.id;
      screen_name = this.tweet.source_tweet.author.screen_name;
    }

    var bundle = new Bundle ();
    bundle.put_int64 ("user_id", id);
    bundle.put_string ("screen_name", screen_name);
    main_window.main_widget.switch_page (Page.PROFILE, bundle);
  }

  /**
   * Loads the data of the tweet with the id tweet_id from the Twitter server.
   */
  private void query_tweet_info (bool existing) { //{{{
    if (this.cancellable != null) {
      this.cancellable.cancel ();
    }

    this.cancellable = new Cancellable ();

    var now = new GLib.DateTime.now_local ();
    var call = account.proxy.new_call ();
    call.set_method ("GET");
    call.set_function ("1.1/statuses/show.json");
    call.add_param ("id", tweet_id.to_string ());
    call.add_param ("include_my_retweet", "true");
    TweetUtils.load_threaded.begin (call, cancellable, (__, res) => {
      Json.Node? root = null;

      try {
        root = TweetUtils.load_threaded.end (res);
      } catch (GLib.Error e) {
        error_label.label = "%s: %s".printf (_("Could not show tweet"), e.message);
        main_stack.visible_child = error_label;
        return;
      }

      if (root == null)
        return;

      Json.Object root_object = root.get_object ();

      if (this.tweet != null) {
        int n_retweets  = (int)root_object.get_int_member ("retweet_count");
        int n_favorites = (int)root_object.get_int_member ("favorite_count");
        this.tweet.retweet_count = n_retweets;
        this.tweet.favorite_count = n_favorites;
      } else {
        this.tweet = new Cb.Tweet ();
        tweet.load_from_json (root, now);
      }

      string with = root_object.get_string_member ("source");
      with = "<span underline='none'>" + extract_source (with) + "</span>";

      set_tweet_data (tweet, with);

      if (!existing)
        load_replied_to_tweet (tweet.reply_id);

      values_set = true;
    });

    var reply_call = account.proxy.new_call ();
    reply_call.set_method ("GET");
    reply_call.set_function ("1.1/search/tweets.json");
    reply_call.add_param ("q", "to:" + this.screen_name);
    reply_call.add_param ("since_id", tweet_id.to_string ());
    reply_call.add_param ("count", "200");
    TweetUtils.load_threaded.begin (reply_call, cancellable, (_, res) => {
      Json.Node? root = null;

      try {
        root = TweetUtils.load_threaded.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }

      if (root == null)
        return;

      var statuses_node = root.get_object ().get_array_member ("statuses");
      int64 previous_tweet_id = -1;
      if (top_list_box.model.get_n_items () > 0) {
        //assert (top_list_box.model.get_n_items () == 1);
        previous_tweet_id = ((Cb.Tweet)(top_list_box.model.get_item (0))).id;
      }
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

        var t = new Cb.Tweet ();
        t.load_from_json (node, now);
        if (t.id != previous_tweet_id) {
          top_list_box.model.add (t);
          n_replies ++;
        }
      });

      if (n_replies > 0) {
        top_list_box.show ();
        reply_indicator.replies_available = true;
      } else {
        //top_list_box.hide ();
        //reply_indicator.replies_available = false;
      }

    });

  } //}}}

  /**
   * Loads the tweet this tweet is a reply to.
   * This will recursively call itself until the end of the chain is reached.
   *
   * @param reply_id The id of the tweet the previous tweet was a reply to.
   */
  private void load_replied_to_tweet (int64 reply_id) {
    if (reply_id == 0) {
      return;
    }

    bottom_list_box.show ();
    var call = account.proxy.new_call ();
    call.set_function ("1.1/statuses/show.json");
    call.set_method ("GET");
    call.add_param ("id", reply_id.to_string ());
    call.invoke_async.begin (cancellable, (obj, res) => {
      try {
        call.invoke_async.end (res);
      }catch (GLib.Error e) {
        critical(e.message);
        if (e.message.strip () != "Forbidden" &&
            e.message.strip ().down () != "not found") {
          Utils.show_error_object (call.get_payload (), e.message,
                                   GLib.Log.LINE, GLib.Log.FILE, this.main_window);
        }
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
      var tweet = new Cb.Tweet ();
      tweet.load_from_json (parser.get_root (), new GLib.DateTime.now_local ());
      bottom_list_box.model.add (tweet);
      load_replied_to_tweet (tweet.reply_id);
    });
  }

  /**
   *
   */
  private void set_tweet_data (Cb.Tweet tweet, string? with = null) {
    account.user_counter.user_seen (tweet.get_user_id (), tweet.get_screen_name (), tweet.get_user_name ());
    GLib.DateTime created_at = new GLib.DateTime.from_unix_local (
             tweet.retweeted_tweet != null ? tweet.retweeted_tweet.created_at :
                                             tweet.source_tweet.created_at);
    string time_format = created_at.format ("%x, %X");
    if (with != null) {
      time_format += " via " + with;
    }

    text_label.label = tweet.get_formatted_text (Settings.get_text_transform_flags ());
    name_button.set_markup (tweet.get_user_name ());
    screen_name_label.label = "@" + tweet.get_screen_name ();
    avatar_image.surface = Twitter.get ().get_avatar (tweet.get_user_id (), tweet.avatar_url, (a) => {
      avatar_image.surface = a;
    });
    update_rt_fav_labels ();
    time_label.label = time_format;
    retweet_button.active  = tweet.is_flag_set (Cb.TweetState.RETWEETED);
    favorite_button.active = tweet.is_flag_set (Cb.TweetState.FAVORITED);
    avatar_image.verified  = tweet.is_flag_set (Cb.TweetState.VERIFIED);


    set_source_link (tweet.id, tweet.get_screen_name ());

    if (tweet.has_inline_media ()) {
      mm_widget.set_all_media (tweet.get_medias ());
      this.mm_widget.visible = (Settings.get_media_visiblity () != MediaVisibility.HIDE);
    } else {
      mm_widget.hide ();
    }

    if (tweet.is_flag_set (Cb.TweetState.PROTECTED)) {
      retweet_button.hide ();
      ((GLib.SimpleAction)actions.lookup_action ("quote")).set_enabled (false);
    } else {
      retweet_button.show ();
      ((GLib.SimpleAction)actions.lookup_action ("quote")).set_enabled (true);
    }
  }

  private void update_rt_fav_labels () {
    rt_label.label = "<big><b>%'d</b></big> %s".printf (tweet.retweet_count, _("Retweets"));
    fav_label.label = "<big><b>%'d</b></big> %s".printf (tweet.favorite_count, _("Favorites"));
  }

  private void set_source_link (int64 id, string screen_name) {
    var link = "https://twitter.com/%s/status/%s".printf (screen_name,
                                                          id.to_string ());

    source_label.label = "<span underline='none'><a href='%s' title='%s'>%s</a></span>"
                         .printf (link, _("Open in Browser"), _("Source"));
  }


  private void quote_activated () {
    //ComposeTweetWindow ctw = new ComposeTweetWindow(main_window, this.account, this.tweet,
                                                    //ComposeTweetWindow.Mode.QUOTE);
    //ctw.show ();
  }

  private void reply_activated () {
    //ComposeTweetWindow ctw = new ComposeTweetWindow(main_window, this.account, this.tweet,
                                                    //ComposeTweetWindow.Mode.REPLY);
    //ctw.show ();
  }

  private void favorite_activated () {
    if (!values_set || !favorite_button.sensitive)
      return;

    bool favoriting = !favorite_button.active;

    favorite_button.sensitive = false;

    if (favoriting)
      this.tweet.favorite_count ++;
    else
      this.tweet.favorite_count --;

    this.update_rt_fav_labels ();

    TweetUtils.set_favorite_status.begin (account, tweet, favoriting, () => {
      favorite_button.sensitive = true;
      values_set = false;
      favorite_button.active = favoriting;
      values_set = true;
    });
  }

  public string get_title () {
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
  private string extract_source (string source_str) {
    int from, to;
    int tmp = 0;
    tmp = source_str.index_of_char ('"');
    tmp = source_str.index_of_char ('"', tmp + 1);
    from = source_str.index_of_char ('"', tmp + 1);
    to = source_str.index_of_char ('"', from + 1);
    if (to == -1 || from == -1)
      return source_str;
    return source_str.substring (0, from-5) + source_str.substring(to + 1);
  }

  public void create_radio_button (Gtk.RadioButton? group) {}
  public Gtk.RadioButton? get_radio_button () {
    return null;
  }

  public void stream_message_received (StreamMessageType type,
                                       Json.Node         root) {
    if (type != StreamMessageType.TWEET)
      return;

    Json.Object root_obj = root.get_object ();
    if (Utils.usable_json_value (root_obj, "in_reply_to_status_id")) {
      int64 reply_id = root_obj.get_int_member ("in_reply_to_status_id");

      if (reply_id == this.tweet_id) {
        var t = new Cb.Tweet ();
        t.load_from_json (root, new GLib.DateTime.now_local ());
        top_list_box.model.add (t);
        top_list_box.show ();
        this.reply_indicator.replies_available = true;
      }
    }
  }
}
