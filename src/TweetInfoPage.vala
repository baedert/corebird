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
public class TweetInfoPage : IPage, Cb.ScrollWidget, Cb.MessageReceiver {
  public const int KEY_MODE        = 0;
  public const int KEY_TWEET       = 1;
  public const int KEY_EXISTING    = 2;
  public const int KEY_TWEET_ID    = 3;
  public const int KEY_SCREEN_NAME = 4;

  public const int BY_INSTANCE = 1;
  public const int BY_ID       = 2;

  private const GLib.ActionEntry[] action_entries = {
    {"quote",    quote_activated   },
    {"reply",    reply_activated   },
    {"favorite", favorite_activated},
    {"delete",   delete_activated  }
  };

  public int unread_count { get {return 0;} }
  public int id           { get; set; }
  private unowned Cb.MainWindow _main_window;
  public unowned Cb.MainWindow main_window {
    set {
      _main_window = value;
    }
  }
  public unowned Account account;
  private int64 tweet_id;
  private string screen_name;
  private bool values_set = false;
  private Cb.Tweet tweet;
  private GLib.SimpleActionGroup actions;
  private GLib.Cancellable? cancellable = null;

  [GtkChild]
  private Gtk.Box main_box;
  [GtkChild]
  private MultiMediaWidget mm_widget;
  [GtkChild]
  private Gtk.Label text_label;
  [GtkChild]
  private Gtk.Button name_button;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Label rt_label;
  [GtkChild]
  private Gtk.Label fav_label;
  [GtkChild]
  private Cb.TweetListBox conversation_list_box;
  [GtkChild]
  private Cb.TweetListBox reply_list_box;
  [GtkChild]
  private Gtk.ToggleButton favorite_button;
  [GtkChild]
  private Gtk.ToggleButton retweet_button;
  [GtkChild]
  private Gtk.Label time_label;
  [GtkChild]
  private Gtk.Label source_label;
  [GtkChild]
  private Cb.MaxSizeContainer max_size_container;
  [GtkChild]
  private Cb.ReplyIndicator reply_indicator;
  [GtkChild]
  private Gtk.Stack main_stack;
  [GtkChild]
  private Gtk.Label error_label;
  [GtkChild]
  private Gtk.Label reply_label;
  [GtkChild]
  private Gtk.Box reply_box;

  public TweetInfoPage (int id, Account account) {
    this.id = id;
    this.account = account;

    this.reply_indicator.clicked.connect (() => {
      max_size_container.animate_open ();
    });

    var scroll_controller = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.VERTICAL);
    scroll_controller.set_propagation_phase (Gtk.PropagationPhase.BUBBLE);
    scroll_controller.scroll.connect ((delta_x, delta_y) => {
      if (delta_y < 0 && this.get_vadjustment ().value == 0 && reply_indicator.get_replies_available ()) {
        double inc = (- delta_y) * 0.2;
        max_size_container.set_fraction (max_size_container.get_fraction () + inc);
      }
      return true;
    });
    this.add_controller (scroll_controller);

    conversation_list_box.model.set_reverse_order ();

    mm_widget.media_clicked.connect ((m, i) => TweetUtils.handle_media_click (tweet, _main_window, i));
    conversation_list_box.get_widget ().row_activated.connect ((row) => {
      var bundle = new Cb.Bundle ();
      bundle.put_int (KEY_MODE, TweetInfoPage.BY_INSTANCE);
      bundle.put_object (KEY_TWEET, ((Cb.TweetRow)row).tweet);
      bundle.put_bool (KEY_EXISTING, true);
      _main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
    });
    reply_list_box.get_widget ().row_activated.connect ((row) => {
      var bundle = new Cb.Bundle ();
      bundle.put_int (KEY_MODE, TweetInfoPage.BY_INSTANCE);
      bundle.put_object (KEY_TWEET, ((Cb.TweetRow)row).tweet);
      bundle.put_bool (KEY_EXISTING, true);
      _main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
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

  public void on_join (int page_id, Cb.Bundle? args) {
    int mode = args.get_int (KEY_MODE);

    if (mode == 0)
      return;

    values_set = false;

    bool existing = args.get_bool (KEY_EXISTING);

    max_size_container.set_fraction (0.0);
    main_stack.visible_child = main_box;

    /* If we have a tweet instance here already, we set the avatar now instead of in
     * set_tweet_data, since the rearrange_tweets() or list.model.clear() calls
     * might cause the avatar to get removed from the cache. */

    if (existing) {
      // Only possible BY_INSTANCE
      var tweet = (Cb.Tweet) args.get_object (KEY_TWEET);
      if (Twitter.get ().has_avatar (tweet.get_user_id ()))
        avatar_image.texture = Twitter.get ().get_cached_avatar (tweet.get_user_id ());

      rearrange_tweets (tweet.id);
    } else {
      conversation_list_box.model.clear ();
      conversation_list_box.get_widget ().hide ();
      reply_list_box.model.clear ();
      reply_list_box.get_widget ().hide ();
    }

    if (mode == BY_INSTANCE) {
      Cb.Tweet tweet = (Cb.Tweet)args.get_object (KEY_TWEET);

      if (Twitter.get ().has_avatar (tweet.get_user_id ()))
        avatar_image.texture = Twitter.get ().get_cached_avatar (tweet.get_user_id ());

      if (tweet.retweeted_tweet != null)
        this.tweet_id = tweet.retweeted_tweet.id;
      else
        this.tweet_id = tweet.id;

      this.screen_name = tweet.get_screen_name ();
      this.tweet = tweet;
      set_tweet_data (tweet);
    } else if (mode == BY_ID) {
      this.tweet = null;
      this.tweet_id = args.get_int64 (KEY_TWEET_ID);
      this.screen_name = args.get_string (KEY_SCREEN_NAME);
    }

    query_tweet_info (existing);
  }

  private void load_user_avatar (string url) {
    string avatar_url;
    int scale = this.get_scale_factor ();

    if (scale == 1)
      avatar_url = url.replace ("_normal", "_bigger");
    else
      avatar_url = url.replace ("_normal", "_200x200");

    TweetUtils.download_avatar.begin (avatar_url, avatar_image.size * scale, cancellable, (obj, res) => {
      Gdk.Texture texture;
      try {
        var pixbuf = TweetUtils.download_avatar.end (res);
        if (pixbuf == null) {
          texture = Twitter.no_avatar;
        } else {
          texture = Gdk.Texture.for_pixbuf (pixbuf);
        }
      } catch (GLib.Error e) {
        warning (e.message);
        texture = Twitter.no_avatar;
      }
      avatar_image.texture = texture;
    });
  }

  private void rearrange_tweets (int64 new_id) {
    //assert (new_id != this.tweet_id);

    if (reply_list_box.model.contains_id (new_id)) {
      // Move the current tweet down into conversation_list_box
      conversation_list_box.model.add (this.tweet);
      conversation_list_box.get_widget ().show ();
      reply_list_box.model.clear ();
      reply_list_box.get_widget ().hide ();
    } else if (conversation_list_box.model.contains_id (new_id)) {
      // Remove all tweets above the new one from the bottom list box,
      // add the direct successor to the top_list
      reply_list_box.model.clear ();
      reply_list_box.get_widget ().show ();
      var t = conversation_list_box.model.get_for_id (new_id, -1);
      if (t != null) {
        reply_list_box.model.add (t);
      } else {
        reply_list_box.model.add (this.tweet);
      }

      conversation_list_box.model.remove_tweets_above (new_id);
      if (conversation_list_box.model.get_n_items () == 0)
        conversation_list_box.get_widget ().hide ();
    }
    //else
      //error ("wtf");
  }

  public void on_leave () {
    if (cancellable != null) {
      cancellable.cancel ();
      cancellable = null;
    }
  }


  [GtkCallback]
  private void favorite_button_toggled_cb () {
    if (!values_set)
      return;

    favorite_button.sensitive = false;

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
    ComposeTweetWindow ctw = new ComposeTweetWindow(_main_window, this.account, this.tweet,
                                                    ComposeTweetWindow.Mode.REPLY);
    ctw.show ();
  }

  [GtkCallback]
  private bool link_activated_cb (string uri) {
    return TweetUtils.activate_link (uri, _main_window);
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

    var bundle = new Cb.Bundle ();
    bundle.put_int64 (ProfilePage.KEY_USER_ID, id);
    bundle.put_string (ProfilePage.KEY_SCREEN_NAME, screen_name);
    _main_window.main_widget.switch_page (Page.PROFILE, bundle);
  }

  private void query_tweet_info (bool existing) {
    if (this.cancellable != null) {
      this.cancellable.cancel ();
    }

    this.cancellable = new Cancellable ();

    var now = new GLib.DateTime.now_local ();
    var call = account.proxy.new_call ();
    call.set_method ("GET");
    call.set_function ("api/v1/statuses/" + tweet_id.to_string ());
    call.add_header ("Authorization", "Bearer " + ((Rest.OAuth2Proxy)account.proxy).get_access_token ());
    Cb.Utils.load_threaded_async.begin (call, cancellable, (__, res) => {
      Json.Node? root = null;
      string? with = null;

      try {
        root = Cb.Utils.load_threaded_async.end (res);
      } catch (GLib.Error e) {
        error_label.label = "%s: %s".printf (_("Could not show tweet"), e.message);
        main_stack.visible_child = error_label;
        return;
      }

      if (root == null)
        return;

      Json.Object root_object = root.get_object ();

      if (this.tweet != null) {
        int n_retweets  = (int)root_object.get_int_member ("reblogs_count");
        int n_favorites = (int)root_object.get_int_member ("favourites_count");
        this.tweet.retweet_count = n_retweets;
        this.tweet.favorite_count = n_favorites;
      } else {
        this.tweet = new Cb.Tweet ();
        tweet.load_from_json (root, account.id, now);
      }

      if (root_object.has_member ("application")) {
        var app_obj = root_object.get_object_member ("application");
        string name = app_obj.get_string_member ("name");
        string url = app_obj.get_string_member ("website");
        with = "<span underline='none'><a href='%s'>%s</a></span>".printf (url, name);
      }

      set_tweet_data (tweet, with);

      if (!existing) {
        if (tweet.retweeted_tweet == null)
          load_replied_to_tweet (tweet.source_tweet.reply_id);
        else
          load_replied_to_tweet (tweet.retweeted_tweet.reply_id);
      }

      values_set = true;
    });

    warning ("Load replies to status");
    //var reply_call = account.proxy.new_call ();
    //reply_call.set_method ("GET");
    //reply_call.set_function ("1.1/search/tweets.json");
    //reply_call.add_param ("q", "to:" + this.screen_name);
    //reply_call.add_param ("since_id", tweet_id.to_string ());
    //reply_call.add_param ("count", "200");
    //reply_call.add_param ("tweet_mode", "extended");
    //Cb.Utils.load_threaded_async.begin (reply_call, cancellable, (_, res) => {
      //Json.Node? root = null;

      //try {
        //root = Cb.Utils.load_threaded_async.end (res);
      //} catch (GLib.Error e) {
        //if (!(e is GLib.IOError.CANCELLED))
          //warning (e.message);

        //return;
      //}

      //if (root == null)
        //return;

      //var statuses_node = root.get_object ().get_array_member ("statuses");
      //int64 previous_tweet_id = -1;
      //if (reply_list_box.model.get_n_items () > 0) {
        //assert (reply_list_box.model.get_n_items () == 1);
        //previous_tweet_id = ((Cb.Tweet)(reply_list_box.model.get_item (0))).id;
      //}
      //int n_replies = 0;
      //statuses_node.foreach_element ((arr, index, node) => {
        //if (n_replies >= 5)
          //return;

        //var obj = node.get_object ();
        //if (!obj.has_member ("in_reply_to_status_id") || obj.get_null_member ("in_reply_to_status_id"))
          //return;

        //int64 reply_id = obj.get_int_member ("in_reply_to_status_id");
        //if (reply_id != tweet_id) {
          //return;
        //}

        //var t = new Cb.Tweet ();
        //t.load_from_json (node, account.id, now);
        //if (t.id != previous_tweet_id) {
          //reply_list_box.get_widget ().show ();
          //reply_list_box.model.add (t);
          //n_replies ++;
        //}
      //});
    //});

  }

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

    conversation_list_box.get_widget ().show ();
    var call = account.proxy.new_call ();
    call.set_function ("1.1/statuses/show.json");
    call.set_method ("GET");
    call.add_param ("id", reply_id.to_string ());
    call.add_param ("tweet_mode", "extended");
    call.invoke_async.begin (cancellable, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        if (e.message.strip () != "Forbidden" &&
            e.message.strip ().down () != "not found" &&
            !(e is GLib.IOError.CANCELLED)) {
          critical (e.message);
          Utils.show_error_object (call.get_payload (), e.message,
                                   GLib.Log.LINE, GLib.Log.FILE, this._main_window);
        }

        /* We may not count the listbox placeholder here */
        int n_children = 0;
        foreach (Gtk.Widget w in conversation_list_box.get_widget ().get_children ()) {
          if (w is Gtk.ListBoxRow) {
            n_children ++;
          }
        }

        conversation_list_box.get_widget ().visible = n_children > 0;
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
      tweet.load_from_json (parser.get_root (), account.id, new GLib.DateTime.now_local ());
      conversation_list_box.model.add (tweet);
      if (tweet.retweeted_tweet == null)
        load_replied_to_tweet (tweet.source_tweet.reply_id);
      else
        load_replied_to_tweet (tweet.retweeted_tweet.reply_id);

      reply_indicator.show ();
      reply_indicator.set_replies_available (true);
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

    text_label.label = tweet.get_formatted_text ();
    ((Gtk.Label)name_button.get_child ()).set_label (tweet.get_user_name ());
    screen_name_label.label = "@" + tweet.get_screen_name ();

    load_user_avatar (tweet.avatar_url);
    update_rt_fav_labels ();
    time_label.label = time_format;
    retweet_button.active  = tweet.is_flag_set (Cb.TweetState.RETWEETED);
    favorite_button.active = tweet.is_flag_set (Cb.TweetState.FAVORITED);
    avatar_image.verified  = tweet.is_flag_set (Cb.TweetState.VERIFIED);

    set_source_link (tweet.id, tweet.get_screen_name ());

    if ((tweet.retweeted_tweet != null &&
         tweet.retweeted_tweet.reply_id != 0) ||
        tweet.source_tweet.reply_id != 0) {
      var reply_users = tweet.get_reply_users ();
      reply_box.show ();
      var buff = new StringBuilder ();
      buff.append (_("Replying to"));
      buff.append_c (' ');
      Cb.Utils.linkify_user (ref reply_users[0], buff);

      for (int i = 1; i < reply_users.length - 1; i ++) {
        buff.append (", ");
        Cb.Utils.linkify_user (ref reply_users[i], buff);
      }

      if (reply_users.length > 1) {
        /* Last one */
        buff.append_c (' ')
            .append (_("and"))
            .append_c (' ');
        Cb.Utils.linkify_user (ref reply_users[reply_users.length - 1], buff);
      }

      reply_label.label = buff.str;

      // Since this is a reply to a tweet, we always need to show this
      reply_indicator.set_replies_available (true);
    } else {
      reply_indicator.set_replies_available (false);
      reply_box.hide ();
    }

    if (tweet.has_inline_media ()) {
      this.mm_widget.visible = (Settings.get_media_visiblity () != MediaVisibility.HIDE);
      mm_widget.set_all_media (tweet.get_medias ());
    } else {
      mm_widget.hide ();
    }

    ((GLib.SimpleAction)actions.lookup_action ("delete")).set_enabled (tweet.get_user_id () == account.id);

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
    ComposeTweetWindow ctw = new ComposeTweetWindow (_main_window, this.account, this.tweet,
                                                     ComposeTweetWindow.Mode.QUOTE);
    ctw.show ();
  }

  private void reply_activated () {
    ComposeTweetWindow ctw = new ComposeTweetWindow (_main_window, this.account, this.tweet,
                                                     ComposeTweetWindow.Mode.REPLY);
    ctw.show ();
  }

  private void favorite_activated () {
    if (!values_set || !favorite_button.sensitive)
      return;

    bool favoriting = !favorite_button.active;

    favorite_button.sensitive = false;

    this.update_rt_fav_labels ();

    TweetUtils.set_favorite_status.begin (account, tweet, favoriting, () => {
      favorite_button.sensitive = true;
      values_set = false;
      favorite_button.active = favoriting;
      values_set = true;
    });
  }

  private void delete_activated () {
    if (this.tweet == null ||
        this.tweet.get_user_id () != account.id) {
      return;
    }

    this._main_window.main_widget.remove_current_page ();
    TweetUtils.delete_tweet.begin (account, tweet, () => {
    });
  }

  public string get_title () {
    return _("Tweet Details");
  }

  public void create_radio_button (Gtk.RadioButton? group) {}
  public Cb.BadgeRadioButton? get_radio_button () {
    return null;
  }

  public void stream_message_received (Cb.StreamMessageType type,
                                       Json.Node         root) {
    if (type == Cb.StreamMessageType.TWEET) {
      Json.Object root_obj = root.get_object ();
      if (Utils.usable_json_value (root_obj, "in_reply_to_status_id")) {
        int64 reply_id = root_obj.get_int_member ("in_reply_to_status_id");

        if (reply_id == this.tweet_id) {
          var t = new Cb.Tweet ();
          t.load_from_json (root, account.id, new GLib.DateTime.now_local ());
          reply_list_box.model.add (t);
        }
      }
    } else if (type == Cb.StreamMessageType.DELETE) {
      int64 tweet_id = root.get_object ().get_object_member ("delete")
                                         .get_object_member ("status")
                                         .get_int_member ("id");
      if (tweet_id == this.tweet_id && _main_window.get_cur_page_id () == this.id) {
        /* TODO: We should probably remove this page with this bundle form the
                 history, even if it's not the currently visible page */
        debug ("Current tweet with id %s deleted!", tweet_id.to_string ());
        this._main_window.main_widget.remove_current_page ();
      }
    } else if (type == Cb.StreamMessageType.EVENT_FAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      int64 source_id = root.get_object ().get_object_member ("source").get_int_member ("id");
      if (source_id == account.id && id == this.tweet_id) {
        this.values_set = false;
        this.favorite_button.active = true;
        this.tweet.favorite_count ++;
        this.update_rt_fav_labels ();
        this.values_set = true;
      }

    } else if (type == Cb.StreamMessageType.EVENT_UNFAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      int64 source_id = root.get_object ().get_object_member ("source").get_int_member ("id");
      if (source_id == account.id && id == this.tweet_id) {
        this.values_set = false;
        this.favorite_button.active = false;
        this.tweet.favorite_count --;
        this.update_rt_fav_labels ();
        this.values_set = true;
      }
    }
  }
}
