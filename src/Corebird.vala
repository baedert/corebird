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

public class Corebird : Gtk.Application {
  public static Sql.Database db;
  public static GLib.Menu account_menu;
  public static SnippetManager snippet_manager;
  public signal void account_added (Account acc);
  public signal void account_removed (Account acc);
  public signal void account_window_changed (int64? old_id, int64 new_id);

  const GLib.ActionEntry[] app_entries = {
    {"show-settings",     show_settings_activated         },
    {"show-shortcuts",    show_shortcuts_activated        },
    {"quit",              quit_application                },
    {"show-about-dialog", about_activated                 },
    {"show-dm-thread",    show_dm_thread,          "(xx)" },
    {"show-window",       show_window,             "x"    },
    {"post-json",         post_json,               "(ss)" },
    {"print-debug",       print_debug,                    }
  };



  public Corebird () throws GLib.Error {
    GLib.Object(application_id:   "org.baedert.corebird",
                flags:            ApplicationFlags.HANDLES_COMMAND_LINE);
                //register_session: true);
    snippet_manager = new SnippetManager ();
  }

  public override int command_line (ApplicationCommandLine cmd) {
    this.hold ();
    string? compose_screen_name = null;


    OptionEntry[] options = new OptionEntry[2];
    options[0] = {"tweet", 't', 0, OptionArg.STRING, ref compose_screen_name,
            "Shows only the 'compose tweet' window for the given account, nothing else.", "SCREEN_NAME"};
    options[1] = {null};

    string[] args = cmd.get_arguments ();
    string*[] _args = new string[args.length];
    for (int i = 0; i < args.length; i++) {
      _args[i] = args[i];
    }

    try {
      var opt_context = new OptionContext ("");
      opt_context.set_help_enabled (true);
      opt_context.add_main_entries (options, Config.GETTEXT_PACKAGE);
      opt_context.add_group (Gtk.get_option_group (false));
#if VIDEO
      opt_context.add_group (Gst.init_get_option_group ());
#endif
      unowned string[] tmp = _args;
      opt_context.parse (ref tmp);
    } catch (GLib.OptionError e) {
      cmd.print ("Use --help to see available options\n");
      quit ();
      return -1;
    }

    open_startup_windows (compose_screen_name);

    this.release ();
    return 0;
  }

  public override void activate () {
    open_startup_windows (null);
  }

  private void show_settings_activated () {
    /* We don't set the settings dialog transient to
       any window because we already save its size */
    var dialog = new SettingsDialog (this);
    dialog.show ();
  }

  private void about_activated () {
    var active_window = get_active_window ();
    var ad = new AboutDialog ();
    ad.modal = true;
    ad.set_transient_for (active_window);
    ad.show_all ();
  }

  private void show_shortcuts_activated () {
    if (Gtk.MAJOR_VERSION == 3 && Gtk.MINOR_VERSION >= 19) {
      var builder = new Gtk.Builder.from_resource ("/org/baedert/corebird/ui/shortcuts-window.ui");
      var shortcuts_window = (Gtk.Window) builder.get_object ("shortcuts_window");
      shortcuts_window.show ();
    } else {
      warning ("The shortcuts window is only available in gtk+ >= 3.20, version is %d.%d",
               Gtk.MAJOR_VERSION, Gtk.MINOR_VERSION);
    }
  }

  public override void startup () {
    base.startup ();

    new LazyMenuButton ();

#if DEBUG
    GLib.Environment.set_variable ("G_MESSAGES_DEBUG", "all", true);
#endif

    Dirs.create_dirs ();
    debug ("startup");
    Corebird.db = new Sql.Database (Dirs.config ("Corebird.db"),
                                    Sql.COREBIRD_INIT_FILE,
                                    Sql.COREBIRD_SQL_VERSION);

    // Setup gettext
    GLib.Intl.setlocale(GLib.LocaleCategory.ALL, Config.DATADIR + "/locale");
    GLib.Intl.bindtextdomain (Config.GETTEXT_PACKAGE, null);
    GLib.Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);

    // Construct app menu
    Gtk.Builder builder = new Gtk.Builder ();
    try {
      builder.add_from_resource ("/org/baedert/corebird/ui/menu.ui");
    } catch (GLib.Error e) {
      critical (e.message);
    }
    GLib.MenuModel app_menu = (MenuModel)builder.get_object ("app-menu");
    var acc_menu = app_menu.get_item_link (0, "section");
    account_menu = new GLib.Menu ();

    Utils.load_custom_css ();
    Utils.load_custom_icons ();
    Utils.init_soup_session ();
    Twitter.get ().init ();

    unowned GLib.SList<Account> accounts = Account.list_accounts ();
    foreach (var acc in accounts) {
      acc.info_changed.connect (account_info_changed);
      var show_win_action = new SimpleAction ("show-" + acc.id.to_string (), null);
      show_win_action.activate.connect (()=> {
        add_window_for_account (acc);
      });
      add_action(show_win_action);

      var mi = create_accout_menu_item (acc);
      account_menu.append_item (mi);
    }
    ((GLib.Menu)acc_menu).append_submenu (_("Open Account"), account_menu);

    this.set_app_menu (app_menu);



    this.set_accels_for_action ("win.compose-tweet", {Settings.get_accel ("compose-tweet")});
    this.set_accels_for_action ("win.toggle-sidebar", {Settings.get_accel ("toggle-sidebar")});
    this.set_accels_for_action ("win.switch-page(0)", {"<Alt>1"});
    this.set_accels_for_action ("win.switch-page(1)", {"<Alt>2"});
    this.set_accels_for_action ("win.switch-page(2)", {"<Alt>3"});
    this.set_accels_for_action ("win.switch-page(3)", {"<Alt>4"});
    this.set_accels_for_action ("win.switch-page(4)", {"<Alt>5"});
    this.set_accels_for_action ("win.switch-page(5)", {"<Alt>6"});
    this.set_accels_for_action ("win.switch-page(6)", {"<Alt>7"});
    this.set_accels_for_action ("win.switch-page(7)", {"<Alt>8"});
    this.set_accels_for_action ("app.show-settings", {Settings.get_accel ("show-settings")});
    this.set_accels_for_action ("app.quit", {"<Primary>Q"});
    this.set_accels_for_action ("app.show-shortcuts", {"<Primary>question", "<Primary>F1"});
    this.set_accels_for_action ("win.show-account-dialog", {Settings.get_accel ("show-account-dialog")});
    this.set_accels_for_action ("win.show-account-list", {Settings.get_accel ("show-account-list")});

    // TweetInfoPage
    this.set_accels_for_action ("tweet.reply",    {"r"});
    this.set_accels_for_action ("tweet.favorite", {"f"});
#if DEBUG
    this.set_accels_for_action ("app.print-debug", {"<Primary>D"});
#endif

    this.add_action_entries (app_entries, this);

    // If the user wants the dark theme, apply it
    var gtk_s = Gtk.Settings.get_default ();
    if (Settings.use_dark_theme ()) {
      gtk_s.gtk_application_prefer_dark_theme = true;
    }

    if (gtk_s.gtk_decoration_layout.contains ("menu")) {
      gtk_s.gtk_decoration_layout = gtk_s.gtk_decoration_layout.replace ("menu", "");
    }

  }

  public override void shutdown () {
    base.shutdown();
  }

  private GLib.MenuItem create_accout_menu_item (Account account) {
      var mi = new GLib.MenuItem ("@" + account.screen_name.replace ("_", "__"),
                                  "app.show-" + account.id.to_string ());
      mi.set_attribute_value ("user-id", new GLib.Variant.int64 (account.id));
      return mi;
  }

  private void account_info_changed (Account    source,
                                     string     screen_name,
                                     string     s,
                                     Cairo.Surface a,
                                     Cairo.Surface b) {
    for (int i = 0; i < account_menu.get_n_items (); i++){
      int64 item_id = account_menu.get_item_attribute_value (i,
                                                             "user-id",
                                                             GLib.VariantType.INT64).get_int64 ();
      if (item_id == source.id) {
        var new_menu_item = create_accout_menu_item (source);
        account_menu.remove (i);
        account_menu.insert_item (i, new_menu_item);
        return;
      }
    }

  }


  /**
   * Open startup windows.
   * Semantics: Open a window for every account in the startup-accounts array.
   * If that array is empty, look at all the account and if there is one, open that one.
   * If there is none, open a MainWindow with a null account.
   */
  private void open_startup_windows (string? compose_screen_name = null) { // {{{
    if (compose_screen_name != null) {
      Account? acc = Account.query_account (compose_screen_name);
      if (acc == null) {
        critical ("No account named `%s` is configured. Exiting.",
                  compose_screen_name);
        return;
      }
      // TODO: Handle the 'avatar not yet cached' case
      acc.init_proxy ();
      acc.query_user_info_by_screen_name.begin ();
      var cw = new ComposeTweetWindow (null, acc, null,
                                       ComposeTweetWindow.Mode.NORMAL);
      cw.show();
      this.add_window (cw);
      return;
    }

    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    /* Handle the stupid case where only one item is in the array but it's empty */
    if (startup_accounts.length == 1 && startup_accounts[0] == "")
      startup_accounts.resize (0);


    uint n_accounts = Account.list_accounts ().length ();

    if (startup_accounts.length == 0) {
      if (n_accounts == 1) {
        add_window_for_screen_name (Account.list_accounts ().nth_data (0).screen_name);
      } else if (n_accounts == 0) {
        var window = new MainWindow (this, null);
        add_window (window);
        window.show_all ();
      } else {
        /* We have multiple configured accounts but still none in autostart.
           This should never happen but we handle the case anyway by just opening
           the first one. */
        add_window_for_screen_name (Account.list_accounts ().nth_data (0).screen_name);
      }
    } else {
      bool opened_window = false;
      foreach (string account in startup_accounts) {
        if (!is_window_open_for_screen_name (account, null)) {
          if (add_window_for_screen_name (account)) {
            opened_window = true;
          }
        }
      }
      /* If we did not open any window at all since all windows for every account
         in the startups-account array were already open, just open a new window with a null account */
      if (!opened_window) {
        if (n_accounts > 0) {
          /* Check if *any* of the configured accounts (not just startup-accounts)
             is not opened in a window */
          foreach (Account account in Account.list_accounts ())
            if (!is_window_open_for_user_id (account.id, null)) {
              add_window_for_account (account);
              return;
            }
        }
        foreach (Gtk.Window w in this.get_windows ())
          if (((MainWindow)w).account.screen_name == Account.DUMMY) {
            return;
          }

        var m = new MainWindow (this, null);
        add_window (m);
        m.show_all ();
      }
    }
  } // }}}

  /**
   * Adds a new MainWindow instance with the account that
   * has the given screen name.
   * Note that this only works if the account is already properly
   * set up and won't warn or fail if if isn't.
   *
   * @param screen_name The screen name of the account do add a
   *                    MainWindow for.
   *
   * @return true if a window has been opened, false otherwise
   */
  public bool add_window_for_screen_name (string screen_name) {
    unowned GLib.SList<Account> accs = Account.list_accounts ();
    foreach (Account a in accs) {
      if (a.screen_name == screen_name) {
        add_window_for_account (a);
        return true;
      }
    }
    warning ("Could not add window for account '%s'", screen_name);
    return false;
  }

  public void add_window_for_account (Account account) {
    var window = new MainWindow (this, account);
    this.add_window (window);
    window.show_all ();
  }

  /**
   * Checks if there's currently a MainWindow instance open that has a
   * reference to the account with the given screen name.
   * (This makes a linear search over all open windows, with a text comparison
   * in each iteration)
   *
   * @param screen_name The screen name to search for
   * @return TRUE if a window with the account associated to the given
   *         screen name is open, FALSE otherwise.
   */
  public bool is_window_open_for_screen_name (string screen_name,
                                              out MainWindow? window = null) {
    unowned GLib.List<weak Gtk.Window> windows = this.get_windows ();
    foreach (Gtk.Window win in windows) {
      if (win is MainWindow) {
        if (((MainWindow)win).account.screen_name == screen_name) {
          window = (MainWindow)win;
          return true;
        }
      }
    }
    window = null;
    return false;
  }

  public bool is_window_open_for_user_id (int64 user_id,
                                          out MainWindow? window = null) {
    unowned GLib.List<weak Gtk.Window> windows = this.get_windows ();
    foreach (Gtk.Window win in windows) {
      if (win is MainWindow) {
        if (((MainWindow)win).account.id == user_id) {
          window = (MainWindow)win;
          return true;
        }
      }
    }
    window = null;
    return false;
  }

  /**
   * Quits the application, saving all open windows and their geometries.
   */
  private void quit_application () {
    unowned GLib.List<weak Gtk.Window> windows = this.get_windows ();
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    if (startup_accounts.length == 1 && startup_accounts[0] == "")
      startup_accounts.resize (0);


    if (startup_accounts.length != 0) {
      base.quit ();
      return;
    }

    string[] account_names = new string[windows.length ()];
    int index = 0;
    foreach (var win in windows) {
      if (!(win is MainWindow))
        continue;
      var mw = (MainWindow)win;
      string screen_name = mw.account.screen_name;
      mw.save_geometry ();
      account_names[index] = screen_name;
      index ++;
    }
    account_names.resize (index + 1);
    Settings.get ().set_strv ("startup-accounts", account_names);
    base.quit ();
  }


  /********************************************************/

  private void show_dm_thread (GLib.SimpleAction a, GLib.Variant? value) {
    // Values: Account id, sender_id
    int64 account_id = value.get_child_value (0).get_int64 ();
    int64 sender_id  = value.get_child_value (1).get_int64 ();
    MainWindow main_window;
    if (is_window_open_for_user_id (account_id, out main_window)) {
      var bundle = new Bundle ();
      bundle.put_int64 ("sender_id", sender_id);
      main_window.main_widget.switch_page (Page.DM, bundle);
      main_window.present ();
    } else
      warning ("Window for Account %s is not open, abort.", account_id.to_string ());
  }

  private void show_window (GLib.SimpleAction a, GLib.Variant? value) {
    int64 user_id = value.get_int64 ();
    MainWindow main_window;
    if (is_window_open_for_user_id (user_id, out main_window))
      main_window.present ();
    else
      warning ("TODO: Implement");
  }

  private void print_debug (GLib.SimpleAction a, GLib.Variant? v) {
#if DEBUG
    Twitter.get ().debug ();
#endif
  }

  private void post_json (GLib.SimpleAction a, GLib.Variant? value) {
    string screen_name = value.get_child_value (0).get_string ();
    string json = value.get_child_value (1).get_string ();
    json += "\r\n";

    MainWindow? win = null;
    if (is_window_open_for_screen_name (screen_name, out win)) {
      if (win.account == null) {
        error ("account is null");
      }
      var fake_call = win.account.proxy.new_call ();

      win.account.user_stream.parse_data_cb (fake_call,
                                             json,
                                             json.length,
                                             null);

    } else
      error ("Window for %s is not open, so account isn't active.", screen_name);
  }


}
