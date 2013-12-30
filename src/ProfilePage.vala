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

[GtkTemplate (ui = "/org/baedert/corebird/ui/profile-page.ui")]
class ProfilePage : ScrollWidget, IPage {
  private static const int PAGE_TWEETS     = 0;
  private static const int PAGE_FOLLOWING  = 1;
  private static const int PAGE_FOLLOWERS  = 2;

  public int unread_count {
    get{return 0;}
    set{}
  }
  public unowned MainWindow main_window { get; set; }
  public unowned Account account { get; set; }
  public int id { get; set; }

  [GtkChild]
  private Gtk.Image verified_image;
  [GtkChild]
  private AspectImage banner_image;
  [GtkChild]
  private Gtk.Image avatar_image;
  [GtkChild]
  private Label name_label;
  [GtkChild]
  private Label screen_name_label;
  [GtkChild]
  private Label description_label;
  [GtkChild]
  private Label url_label;
  [GtkChild]
  private Label location_label;
  [GtkChild]
  private Button follow_button;
  [GtkChild]
  private TweetListBox tweet_list;
  [GtkChild]
  private Gtk.Spinner progress_spinner;
  [GtkChild]
  private Gtk.Label follows_you_label;
  [GtkChild]
  private Gtk.MenuItem dm_menu_item;
  [GtkChild]
  private Gtk.MenuItem tweet_to_menu_item;
  private bool following;
  private int64 user_id;
  private new string name;
  private string screen_name;
  private string avatar_url;
  private GLib.Cancellable data_cancellable;

  public ProfilePage (int id) {
    this.id = id;
    this.scroll_event.connect ((evt) => {
      if (evt.delta_y < 0 && this.vadjustment.value == 0) {
        if (banner_image.scale >= 1.0) {
          banner_image.scale = 1.0f;
          return false;
        }
        banner_image.scale += 0.25f * (-evt.delta_y);
        banner_image.queue_resize ();
        return true;
      }
      return false;
    });

    tweet_list.row_activated.connect ((row) => {
      main_window.switch_page (MainWindow.PAGE_TWEET_INFO,
                               TweetInfoPage.BY_INSTANCE,
                               ((TweetListEntry)row).tweet);
    });

  }

  private void set_user_id (int64 user_id) { // {{{
    this.user_id = user_id;

    /* Load the profile data now, then - if available - set the cached data */
    load_profile_data.begin(user_id);
    follow_button.sensitive = (user_id != account.id);

    load_banner (DATADIR + "/no_banner.png");
    load_friendship();
    //Load cached data
    Corebird.db.select ("profiles").cols ("id", "screen_name", "name", "description", "tweets",
     "following", "followers", "avatar_name", "banner_url", "url", "location", "is_following",
     "banner_name").where_eqi ("id", user_id)
    .run ((vals) => {
      /* If we get inside this block, there is already some data in the
        DB we can use. */
      try {
        avatar_image.pixbuf = new Gdk.Pixbuf.from_file (Utils.user_file ("/assets/avatars/"+vals[7]));
      } catch (GLib.Error e) {
        warning (e.message);
      }

      set_data(vals[2], vals[1], vals[9], vals[10], vals[3],
               int.parse (vals[4]), int.parse (vals[5]), int.parse (vals[6]),
               vals[7], false);
      set_follow_button_state (bool.parse (vals[11]));
      string banner_name = vals[12];
      debug("banner_name: %s", banner_name);

      if (banner_name != null &&
          FileUtils.test(Utils.user_file("assets/banners/"+banner_name), FileTest.EXISTS)){
        message("Banner exists, set it directly...");
        load_banner (Utils.user_file ("assets/banners/" + banner_name));
      } else {
        // TODO: ???
        // If the cached banner does somehow not exist, load it again.
        debug("Banner %s does not exist, load it first...", banner_name);
        load_banner (DATADIR + "/no_banner.png");
      }
      return false;
    });
  } // }}}


  private void load_friendship () {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/friendships/show.json");
    call.set_method ("GET");
    call.add_param ("source_id", account.id.to_string ());
    call.add_param ("target_id", user_id.to_string ());
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message);
        return;
      }
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical ("%s:\n%s", e.message, call.get_payload ());
        return;
      }
      bool followed_by = parser.get_root ().get_object ().get_object_member ("relationship")
                               .get_object_member ("target").get_boolean_member ("following");
      follows_you_label.visible = followed_by;
    });
  }

  private async void load_profile_data (int64 user_id) { //{{{
    progress_spinner.show ();
    progress_spinner.start ();
    follow_button.sensitive = false;
    var call = account.proxy.new_call ();
    call.set_method ("GET");
    call.set_function ("1.1/users/show.json");
    call.add_param ("user_id", user_id.to_string ());
    call.add_param ("include_entities", "false");
    call.invoke_async.begin (data_cancellable, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        warning ("Error while ending call: %s", e.message);
        return;
      }
      string back = call.get_payload();
      Json.Parser parser = new Json.Parser();
      try{
        parser.load_from_data(back);
      } catch (GLib.Error e){
        warning ("Error while loading profile data: %s", e.message);
        return;
      }

      var root = parser.get_root().get_object();
      int64 id = root.get_int_member ("id");

      string avatar_url = root.get_string_member("profile_image_url");
      avatar_url = avatar_url.replace("_normal", "_bigger");
      string avatar_name = Utils.get_avatar_name(avatar_url);
      string avatar_on_disk = Utils.user_file("assets/avatars/"+avatar_name);

      if(!FileUtils.test(avatar_on_disk, FileTest.EXISTS)){
        Utils.download_file_async.begin(avatar_url, avatar_on_disk, data_cancellable, () => {
          try {
            avatar_image.pixbuf = new Gdk.Pixbuf.from_file (avatar_on_disk);
          } catch (GLib.Error e) {
            warning (e.message);
          }
          progress_spinner.stop ();
          progress_spinner.hide ();
        });
      }else {
        try {
          avatar_image.pixbuf = new Gdk.Pixbuf.from_file (avatar_on_disk);
        } catch (GLib.Error e) {
          warning (e.message);
        }
        progress_spinner.stop ();
        progress_spinner.hide ();
      }

      string name        = root.get_string_member("name").replace ("&", "&amp;");
      string screen_name = root.get_string_member("screen_name");
      string description = root.get_string_member("description").replace("&", "&amp;");
      int followers      = (int)root.get_int_member("followers_count");
      int following      = (int)root.get_int_member("friends_count");
      int tweets         = (int)root.get_int_member("statuses_count");
      bool is_following  = root.get_boolean_member("following");
      bool has_url       = root.get_object_member("entities").has_member("url");
      string banner_name = get_banner_name(user_id);
      bool verified      = root.get_boolean_member ("verified");

      if (root.has_member ("profile_banner_url")) {
        string banner_base_url = root.get_string_member ("profile_banner_url");
        load_profile_banner (banner_base_url, user_id);
      }

      string display_url = "";
      Json.Object entities = root.get_object_member ("entities");
      if(has_url) {
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
      if(root.has_member("location")){
        location = root.get_string_member("location");
      }

      GLib.SList<TweetUtils.Sequence?> text_urls = null;
      if (root.has_member ("description")) {
        Json.Array urls = entities.get_object_member ("description").get_array_member ("urls");
        text_urls = new GLib.SList<TweetUtils.Sequence?>();
        urls.foreach_element ((arr, i, node) => {
          var ent = node.get_object ();
          string expanded_url = ent.get_string_member ("expanded_url");
          expanded_url = expanded_url.replace ("&", "&amp;");
          Json.Array indices = ent.get_array_member ("indices");
          text_urls.prepend (TweetUtils.Sequence(){
            start = (int)indices.get_int_element (0),
            end   = (int)indices.get_int_element (1),
            url   = expanded_url,
            display_url = ent.get_string_member ("display_url")
          });

        });
      }

      account.user_counter.user_seen (id, screen_name, name);

      set_data(name, screen_name, display_url, location, description, tweets,
           following, followers, avatar_url, verified, text_urls);
      set_follow_button_state (is_following);
      Corebird.db.replace ("profiles")
                 .vali64 ("id", id)
                 .val ("screen_name", screen_name)
                 .val ("name", name)
                 .vali ("followers", followers)
                 .vali ("following", following)
                 .vali ("tweets", tweets)
                 .val ("description", description)
                 .val ("avatar_name", avatar_name)
                 .val ("url", display_url)
                 .val ("location", location)
                 .valb ("is_following", is_following)
                 .val ("banner_name", banner_name)
                 .run ();

    }); // end of callback
  } //}}}


  private void load_tweets () { // {{{
    tweet_list.set_unempty ();
    var call = account.proxy.new_call ();
    call.set_function ("1.1/statuses/user_timeline.json");
    call.set_method ("GET");
    call.add_param ("user_id", this.user_id.to_string ());
    call.add_param ("count", "35");
    call.add_param ("contributor_details", "true");
    call.add_param ("include_my_retweet", "true");

    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }
      var now = new GLib.DateTime.now_local ();
      var root = parser.get_root().get_array();
      if (root.get_length () == 0) {
        tweet_list.set_empty ();
        return;
      }
      root.foreach_element( (array, index, node) => {
        Tweet t = new Tweet();
        t.load_from_json(node, now);
//        if (tweet_type != -1){
//          t.type = tweet_type;
//        }

//        if(t.id < lowest_id)
//          lowest_id = t.id;
        var entry  = new TweetListEntry(t, main_window, account);
//        this.delta_updater.add (entry);
        tweet_list.add (entry);
      });


    });
  } // }}}

  /**
   * Loads the user's banner image.
   *
   * @param base_url The "base url" of the banner, obtained from the users/show call from Twitter.
   * @param user_id Foo
   * @param screen_name Bar
   */
  private void load_profile_banner (string base_url, int64 user_id) { // {{{
    string saved_banner_url = Utils.user_file ("assets/banners/"+get_banner_name (user_id));
    string banner_url  = base_url+"/mobile_retina";
    string banner_name = get_banner_name (user_id);
    string banner_on_disk = Utils.user_file("assets/banners/"+banner_name);
    if (!FileUtils.test (banner_on_disk, FileTest.EXISTS) || banner_url != saved_banner_url) {
      Utils.download_file_async .begin (banner_url, banner_on_disk, data_cancellable,
          () => {load_banner (banner_on_disk);});
        debug("Setting the banner name to %s", banner_name);
      Corebird.db.update ("profiles")
                 .val ("banner_url", banner_url)
                 .val ("banner_name", banner_name)
                 .where_eqi ("id", user_id)
                 .run ();
    } else {
      load_banner (banner_on_disk);
    }
  } // }}}


  private new void set_data (string name, string screen_name, string? url,
                             string? location, string description, int tweets,
                             int following, int followers, string avatar_url,
                             bool verified,
                             GLib.SList<TweetUtils.Sequence?>? text_urls = null
                             ) { //{{{

    name_label.set_markup("<b>%s</b>".printf (name));
    screen_name_label.set_label ("@" + screen_name);
    tweet_to_menu_item.label = _("Tweet to @%s").printf (screen_name);
    string desc = description;
    if (text_urls != null) {
      desc = TweetUtils.get_formatted_text (description, text_urls);
    }
    description_label.label = "<big><big>" + desc + "</big></big>";

    if (location != null && location != "") {
      location_label.visible = true;
      location_label.label = location;
    } else
      location_label.visible = false;

    if (verified) {
      verified_image.show ();
      if (verified_image.pixbuf == null) {
        try {
          verified_image.pixbuf = new Gdk.Pixbuf.from_file (DATADIR + "verified.png");
        } catch (GLib.Error e) {
          warning (e.message);
        }
      }
    } else {
      verified_image.hide ();
    }

    if (url != null && url != "") {
      url_label.visible = true;
      url_label.set_markup ("<a href='%s'>%s</a>".printf (url, url));
    } else
      url_label.visible = false;

    this.name = name;
    this.screen_name = screen_name;
    this.avatar_url = avatar_url;

  } //}}}

  [GtkCallback]
  private void follow_button_clicked_cb () { //{{{
    var call = account.proxy.new_call();
    if (following)
      call.set_function( "1.1/friendships/destroy.json");
    else
      call.set_function ("1.1/friendships/create.json");
    message (@"User ID: $user_id");
    message (user_id.to_string ());
    progress_spinner.show ();
    progress_spinner.start ();
    follow_button.sensitive = false;
    call.set_method ("POST");
    call.add_param ("follow", "true");
    call.add_param ("id", user_id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try {
        set_follow_button_state (!following);
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        critical (e.message);
      }
      follow_button.sensitive = true;
      progress_spinner.hide ();
    });
  } //}}}

  /*
   * Returns the banner name for the given user by user_id and screen_name.
   * This is useful since both of them might be used for the banner name.
   */
  private string get_banner_name (int64 user_id) {
    return user_id.to_string()+".png";
  }

  [GtkCallback]
  private bool activate_link (string uri) {
    return TweetUtils.activate_link (uri, main_window);
  }

  [GtkCallback]
  private void dm_menu_item_activate_cb () {
    main_window.switch_page (MainWindow.PAGE_DM,
                             user_id, screen_name, name, avatar_url);
  }

  [GtkCallback]
  private void tweet_to_item_activate_cb () {
    var cw = new ComposeTweetWindow (main_window, account, null);
    cw.set_text ("@" + screen_name + " ");
    cw.show_all ();
  }

  [GtkCallback]
  private void  list_menu_item_activated () {
    var uld = new UserListDialog (main_window, account, user_id);
    uld.load_lists ();
    uld.show_all ();
  }

  private void set_follow_button_state (bool following) { //{{{
    var sc = follow_button.get_style_context ();
    follow_button.sensitive = (user_id != account.id);
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
    dm_menu_item.sensitive = following;
  } //}}}


  private void load_banner (string path) {
    try {
      banner_image.pixbuf = new Gdk.Pixbuf.from_file (path);
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }


  /**
   * see IPage#onJoin
   */
  public void on_join(int page_id, va_list arg_list) {
    int64 user_id = arg_list.arg();
    if (user_id == 0)
      return;
    data_cancellable = new GLib.Cancellable ();
    set_user_id(user_id);
    tweet_list.remove_all ();
    load_tweets ();
  }

  public void on_leave () {
    // TODO: Reenable this once a new librest release is out;
    //       We might otherwise overwrite the new user's data with that from the old one.
//    data_cancellable.cancel ();
    account.user_counter.save (account.db);
    banner_image.scale = 0.3;
  }


  public void create_tool_button(RadioToolButton? group) {}

  public RadioToolButton? get_tool_button(){
    return null;
  }
}
