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

[GtkTemplate (ui = "/org/baedert/corebird/ui/profile-page.ui")]
class ProfilePage : ScrollWidget, IPage, IMessageReceiver {
  private const GLib.ActionEntry[] action_entries = {
    {"write-dm", write_dm_activated},
    {"tweet-to", tweet_to_activated},
    {"add-remove-list", add_remove_list_activated},
  };

  public int unread_count {
    get { return 0; }
  }

  private unowned MainWindow main_window;
  public unowned MainWindow window {
    set {
      main_window = value;
      user_lists.main_window = value;
    }
  }
  public unowned Account account;
  public int id { get; set; }

  [GtkChild]
  private AspectImage banner_image;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private Gtk.Label description_label;
  [GtkChild]
  private Gtk.Label url_label;
  [GtkChild]
  private Gtk.Label tweets_label;
  [GtkChild]
  private Gtk.Label following_label;
  [GtkChild]
  private Gtk.Label followers_label;
  [GtkChild]
  private Gtk.Label location_label;
  [GtkChild]
  private FollowButton follow_button;
  [GtkChild]
  private TweetListBox tweet_list;
  [GtkChild]
  private TweetListBox followers_list;
  [GtkChild]
  private TweetListBox following_list;
  [GtkChild]
  private Gtk.Spinner progress_spinner;
  [GtkChild]
  private Gtk.Label follows_you_label;
  [GtkChild]
  private UserListsWidget user_lists;
  [GtkChild]
  private Gtk.Stack user_stack;
  [GtkChild]
  private Gtk.MenuButton more_button;
  [GtkChild]
  private Gtk.Stack loading_stack;
  [GtkChild]
  private Gtk.RadioButton tweets_button;
  private int64 user_id;
  private new string name;
  private string screen_name;
  private string avatar_url;
  private int follower_count = -1;
  private GLib.Cancellable data_cancellable;
  private bool lists_page_inited = false;
  private bool block_item_blocked = false;
  private bool retweet_item_blocked = false;
  private bool mute_item_blocked = false;
  private bool tweets_loading = false;
  private bool followers_loading = false;
  private Cursor? followers_cursor = null;
  private bool following_loading = false;
  private Cursor? following_cursor = null;
  private GLib.SimpleActionGroup actions;

  public ProfilePage (int id, Account account, DeltaUpdater delta_updater) {
    this.id = id;
    this.account = account;
    this.user_lists.account = account;
    this.tweet_list.account = account;
    this.tweet_list.delta_updater = delta_updater;

    this.scroll_event.connect ((evt) => {
      if (evt.delta_y < 0 && this.vadjustment.value == 0) {
        if (banner_image.scale >= 1.0) {
          banner_image.scale = 1.0f;
          return false;
        }
        banner_image.scale += 0.25f * (-evt.delta_y);
        return true;
      }
      return false;
    });
    this.scrolled_to_end.connect (() => {
      if (user_stack.visible_child == tweet_list) {
        this.load_older_tweets.begin ();
      } else if (user_stack.visible_child == followers_list) {
        this.load_followers.begin ();
      } else if (user_stack.visible_child == following_list) {
        this.load_following.begin ();
      }
    });

    tweet_list.row_activated.connect ((row) => {
      var bundle = new Bundle ();
      bundle.put_int ("mode", TweetInfoPage.BY_INSTANCE);
      bundle.put_object ("tweet", ((TweetListEntry)row).tweet);
      main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
    });
    followers_list.row_activated.connect ((row) => {
      var bundle = new Bundle ();
      bundle.put_int64 ("user_id", ((UserListEntry)row).user_id);
      bundle.put_string ("screen_name", ((UserListEntry)row).screen_name);
      main_window.main_widget.switch_page (Page.PROFILE, bundle);
    });
    following_list.row_activated.connect ((row) => {
      var bundle = new Bundle ();
      bundle.put_int64 ("user_id", ((UserListEntry)row).user_id);
      bundle.put_string ("screen_name", ((UserListEntry)row).screen_name);
      main_window.main_widget.switch_page (Page.PROFILE, bundle);
    });


    user_lists.hide_user_list_entry ();

    actions = new GLib.SimpleActionGroup ();
    actions.add_action_entries (action_entries, this);

    GLib.SimpleAction block_action = new GLib.SimpleAction.stateful ("toggle-blocked", null,
                                                                     new GLib.Variant.boolean (false));
    block_action.activate.connect (toggle_blocked_activated);
    actions.add_action (block_action);

    GLib.SimpleAction mute_action = new GLib.SimpleAction.stateful ("toggle-muted", null,
                                                                    new GLib.Variant.boolean (false));
    mute_action.activate.connect (toggle_muted_activated);
    actions.add_action (mute_action);

    GLib.SimpleAction rt_action = new GLib.SimpleAction.stateful ("toggle-retweets", null,
                                                                  new GLib.Variant.boolean (false));
    rt_action.activate.connect (retweet_action_activated);
    actions.add_action (rt_action);


    this.insert_action_group ("user", actions);
  }

  private void set_user_id (int64 user_id) {
    this.user_id = user_id;

    follow_button.sensitive = (user_id != account.id);
    ((SimpleAction)actions.lookup_action ("add-remove-list")).set_enabled (user_id != account.id);
    ((SimpleAction)actions.lookup_action ("write-dm")).set_enabled (user_id != account.id);
    ((SimpleAction)actions.lookup_action ("toggle-blocked")).set_enabled (user_id != account.id);
    ((SimpleAction)actions.lookup_action ("toggle-muted")).set_enabled (user_id != account.id);
    /* We (maybe) re-enable this later when the friendship object has arrived */
    ((SimpleAction)actions.lookup_action ("toggle-retweets")).set_enabled (false);

    /* Set muted and blocked status now, let the friendship update it */
    set_user_blocked (account.is_blocked (user_id));
    set_user_muted (account.is_muted (user_id));

    set_banner (null);
    load_friendship.begin ();
    /* Load the profile data now, then - if available - set the cached data */
    load_profile_data.begin (user_id);
  }


  private async void load_friendship () {
    uint fr = yield UserUtils.load_friendship (account, this.user_id);

    follows_you_label.visible = (fr & FRIENDSHIP_FOLLOWED_BY) > 0;
    set_user_blocked ((fr & FRIENDSHIP_BLOCKING) > 0);
    set_retweets_disabled ((fr & FRIENDSHIP_FOLLOWING) > 0 &&
                           (fr & FRIENDSHIP_WANT_RETWEETS) == 0);

    if ((fr & FRIENDSHIP_CAN_DM) == 0)
      ((SimpleAction)actions.lookup_action ("write-dm")).set_enabled (false);

    ((SimpleAction)actions.lookup_action ("toggle-retweets")).set_enabled ((fr & FRIENDSHIP_FOLLOWING) > 0);
  }

  private async void load_profile_data (int64 user_id) {
    loading_stack.visible_child_name = "progress";
    progress_spinner.start ();

    follow_button.sensitive = false;
    var call = account.proxy.new_call ();
    call.set_method ("GET");
    call.set_function ("1.1/users/show.json");
    call.add_param ("user_id", user_id.to_string ());
    call.add_param ("include_entities", "false");

    Json.Node? root_node = null;
    try {
      root_node = yield TweetUtils.load_threaded (call, data_cancellable);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }

    if (root_node == null) return;

    var root = root_node.get_object();
    int64 id = root.get_int_member ("id");

    string avatar_url = root.get_string_member("profile_image_url");
    int scale = this.get_scale_factor ();

    if (scale == 1)
      avatar_url = avatar_url.replace("_normal", "_bigger");
    else
      avatar_url = avatar_url.replace ("_normal", "_200x200");

    // We don't use our AvatarCache here because this (73×73) avatar is only
    // ever loaded here.
    TweetUtils.download_avatar.begin (avatar_url, 73 * scale, (obj, res) => {
      Cairo.Surface surface;
      try {
        var pixbuf = TweetUtils.download_avatar.end (res);
        surface = Gdk.cairo_surface_create_from_pixbuf (pixbuf, scale, null);
      } catch (GLib.Error e) {
        warning (e.message);
        surface = Twitter.no_avatar;
      }
      avatar_image.surface = surface;
      progress_spinner.stop ();
      loading_stack.visible_child_name = "data";
    });

    string name        = root.get_string_member("name").replace ("&", "&amp;").strip ();
    string screen_name = root.get_string_member("screen_name");
    string description = root.get_string_member("description").replace("&", "&amp;");
    int followers      = (int)root.get_int_member("followers_count");
    int following      = (int)root.get_int_member("friends_count");
    int tweets         = (int)root.get_int_member("statuses_count");
    bool is_following  = false;
    if (Utils.usable_json_value (root, "following"))
      is_following = root.get_boolean_member("following");
    bool has_url       = root.get_object_member("entities").has_member("url");
    bool verified      = root.get_boolean_member ("verified");
    bool protected_user = root.get_boolean_member ("protected");
    if (protected_user) {
      tweet_list.set_placeholder_text (_("Protected profile"));
    }

    if (root.has_member ("profile_banner_url")) {
      string banner_base_url = root.get_string_member ("profile_banner_url");
      load_profile_banner (banner_base_url, user_id);
    }

    string display_url = "";
    Json.Object entities = root.get_object_member ("entities");
    if (has_url) {
      var urls_object = entities.get_object_member("url").get_array_member("urls").
        get_element(0).get_object();

      var url = urls_object.get_string_member("expanded_url");
      if (urls_object.has_member ("display_url")) {
        display_url = urls_object.get_string_member("expanded_url");
      } else {
        url = urls_object.get_string_member("url");
        display_url = url;
      }
    }

    string location = null;
    if (root.has_member("location")) {
      location = root.get_string_member("location");
    }

    Cb.TextEntity[]? text_urls = null;
    if (root.has_member ("description")) {
      Json.Array urls = entities.get_object_member ("description").get_array_member ("urls");
      text_urls = new Cb.TextEntity[urls.get_length ()];
      urls.foreach_element ((arr, i, node) => {
        var ent = node.get_object ();
        string expanded_url = ent.get_string_member ("expanded_url");
        expanded_url = expanded_url.replace ("&", "&amp;");
        Json.Array indices = ent.get_array_member ("indices");
        text_urls[i] = Cb.TextEntity(){
          from = (uint)indices.get_int_element (0),
          to   = (uint)indices.get_int_element (1),
          target = expanded_url,
          display_text = ent.get_string_member ("display_url")
        };
      });
    }

    account.user_counter.user_seen (id, screen_name, name);

    this.follow_button.following = is_following;
    this.follow_button.sensitive = (this.user_id != this.account.id);


    var section = (GLib.Menu)more_button.menu_model.get_item_link (0, GLib.Menu.LINK_SECTION);
    var user_item = new GLib.MenuItem (_("Tweet to @%s").printf (screen_name),
                                       "user.tweet-to");
    section.remove (1);
    section.insert_item (1, user_item);

    name_label.set_markup (name.strip ());
    screen_name_label.set_label ("@" + screen_name);
    //tweet_to_menu_item.label = _("Tweet to @%s").printf (screen_name);
    string desc = description;
    if (text_urls != null) {
      TweetUtils.sort_entities (ref text_urls);
      desc = Cb.TextTransform.text (description,
                                    text_urls,
                                    0,
                                    0,
                                    0);
    }

    this.follower_count = followers;
    description_label.label = "<big>" + desc + "</big>";
    tweets_label.label = "%'d".printf(tweets);
    following_label.label = "%'d".printf(following);
    update_follower_label ();

    if (location != null && location != "") {
      location_label.visible = true;
      location_label.label = location;
    } else
      location_label.visible = false;

    avatar_image.verified = verified;

    if (display_url.length > 0) {
      url_label.visible = true;
      url_label.set_markup ("<span underline='none'><a href='%s'>%s</a></span>"
                            .printf (display_url, display_url));
      description_label.margin_bottom = 6;
    } else {
      url_label.visible = false;
      description_label.margin_bottom = 12;
    }

    this.name = name;
    this.screen_name = screen_name;
    this.avatar_url = avatar_url;
  }


  private async void load_tweets () {
    tweet_list.set_unempty ();
    tweets_loading = true;
    int requested_tweet_count = 10;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/statuses/user_timeline.json");
    call.set_method ("GET");
    call.add_param ("user_id", this.user_id.to_string ());
    call.add_param ("count", requested_tweet_count.to_string ());
    call.add_param ("contributor_details", "true");
    call.add_param ("include_my_retweet", "true");


    Json.Node? root = null;
    try {
      root = yield TweetUtils.load_threaded (call, data_cancellable);
    } catch (GLib.Error e) {
      warning (e.message);
      tweet_list.set_empty ();
      return;
    }

    if (root == null) return;

    var root_array = root.get_array ();
    if (root_array.get_length () == 0) {
      tweet_list.set_empty ();
      return;
    }
    yield TweetUtils.work_array (root_array,
                                 tweet_list,
                                 account);
    tweets_loading = false;
  }

  private async void load_older_tweets () {
    if (tweets_loading)
      return;

    if (user_stack.visible_child != tweet_list)
      return;

    tweets_loading = true;
    int requested_tweet_count = 15;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/statuses/user_timeline.json");
    call.set_method ("GET");
    call.add_param ("user_id", this.user_id.to_string ());
    call.add_param ("count", requested_tweet_count.to_string ());
    call.add_param ("contributor_details", "true");
    call.add_param ("include_my_retweet", "true");
    call.add_param ("max_id", (tweet_list.model.lowest_id - 1).to_string ());

    Json.Node? root = null;
    try {
      root = yield TweetUtils.load_threaded (call, data_cancellable);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }

    if (root == null) return;

    var root_arr = root.get_array ();
    yield TweetUtils.work_array (root_arr,
                                 tweet_list,
                                 account);
    tweets_loading = false;
  }

  private async void load_followers () {
    if (this.followers_cursor != null && this.followers_cursor.full)
      return;

    if (this.followers_loading)
      return;

    this.followers_loading = true;

    this.followers_cursor = yield UserUtils.load_followers (this.account,
                                                            this.user_id,
                                                            this.followers_cursor);

    if (this.followers_cursor == null)
      return;

    var users_array = this.followers_cursor.json_object.get_array ();

    users_array.foreach_element ((array, index, node) => {
      var user_obj = node.get_object ();
      string avatar_url = user_obj.get_string_member ("profile_image_url");

      if (this.get_scale_factor () == 2)
        avatar_url = avatar_url.replace ("_normal", "_bigger");


      var entry = new UserListEntry ();
      entry.show_settings = false;
      entry.user_id = user_obj.get_int_member ("id");
      entry.screen_name = "@" + user_obj.get_string_member ("screen_name");
      entry.name = user_obj.get_string_member ("name");
      entry.avatar_url = avatar_url;
      entry.get_style_context ().add_class ("tweet");
      entry.show ();
      this.followers_list.add (entry);
    });

    this.followers_loading = false;
  }

  private async void load_following () {
    if (this.following_cursor != null && this.following_cursor.full)
      return;

    if (this.following_loading)
      return;

    this.following_loading = true;

    this.following_cursor = yield UserUtils.load_following (this.account,
                                                            this.user_id,
                                                            this.following_cursor);

    if (this.following_cursor == null)
      return;

    var users_array = this.following_cursor.json_object.get_array ();

    users_array.foreach_element ((array, index, node) => {
      var user_obj = node.get_object ();
      string avatar_url = user_obj.get_string_member ("profile_image_url");

      if (this.get_scale_factor () == 2)
        avatar_url = avatar_url.replace ("_normal", "_bigger");

      var entry = new UserListEntry ();
      entry.show_settings = false;
      entry.user_id = user_obj.get_int_member ("id");
      entry.screen_name = "@" + user_obj.get_string_member ("screen_name");
      entry.name = user_obj.get_string_member ("name");
      entry.avatar_url = avatar_url;
      entry.get_style_context ().add_class ("tweet");
      entry.show ();
      this.following_list.add (entry);

    });

    this.following_loading = false;
  }

  private void load_profile_banner (string base_url, int64 user_id) {
    string banner_url  = base_url + "/mobile_retina";
    Utils.download_pixbuf.begin (banner_url, null, (obj, res) => {
      Gdk.Pixbuf? banner = Utils.download_pixbuf.end (res);
      set_banner (banner);
    });
  }

  [GtkCallback]
  private void follow_button_clicked_cb () {
    var call = account.proxy.new_call();
    HomeTimeline ht = (HomeTimeline) main_window.get_page (Page.STREAM);
    if (follow_button.following) {
      call.set_function( "1.1/friendships/destroy.json");
      ht.hide_tweets_from (this.user_id, TweetState.HIDDEN_UNFOLLOWED);
      ht.hide_retweets_from (this.user_id, TweetState.HIDDEN_UNFOLLOWED);
      follower_count --;
      account.unfollow_id (this.user_id);
      ((SimpleAction)actions.lookup_action ("toggle-retweets")).set_enabled (false);
      set_retweets_disabled (false);
    } else {
      call.set_function ("1.1/friendships/create.json");
      call.add_param ("follow", "false");
      ht.show_tweets_from (this.user_id, TweetState.HIDDEN_UNFOLLOWED);
      if (!((SimpleAction)actions.lookup_action ("toggle-retweets")).get_state ().get_boolean ()) {
        ht.show_retweets_from (this.user_id, TweetState.HIDDEN_UNFOLLOWED);
      }
      set_user_blocked (false);
      follower_count ++;
      account.follow_id (this.user_id);
      ((SimpleAction)actions.lookup_action ("toggle-retweets")).set_enabled (true);
    }
    update_follower_label ();
    progress_spinner.start ();
    loading_stack.visible_child_name = "progress";
    follow_button.sensitive = false;
    call.set_method ("POST");
    call.add_param ("id", user_id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try {
        this.follow_button.following = !this.follow_button.following;
        this.follow_button.sensitive = (this.user_id != this.account.id);
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        critical (e.message);
        critical (call.get_payload ());
      }
      follow_button.sensitive = true;
      progress_spinner.stop ();
      loading_stack.visible_child_name = "data";
    });
  }

  [GtkCallback]
  private bool activate_link (string uri) {
    return TweetUtils.activate_link (uri, main_window);
  }


  private inline void set_banner (Gdk.Pixbuf? banner) {
    if (banner == null)
      banner_image.pixbuf = Twitter.no_banner;
    else
      banner_image.pixbuf = banner;
  }

  /**
   * see IPage#onJoin
   */
  public void on_join (int page_id, Bundle? args) {
    int64 user_id = args.get_int64 ("user_id");
    if (user_id == -1)
      return;

    string? screen_name = args.get_string ("screen_name");
    if (screen_name != null) {
      this.screen_name = screen_name;
    }


    data_cancellable = new GLib.Cancellable ();

    if (user_id != this.user_id) {
      reset_data ();
      followers_cursor = null;
      followers_list.remove_all ();
      following_cursor = null;
      following_list.remove_all ();
      set_user_id (user_id);
      if (account.follows_id (user_id)) {
        this.follow_button.following = true;
        this.follow_button.sensitive = true;
      }
      tweet_list.model.clear ();
      user_lists.clear_lists ();
      lists_page_inited = false;
      load_tweets.begin ();
    }
    tweet_list.reset_placeholder_text ();
    followers_list.reset_placeholder_text ();
    following_list.reset_placeholder_text ();
    tweets_button.active = true;
    //user_stack.visible_child = tweet_list;
  }

  public void on_leave () {
    // We might otherwise overwrite the new user's data with that from the old one.
    data_cancellable.cancel ();
    banner_image.scale = 0.3;
  }

  private void reset_data () {
    name_label.label = " ";
    screen_name_label.label = " ";
    description_label.label = " ";
    url_label.label = " ";
    location_label.label = " ";
    tweets_label.label = " ";
    following_label.label = " ";
    followers_label.label = " ";
    avatar_image.surface = null;
  }

  public void create_radio_button (Gtk.RadioButton? group) {}


  public string get_title () {
    return "@" + screen_name;
  }

  public Gtk.RadioButton? get_radio_button(){
    return null;
  }

  private void write_dm_activated (GLib.SimpleAction a, GLib.Variant? v) {
    var bundle = new Bundle ();
    bundle.put_int64 ("sender_id", user_id);
    bundle.put_string ("screen_name", screen_name);
    bundle.put_string ("name", name);
    bundle.put_string ("avatar_url", avatar_url.replace ("_bigger", "_normal"));
    main_window.main_widget.switch_page (Page.DM, bundle);
  }

  private void tweet_to_activated (GLib.SimpleAction a, GLib.Variant? v) {
    var cw = new ComposeTweetWindow (main_window, account, null);
    cw.set_text ("@" + screen_name + " ");
    cw.show_all ();
  }

  private void add_remove_list_activated (GLib.SimpleAction a, GLib.Variant? v) {
    var uld = new UserListDialog (main_window, account, user_id);
    uld.load_lists ();
    uld.show_all ();
  }


  private void toggle_blocked_activated (GLib.SimpleAction a, GLib.Variant? v) {
    if (block_item_blocked)
      return;

    block_item_blocked = true;

    bool current_state = get_user_blocked ();
    HomeTimeline ht = (HomeTimeline) main_window.get_page (Page.STREAM);
    var call = account.proxy.new_call ();
    call.set_method ("POST");
    if (current_state) {
      call.set_function ("1.1/blocks/destroy.json");
      ht.show_tweets_from (this.user_id, TweetState.HIDDEN_AUTHOR_BLOCKED);
    } else {
      call.set_function ("1.1/blocks/create.json");
      this.follow_button.following = false;
      this.follow_button.sensitive = (this.user_id != this.account.id);
      ht.hide_tweets_from (this.user_id, TweetState.HIDDEN_AUTHOR_BLOCKED);
    }
    set_user_blocked (!current_state);
    call.add_param ("user_id", this.user_id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE, this.main_window);
        /* Reset the state if the blocking failed */
        a.set_state (new GLib.Variant.boolean (current_state));
      }
      block_item_blocked = false;
    });
  }

  private void toggle_muted_activated (GLib.SimpleAction a, GLib.Variant? v) {
    bool setting = get_user_muted ();
    mute_item_blocked = true;
    a.set_state (!setting);
    UserUtils.mute_user.begin (account,this.user_id, !setting, (obj, res) => {
      UserUtils.mute_user.end (res);
      mute_item_blocked = false;
      HomeTimeline ht = (HomeTimeline) main_window.get_page (Page.STREAM);
      if (setting) {
        ht.show_tweets_from (this.user_id, TweetState.HIDDEN_AUTHOR_MUTED);
        ht.show_retweets_from (this.user_id, TweetState.HIDDEN_RETWEETER_MUTED);
      } else {
        ht.hide_tweets_from (this.user_id, TweetState.HIDDEN_AUTHOR_MUTED);
        ht.hide_retweets_from (this.user_id, TweetState.HIDDEN_RETWEETER_MUTED);
      }
    });
  }

  private void retweet_action_activated (GLib.SimpleAction a, GLib.Variant? v) {
    if (retweet_item_blocked)
      return;

    retweet_item_blocked = true;
    bool current_state = a.get_state ().get_boolean ();
    a.set_state (new GLib.Variant.boolean (!current_state));
    var call = account.proxy.new_call ();
    call.set_function ("1.1/friendships/update.json");
    call.set_method ("POST");
    call.add_param ("user_id", this.user_id.to_string ());
    call.add_param ("retweets", current_state.to_string ());
    HomeTimeline ht = (HomeTimeline) main_window.get_page (Page.STREAM);
    if (current_state) {
      ht.show_retweets_from (this.user_id, TweetState.HIDDEN_RTS_DISABLED);
      account.remove_disabled_rts_id (this.user_id);
    } else {
      ht.hide_retweets_from (this.user_id, TweetState.HIDDEN_RTS_DISABLED);
      account.add_disabled_rts_id (this.user_id);
    }

    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE, this.main_window);
        /* Reset the state if the retweeting failed */
        a.set_state (new GLib.Variant.boolean (current_state));
      }
      retweet_item_blocked = false;
    });
  }


  private void set_user_blocked (bool blocked) {
    ((SimpleAction)actions.lookup_action ("toggle-blocked")).set_state (new GLib.Variant.boolean (blocked));
  }

  private bool get_user_blocked () {
    return ((SimpleAction)actions.lookup_action ("toggle-blocked")).get_state ().get_boolean ();
  }

  private void set_user_muted (bool muted) {
    ((SimpleAction)actions.lookup_action ("toggle-muted")).set_state (new GLib.Variant.boolean (muted));
  }

  private bool get_user_muted () {
    return ((SimpleAction)actions.lookup_action ("toggle-muted")).get_state ().get_boolean ();
  }

  private void set_retweets_disabled (bool disabled) {
    ((SimpleAction)actions.lookup_action ("toggle-retweets")).set_state (new GLib.Variant.boolean (disabled));
  }

  private void update_follower_label () {
    followers_label.label = "%'d".printf(follower_count);
  }

  public void stream_message_received (StreamMessageType type,
                                       Json.Node         root_node) {
    if (type == StreamMessageType.TWEET) {
      var obj = root_node.get_object ();
      var user = obj.get_object_member ("user");
      if (user.get_int_member ("id") != this.user_id)
        return;

      // Correct user!
      var tweet = new Tweet ();
      tweet.load_from_json (root_node,
                            new GLib.DateTime.now_local (),
                            this.account);
      this.tweet_list.model.add (tweet);
    }
  }

  [GtkCallback]
  private void tweets_button_toggled_cb (GLib.Object source) {
    if (((Gtk.RadioButton)source).active) {
      this.balance_next_upper_change (BOTTOM);
      user_stack.visible_child = tweet_list;
    }
  }
  [GtkCallback]
  private void followers_button_toggled_cb (GLib.Object source) {
    if (((Gtk.RadioButton)source).active) {
      if (this.followers_cursor == null) {
        this.load_followers.begin ();
      }
      this.balance_next_upper_change (BOTTOM);
      user_stack.visible_child = followers_list;
    }
  }

  [GtkCallback]
  private void following_button_toggled_cb (GLib.Object source) {
    if (((Gtk.RadioButton)source).active) {
      if (this.following_cursor == null) {
        this.load_following.begin ();
      }
      this.balance_next_upper_change (BOTTOM);
      user_stack.visible_child = following_list;
    }
  }

  [GtkCallback]
  private void lists_button_toggled_cb (GLib.Object source) {
    if (((Gtk.RadioButton)source).active) {
      if (!lists_page_inited) {
        user_lists.load_lists.begin (user_id);
        lists_page_inited = true;
      }
      this.balance_next_upper_change (BOTTOM);
      user_stack.visible_child = user_lists;
    }
  }
}
