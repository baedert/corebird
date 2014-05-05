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
  public int64 id                 {public get; private set;}
  public Sql.Database db          {public get; private set;}
  public string screen_name       {public get; private set;}
  public string name              {public get; private set;}
  public string avatar_url        {public get; public  set;}
  public Gdk.Pixbuf avatar_small  {public get; private set;}
  public Gdk.Pixbuf avatar        {public get; private set;}
  public Rest.OAuthProxy proxy    {public get; private set;}
  public UserStream user_stream   {public get; private set;}
  public UserCounter user_counter {public get; private set;}
  public Gee.ArrayList<Filter> filters;

  public Account (int64 id, string screen_name, string name) {
    this.id = id;
    this.screen_name = screen_name;
    this.name = name;
    this.filters = new Gee.ArrayList<Filter> ();
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
                                Sql.ACCOUNTS_INIT_FILE);
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
    this.user_stream = new UserStream ("@"+screen_name);
    if (load_secrets) {
      init_database ();
      db.select ("common").cols ("token", "token_secret").run ((vals) => {
        proxy.token = user_stream.token = vals[0];
        proxy.token_secret = user_stream.token_secret = vals[1];
        return false; //stop
      });
    }
  }

  /**
   * Loads the small and normally sized avatars from disk.
   * Normal: accounts/ID.png
   * Small:  accounts/ID_small.png
   */
  public void load_avatar () {
    string small_path = Dirs.config (@"accounts/$(id)_small.png");
    string path = Dirs.config (@"accounts/$(id).png");
    try {
      this.avatar_small = new Gdk.Pixbuf.from_file (small_path);
      this.avatar = new Gdk.Pixbuf.from_file (path);
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }

  /**
   * Download the appropriate user info from the Twitter server,
   * updating the local information stored in this class' local variables.
   * (Means, you need to call save_info to actually save it persistently)
   *
   * @param screen_name The screen name to use for the API call.
   */
  public async void query_user_info_by_scren_name (string screen_name) {
    this.screen_name = screen_name;
    var call = proxy.new_call ();
    call.set_function ("1.1/users/show.json");
    call.set_method ("GET");
    call.add_param ("screen_name", screen_name);
    call.invoke_async.begin (null, (obj, res) => {
      try{call.invoke_async.end (res);} catch (GLib.Error e) {
        if (e.message.down() == "unauthorized") {
          Utils.show_error_dialog ("Unauthorized");
        }
        critical (e.message);
        return;
      }
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
      }
      var root = parser.get_root ().get_object ();
      this.id = root.get_int_member ("id");
      this.name = root.get_string_member ("name");
      this.screen_name = root.get_string_member ("screen_name");
      string avatar_url = root.get_string_member ("profile_image_url");
      update_avatar.begin (avatar_url);
      query_user_info_by_scren_name.callback();
      debug ("Name: %s", name);
    });

    yield;
  }

  /**
   * Updates the account's avatar picture.
   * This means that the new avatar will be downloaded if necessary and
   * scaled appropriately.
   *
   * @param url The url of the (possibly) new avatar(optional).
   */
  public async void update_avatar (string url = "") {
    if (url.length > 0 && url == this.avatar_url)
      return;

    debug ("Using %s to update the avatar(old: %s)", url, this.avatar_url);

    if (url.length > 0) {
      var session = new Soup.Session ();
      var msg = new Soup.Message ("GET", url);
      session.send_message (msg);
      var data_stream = new MemoryInputStream.from_data ((owned)msg.response_body.data, null);
      string type = Utils.get_file_type (url);
      string dest_path = Dirs.config (@"accounts/$(id)_small.png");
      string big_dest  = Dirs.config (@"accounts/$(id).png");
      Gdk.Pixbuf pixbuf;
      try {
        pixbuf = new Gdk.Pixbuf.from_stream(data_stream);
        pixbuf.save(big_dest, type);
        double scale_x = 24.0 / pixbuf.get_width();
        double scale_y = 24.0 / pixbuf.get_height();
        var scaled_pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB,
                                           pixbuf.has_alpha, 8, 24, 24);
        pixbuf.scale(scaled_pixbuf, 0, 0, 24, 24, 0, 0, scale_x, scale_y, Gdk.InterpType.HYPER);
        scaled_pixbuf.save(dest_path, type);
        debug ("saving to %s", dest_path);
        this.avatar_small = scaled_pixbuf;
      } catch (GLib.Error e) {
        critical (e.message);
      }
      this.avatar_url = url;
      Corebird.db.update ("accounts").val ("avatar_url", url).where_eqi ("id", id).run ();
    } else {
      critical ("Not implemented yet");
    }
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

  public bool filter_matches (Tweet t) {
    if (t.user_id == this.id)
      return false;


    foreach (Filter f in filters) {
      if (f.matches (t.get_real_text ())) {
        return true;
      }
    }
    return false;
  }

  /** Static stuff ********************************************************************/
  private static GLib.SList<Account> accounts = null;

  /**
   * Simply returns a list of user-specified accounts.
   * The list is lazily loaded from the database
   *
   * @return A singly-linked list of accounts
   */
  public static unowned GLib.SList<Account> list_accounts () {
    if (accounts == null)
      lookup_accounts ();
    return accounts;
  }
  /**
   * Look up the accounts. Each account has a <id>.db in ~/.corebird/accounts/
   * The accounts are initialized with only their screen_name and their ID.
   */
  private static void lookup_accounts () {
    accounts = new GLib.SList<Account> ();
    Corebird.db.select ("accounts").cols ("id", "screen_name", "name", "avatar_url").run ((vals) => {
      Account acc = new Account (int64.parse(vals[0]), vals[1], vals[2]);
      acc.avatar_url = vals[3]; // O(n^2)
      accounts.append (acc);
      return true;
    });
  }

  /**
   * Adds the given account to the end of the current account list.
   *
   * @param acc The account to add.
   */
  public static void add_account (Account acc) {
    accounts.append (acc);
  }

  /**
   * Removes the acccunt with th given screen name from the account list.
   *
   * @param screen_name The screen name of the account to remove.
   */
  public static void remove_account (string screen_name) {
    foreach(Account a in accounts) {
      if(a.screen_name == screen_name){
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
    foreach (unowned Account a in accounts) {
      if (screen_name == a.screen_name)
        return a;
    }
    return null;
  }
}
