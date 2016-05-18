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

public class Account : GLib.Object {
  public static const string DUMMY = "screen_name";
  public int64 id;
  public Sql.Database db;
  public string screen_name       {public get; public  set;}
  public string name              {public get; public  set;}
  public string avatar_url        {public get; public  set;}
  public string? banner_url       {public get; private set;}
  public string? website          {public get; public  set;}
  public string? description      {public get; public  set;}
  public Cairo.Surface avatar_small {public get; public set;}
  public Cairo.Surface avatar       {public get; public set;}
  public Rest.OAuthProxy proxy;
  public UserStream user_stream;
  public UserCounter user_counter;
  private UserEventReceiver event_receiver;
  public NotificationManager notifications;
  public int64[] friends;
  public int64[] blocked;
  public int64[] muted;
  public int64[] disabled_rts;
  public GLib.GenericArray<Filter> filters;
  public signal void info_changed (string screen_name, string name,
                                   Cairo.Surface avatar_small, Cairo.Surface avatar);

  public Account (int64 id, string screen_name, string name) {
    this.id = id;
    this.screen_name = screen_name;
    this.name = name;
    this.filters = new GLib.GenericArray<Filter> ();
    this.event_receiver = new UserEventReceiver (this);
    this.notifications = new NotificationManager (this);
  }

  /**
   * Initializes the database. All account databases are VersionedDatabases
   * and are stored in accounts/ID.db.
   *
   */
  public void init_database () {
    if (db != null)
      return;

    this.db = new Sql.Database (Dirs.config (@"accounts/$id.db"),
                                Sql.ACCOUNTS_INIT_FILE,
                                Sql.ACCOUNTS_SQL_VERSION);
    user_counter = new UserCounter ();
    user_counter.load (db);
    this.load_filters ();
  }

  /**
   * Initializes the RestProxy object.
   *
   * @param load_secrets If set to true, the token and token_secret will be loaded
   *                     from the account's database.
   * @param force        If set to true, we will simply force to create a new
   *                     RestProxy object.
   */
  public void init_proxy (bool load_secrets = true, bool force = false) {
    if (proxy != null && !force)
      return;

    this.proxy = new Rest.OAuthProxy (Settings.get_consumer_key (),
                                      Settings.get_consumer_secret (),
                                      "https://api.twitter.com/",
                                      false);
    this.user_stream = new UserStream (this);
    this.user_stream.register (this.event_receiver);
    if (load_secrets) {
      init_database ();
      int n_rows = db.select ("common").cols ("token", "token_secret")
                                       .run ((vals) => {
        proxy.token = user_stream.token = vals[0];
        proxy.token_secret = user_stream.token_secret = vals[1];
        return false; //stop
      });

      if (n_rows < 1) {
        critical ("Could not load token{_secret} for user %s", this.screen_name);
      }
    }
  }

  public void uninit () {
    this.proxy = null;
    this.user_counter.save (this.db);
    this.user_stream.unregister (this.event_receiver);
    this.user_stream.stop ();
    this.user_stream = null;
  }

  /**
   * Loads the small and normally sized avatars from disk.
   * Normal: accounts/ID.png
   * Small:  accounts/ID_small.png
   */
  public void load_avatar () {
    string small_path = Dirs.config (@"accounts/$(id)_small.png");
    string path = Dirs.config (@"accounts/$(id).png");
    this.avatar_small = load_surface (small_path);
    this.avatar       = load_surface (path);
    info_changed (screen_name, name, avatar, avatar_small);
  }

  public void set_new_avatar (Cairo.Surface new_avatar) {
    string path       = Dirs.config (@"accounts/$(id).png");
    string small_path = Dirs.config (@"accounts/$(id)_small.png");


    Cairo.Surface avatar = scale_surface ((Cairo.ImageSurface)new_avatar, 48, 48);
    Cairo.Surface avatar_small = scale_surface ((Cairo.ImageSurface)new_avatar, 24, 24);


    write_surface (avatar, path);
    write_surface (avatar_small, small_path);

    this.avatar = avatar;
    this.avatar_small = avatar_small;
  }

  /**
   * Download the appropriate user info from the Twitter server,
   * updating the local information stored in this class' local variables
   * and the information stored in the account's database file.
   *
   * @param screen_name The screen name to use for the API call or null in
   *                    which case the ID will be used.
   */
  public async void query_user_info_by_screen_name (string? screen_name = null) {
    if (proxy == null)
      error ("Proxy not initied");

    var call = proxy.new_call ();
    call.set_function ("1.1/users/show.json");
    call.set_method ("GET");
    if (screen_name != null) {
      call.add_param ("screen_name", screen_name);
      this.screen_name = screen_name;
    } else {
      call.add_param ("user_id", this.id.to_string ());
    }
    call.add_param ("skip_status", "true");

    Json.Node? root_node = null;
    try {
      root_node = yield TweetUtils.load_threaded (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }

    bool values_changed = false;

    var root = root_node.get_object ();
    this.id = root.get_int_member ("id");
    if (this.name != root.get_string_member ("name")) {
      this.name = root.get_string_member ("name");
      values_changed = true;
    }
    if (this.screen_name != root.get_string_member ("screen_name")) {
      string old_screen_name = this.screen_name;
      this.screen_name = root.get_string_member ("screen_name");
      Utils.update_startup_account (old_screen_name, this.screen_name);
      values_changed = true;
    }

    Json.Array desc_urls = root.get_object_member ("entities").get_object_member ("description")
                                                              .get_array_member ("urls");
    var urls = new TextEntity[desc_urls.get_length ()];
    desc_urls.foreach_element ((arr, index, node) => {
      Json.Object obj = node.get_object ();
      Json.Array indices = obj.get_array_member ("indices");
      urls[index] = TextEntity () {
        from = (int)indices.get_int_element (0),
        to   = (int)indices.get_int_element (1),
        display_text = obj.get_string_member ("expanded_url"),
        target = null
      };
    });
    this.description = TextTransform.transform (root.get_string_member ("description"),
                                                urls,
                                                TransformFlags.EXPAND_LINKS);


    if (root.has_member ("profile_banner_url"))
      this.banner_url = root.get_string_member ("profile_banner_url");

    /* Website URL */
    if (root.get_object_member ("entities").has_member ("url")) {
      this.website = root.get_object_member ("entities").get_object_member ("url")
                     .get_array_member ("urls").get_object_element (0).get_string_member ("expanded_url");
    } else
      this.website = "";


    string avatar_url = root.get_string_member ("profile_image_url");
    values_changed |= yield update_avatar (avatar_url);

    if (values_changed) {
      if (this.db != null)
        this.save_info ();

      info_changed (this.screen_name,
                    this.name,
                    this.avatar_small,
                    this.avatar);
    }
  }

  public async void init_information () {
    var collect_obj = new Collect (4);
    collect_obj.finished.connect (() => {
      init_information.callback ();
    });

    query_user_info_by_screen_name.begin (null, () => {
      collect_obj.emit ();
    });

    load_id_array.begin (collect_obj, "1.1/friendships/no_retweets/ids.json", true, (obj, res) => {
      Json.Array? arr = load_id_array.end (res);
      if (arr != null) {
        this.set_disabled_rts (arr);
        collect_obj.emit ();
      }
    });
    load_id_array.begin (collect_obj, "1.1/blocks/ids.json", false, (obj, res) => {
      Json.Array? arr = load_id_array.end (res);
      if (arr != null) {
        this.set_blocked (arr);
        collect_obj.emit ();
      }
    });
    load_id_array.begin (collect_obj, "1.1/mutes/users/ids.json", false, (obj, res) => {
      Json.Array? arr = load_id_array.end (res);
      if (arr != null) {
        this.set_muted (arr);
        collect_obj.emit ();
      }
    });

    yield;
  }

  private async Json.Array? load_id_array (Collect collect_obj,
                                           string  function,
                                           bool    direct) {
    var call = this.proxy.new_call ();
    call.set_function (function);
    call.set_method ("GET");

    Json.Node? root = null;
    try {
      root = yield TweetUtils.load_threaded (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      collect_obj.emit ();
      return null;
    }

    if (direct)
      return root.get_array ();
    else
      return root.get_object ().get_array_member ("ids");
  }

  /**
   * Updates the account's avatar picture.
   * This means that the new avatar will be downloaded if necessary and
   * scaled appropriately.
   *
   * @param url The url of the (possibly) new avatar(optional).
   */
  private async bool update_avatar (string url = "") {
    string dest_path = Dirs.config (@"accounts/$(id)_small.png");
    string big_dest  = Dirs.config (@"accounts/$(id).png");



    if (url.length > 0 && url == this.avatar_url) {
      if (GLib.FileUtils.test (dest_path, GLib.FileTest.EXISTS) &&
          GLib.FileUtils.test (big_dest,  GLib.FileTest.EXISTS))
      return false;
    }

    debug ("Using %s to update the avatar(old: %s)", url, this.avatar_url);

    if (url.length > 0) {
      var msg = new Soup.Message ("GET", url);
      SOUP_SESSION.queue_message (msg, (_s, _msg) => {
        var data_stream = new MemoryInputStream.from_data (msg.response_body.data, GLib.g_free);
        string type = Utils.get_file_type (url);
        Gdk.Pixbuf pixbuf;
        try {
          pixbuf = new Gdk.Pixbuf.from_stream(data_stream);
          pixbuf.save(big_dest, type);
          data_stream.close ();
          double scale_x = 24.0 / pixbuf.get_width();
          double scale_y = 24.0 / pixbuf.get_height();
          var scaled_pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB,
                                             pixbuf.has_alpha, 8, 24, 24);
          pixbuf.scale(scaled_pixbuf, 0, 0, 24, 24, 0, 0, scale_x, scale_y, Gdk.InterpType.HYPER);
          scaled_pixbuf.save(dest_path, type);
          debug ("saving to %s", dest_path);
          this.avatar_small = Gdk.cairo_surface_create_from_pixbuf (scaled_pixbuf, 1, null);
          this.avatar = Gdk.cairo_surface_create_from_pixbuf (pixbuf, 1, null);
        } catch (GLib.Error e) {
          critical (e.message);
        }
        this.avatar_url = url;
        Corebird.db.update ("accounts").val ("avatar_url", url).where_eqi ("id", id).run ();
        update_avatar.callback ();
      });
      yield;
      return true;
    } else {
      critical ("Not implemented yet");
    }

    return false;
  }

  /**
   * Saves the account info both in the account's database and in the
   * global one.
   */
  public void save_info () {
    db.replace ("info").vali64 ("id", id)
                       .val ("screen_name", screen_name)
                       .val ("name", name)
                       .run ();
    Corebird.db.replace ("accounts").vali64 ("id", id)
                                    .val ("screen_name", screen_name)
                                    .val ("name", name)
                                    .val ("avatar_url", avatar_url)
                                    .run ();
  }

  /**
   * Load all the filters from the database.
   */
  private void load_filters () {
    this.db.select ("filters").cols ("content", "id")
              .order ("id").run ((cols) => {
      Filter f = new Filter (cols[0]);
      f.id = int.parse (cols[1]);
      filters.add (f);
      return true;
    });
  }

  public void add_filter (owned Filter f) {
    this.filters.add (f);
  }

  /**
   * Checks if any of the filters associated to this acount match
   * the given tweet.
   *
   * @param t The tweet to check for
   *
   * @return true iff at least one of the filters match, false otherwise.
   */
  public bool filter_matches (Tweet t) {
    if (t.source_tweet.author.id == this.id)
      return false;


    for (int i = 0; i < filters.length; i ++) {
      var f = this.filters.get (i);
      if (f.matches (t.get_real_text ())) {
        return true;
      }
    }
    return false;
  }

  public void set_friends (Json.Array friends_array) {
    this.friends = new int64[friends_array.get_length ()];
    debug ("Adding %d friends...", friends.length);
    for (int i = 0; i < friends_array.get_length (); i ++) {
      this.friends[i] = friends_array.get_int_element (i);
    }
  }

  public bool follows_id (int64 user_id) {
    foreach (int64 id in this.friends)
      if (id == user_id)
        return true;

    return false;
  }

  public void follow_id (int64 user_id) {
    this.friends.resize (this.friends.length + 1);
    this.friends[this.friends.length - 1] = user_id;
  }

  public void unfollow_id (int64 user_id) {
    if (this.friends == null || this.friends.length == 0) {
      warning ("friends == null");
      return;
    }

    int64[] new_friends = new int64[this.friends.length];

    int o = 0;
    bool found = false;
    for (int i = 0; i < this.friends.length; i++) {
      if (this.friends[i] == user_id) {
        found = true;
        continue;
      }
      new_friends[o] = this.friends[i];
      o ++;
    }
    if (found)
      new_friends.resize (new_friends.length - 1);
    this.friends = new_friends;
  }

  public void set_muted (Json.Array muted_array) {
    this.muted = new int64[muted_array.get_length ()];
    debug ("Add %d muted ids", this.muted.length);
    for (int i = 0; i < this.muted.length; i ++) {
      this.muted[i] = muted_array.get_int_element (i);
    }
  }

  public void mute_id (int64 id) {
    this.muted.resize (this.muted.length + 1);
    this.muted[this.muted.length - 1] = id;
  }

  public void unmute_id (int64 id) {
    if (this.muted == null || this.muted.length == 0) {
      warning ("muted == null");
      return;
    }
    int64[] new_muted = new int64[this.muted.length - 1];

    int o = 0;
    for (int i = 0; i < this.muted.length; i++) {
      if (this.muted[i] == id) {
        continue;
      }
      muted[o] = this.muted[i];
      o ++;
    }
    this.muted = new_muted;
  }

  public void set_blocked (Json.Array blocked_array) {
    this.blocked = new int64[blocked_array.get_length ()];
    debug ("Add %d blocked ids", this.blocked.length);
    for (int i = 0; i < this.blocked.length; i ++) {
      this.blocked[i] = blocked_array.get_int_element (i);
    }
  }

  public void block_id (int64 id) {
    this.blocked.resize (this.blocked.length + 1);
    this.blocked[this.blocked.length - 1] = id;
  }

  public void unblock_id (int64 id) {
    if (this.blocked == null || this.blocked.length == 0) {
      warning ("blocked == null");
      return;
    }
    int64[] new_blocked = new int64[this.blocked.length - 1];

    int o = 0;
    for (int i = 0; i < this.blocked.length; i++) {
      if (this.blocked[i] == id) {
        continue;
      }
      blocked[o] = this.blocked[i];
      o ++;
    }
    this.blocked = new_blocked;
  }

  public void set_disabled_rts (Json.Array disabled_rts_array) {
    this.disabled_rts = new int64[disabled_rts_array.get_length ()];
    debug ("Add %d disabled_rts ids", this.disabled_rts.length);
    for (int i = 0; i < this.disabled_rts.length; i ++) {
      this.disabled_rts[i] = disabled_rts_array.get_int_element (i);
    }
  }

  public void add_disabled_rts_id (int64 user_id) {
    this.disabled_rts.resize (this.disabled_rts.length + 1);
    this.disabled_rts[this.disabled_rts.length - 1] = id;
  }

  public void remove_disabled_rts_id (int64 user_id) {
    if (this.disabled_rts == null || this.disabled_rts.length == 0) {
      warning ("disabled_rts == null");
      return;
    }
    int64[] new_disabled_rts = new int64[this.disabled_rts.length - 1];

    int o = 0;
    for (int i = 0; i < this.disabled_rts.length; i++) {
      if (this.disabled_rts[i] == id) {
        continue;
      }
      disabled_rts[o] = this.disabled_rts[i];
      o ++;
    }
    this.disabled_rts = new_disabled_rts;
  }

  public bool blocked_or_muted (int64 user_id) {
    foreach (int64 id in this.muted)
      if (id == user_id)
        return true;

    foreach (int64 id in this.blocked)
      if (id == user_id)
        return true;

    return false;
  }

  /** Static stuff ********************************************************************/
  private static GLib.GenericArray<Account>? accounts = null;

  public static Account get_nth (uint index) {
    if (GLib.unlikely (accounts == null))
      lookup_accounts ();

    return accounts.get (index);
  }

  public static uint get_n () {
    if (GLib.unlikely (accounts == null))
      lookup_accounts ();

    return accounts.length;
  }

  /**
   * Look up the accounts. Each account has a <id>.db in ~/.corebird/accounts/
   * The accounts are initialized with only their screen_name and their ID.
   */
  private static void lookup_accounts () {
    assert (accounts == null);
    accounts = new GLib.GenericArray<Account> ();
    Corebird.db.select ("accounts").cols ("id", "screen_name", "name", "avatar_url").run ((vals) => {
      Account acc = new Account (int64.parse(vals[0]), vals[1], vals[2]);
      acc.avatar_url = vals[3];
      acc.load_avatar ();
      accounts.add (acc);
      return true;
    });
  }

  /**
   * Adds the given account to the end of the current account list.
   *
   * @param acc The account to add.
   */
  public static void add_account (Account acc) {
    accounts.add (acc);
  }

  /**
   * Removes the acccunt with th given screen name from the account list.
   *
   * @param screen_name The screen name of the account to remove.
   */
  public static void remove_account (string screen_name) {
    if (GLib.unlikely (accounts == null))
      lookup_accounts ();

    for (uint i = 0; i < accounts.length; i ++) {
      var a = accounts.get (i);
      if (a.screen_name == screen_name) {
        accounts.remove (a);
        return;
      }
    }
  }

  /**
   * Returns an unowned reference to the account with the given screen name.
   *
   * @param screen_name The screen name of the account to return
   * @return An unowned reference to the account object with the given screen name or
   *         null of no such instance could be found.
   */
  public static unowned Account? query_account (string screen_name) {
    if (GLib.unlikely (accounts == null))
      lookup_accounts ();

    for (uint i = 0; i < accounts.length; i ++) {
      unowned Account a = accounts.get (i);

      if (screen_name == a.screen_name)
        return a;
    }
    return null;
  }

  public static unowned Account? query_account_by_id (int64 id) {
    if (GLib.unlikely (accounts == null))
      lookup_accounts ();

    for (uint i = 0; i < accounts.length; i ++) {
      unowned Account a = accounts.get (i);
      if (id == a.id)
        return a;
    }
    return null;
  }
}
