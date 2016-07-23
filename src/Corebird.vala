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
  public static SnippetManager snippet_manager;
  public signal void account_added (Account acc);
  public signal void account_removed (Account acc);
  public signal void account_window_changed (int64? old_id, int64 new_id);

  private SettingsDialog? settings_dialog = null;
  private GLib.GenericArray<Account> active_accounts;
  private bool started_as_service = false;

  const GLib.ActionEntry[] app_entries = {
    {"show-settings",     show_settings_activated         },
    {"show-shortcuts",    show_shortcuts_activated        },
    {"quit",              quit_application                },
    {"show-about-dialog", about_activated                 },
    {"show-dm-thread",    show_dm_thread,          "(xx)" },
    {"show-window",       show_window,             "x"    },
#if DEBUG
    {"post-json",         post_json,               "(ss)" },
    {"print-debug",       print_debug,                    },
#endif
  };



  public Corebird () {
    GLib.Object(application_id:   "org.baedert.corebird",
                flags:            ApplicationFlags.HANDLES_COMMAND_LINE);
                //register_session: true);
    snippet_manager = new SnippetManager ();
    active_accounts = new GLib.GenericArray<Account> ();
    db = new Sql.Database (Dirs.config ("Corebird.db"),
                           Sql.COREBIRD_INIT_FILE,
                           Sql.COREBIRD_SQL_VERSION);
  }

  public override int command_line (ApplicationCommandLine cmd) {
    string? compose_screen_name = null;
    bool start_service = false;
    bool stop_service = false;
    bool print_startup_accounts = false;

    OptionEntry[] options = new OptionEntry[5];
    options[0] = {"tweet", 't', 0, OptionArg.STRING, ref compose_screen_name,
                  "Shows only the 'compose tweet' window for the given account, nothing else.", "SCREEN_NAME"};
    options[1] = {"start-service", 's', 0, OptionArg.NONE, ref start_service,
                  "Start service", null};
    options[2] = {"stop-service", 'p', 0, OptionArg.NONE, ref stop_service,
                  "Stop service, if it has been started as a service", null};
    options[3] = {"print-startup-accounts", 'a', 0, OptionArg.NONE, ref print_startup_accounts,
                  "Print configured startup accounts", null};

    options[4] = {null};

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

    if (stop_service && start_service) {
      error ("Can't stop and start service at the same time.");
    }


    if (stop_service) {
      if (this.started_as_service) {
        debug ("Stopping service");
        /* Starting as a service adds an extra hold() */
        this.release ();
      } else {
        warning ("--stop-service passed, but corebird has not been started as a service");
      }
    } else if (print_startup_accounts) {
      string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
      foreach (unowned string acc in startup_accounts) {
        stdout.printf ("%s\n", acc);
      }
    } else if (start_service && !this.started_as_service) {
      this.started_as_service = true;
      this.activate ();
    } else {
      open_startup_windows (compose_screen_name);
    }

    return 0;
  }

  public override void activate () {
    if (started_as_service) {
      this.hold ();

      string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
      if (startup_accounts.length == 1 && startup_accounts[0] == "")
        startup_accounts.resize (0);

      debug ("Configured startup accounts: %d", startup_accounts.length);
      uint n_accounts = Account.get_n ();
      debug ("Configured accounts: %u", n_accounts);

      foreach (unowned string screen_name in startup_accounts) {
        Account? acc = Account.query_account (screen_name);
        if (acc != null) {
          debug ("Service: Starting account %s...", screen_name);
          this.start_account (acc);
        } else {
          warning ("Invalid startup account: '%s'", screen_name);
        }
      }
    } else {
      open_startup_windows (null);
    }
  }

  private void show_settings_activated () {
    /* We don't set the settings dialog transient to
       any window because we already save its size */
    if (this.settings_dialog != null)
      return;

    var dialog = new SettingsDialog (this);
    var action = (GLib.SimpleAction)this.lookup_action ("show-settings");
    action.set_enabled (false);
    dialog.delete_event.connect (() => {
      action.set_enabled (true);
      this.settings_dialog = null;
      return Gdk.EVENT_PROPAGATE;
    });
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
    // TODO: Remove this once the required gtk version is >= 3.20
    if (Gtk.get_major_version () == 3 && Gtk.get_minor_version () >= 19) {
      var builder = new Gtk.Builder.from_resource ("/org/baedert/corebird/ui/shortcuts-window.ui");
      var shortcuts_window = (Gtk.Window) builder.get_object ("shortcuts_window");
      shortcuts_window.show ();
    } else {
      warning ("The shortcuts window is only available in gtk+ >= 3.20, version is %u.%u",
               Gtk.get_major_version (), Gtk.get_minor_version ());
    }
  }

  public override void startup () {
    base.startup ();
    this.set_resource_base_path ("/org/baedert/corebird");

    new ComposeImageManager ();
    new LazyMenuButton ();

#if DEBUG
    GLib.Environment.set_variable ("G_MESSAGES_DEBUG", "all", true);
#endif

    Dirs.create_dirs ();
    debug ("startup");
    // Setup gettext
    GLib.Intl.setlocale (GLib.LocaleCategory.ALL, Config.DATADIR + "/locale");
    GLib.Intl.bindtextdomain (Config.GETTEXT_PACKAGE, null);
    GLib.Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    GLib.Intl.textdomain (Config.GETTEXT_PACKAGE);



    Utils.load_custom_css ();
    Utils.load_custom_icons ();
    Utils.init_soup_session ();
    Twitter.get ().init ();

    this.set_accels_for_action ("win.compose-tweet", {Settings.get_accel ("compose-tweet")});
    this.set_accels_for_action ("win.toggle-sidebar", {Settings.get_accel ("toggle-sidebar")});
    this.set_accels_for_action ("win.switch-page(0)", {"<Alt>1"});
    this.set_accels_for_action ("win.switch-page(1)", {"<Alt>2"});
    this.set_accels_for_action ("win.switch-page(2)", {"<Alt>3"});
    this.set_accels_for_action ("win.switch-page(3)", {"<Alt>4"});
    this.set_accels_for_action ("win.switch-page(4)", {"<Alt>5"});
    this.set_accels_for_action ("win.switch-page(5)", {"<Alt>6"});
    this.set_accels_for_action ("win.switch-page(6)", {"<Alt>7"});
    this.set_accels_for_action ("app.show-settings", {Settings.get_accel ("show-settings")});
    this.set_accels_for_action ("app.quit", {"<Primary>Q"});
    this.set_accels_for_action ("app.show-shortcuts", {"<Primary>question", "<Primary>F1"});
    this.set_accels_for_action ("win.show-account-dialog", {Settings.get_accel ("show-account-dialog")});
    this.set_accels_for_action ("win.show-account-list", {Settings.get_accel ("show-account-list")});
    this.set_accels_for_action ("win.previous", {"<Alt>Left", "Back"});
    this.set_accels_for_action ("win.next", {"<Alt>Right", "Forward"});

    // TweetInfoPage
    this.set_accels_for_action ("tweet.reply",    {"r"});
    this.set_accels_for_action ("tweet.favorite", {"f"});
#if DEBUG
    this.set_accels_for_action ("app.print-debug", {"<Primary>D"});
#endif

    this.add_action_entries (app_entries, this);

    // TODO: Remove this once the required gtk version is >= 3.20
    if (Gtk.get_major_version () == 3 && Gtk.get_minor_version () < 19) {
      ((GLib.SimpleAction)this.lookup_action ("show-shortcuts")).set_enabled (false);
    }

    // If the user wants the dark theme, apply it
    var gtk_s = Gtk.Settings.get_default ();
    if (Settings.use_dark_theme ()) {
      gtk_s.gtk_application_prefer_dark_theme = true;
    }

    if (gtk_s.gtk_decoration_layout.contains ("menu")) {
      gtk_s.gtk_decoration_layout = gtk_s.gtk_decoration_layout.replace ("menu", "");
    }

  }

  /**
   * Open startup windows.
   * Semantics: Open a window for every account in the startup-accounts array.
   * If that array is empty, look at all the account and if there is one, open that one.
   * If there is none, open a MainWindow with a null account.
   */
  private void open_startup_windows (string? compose_screen_name = null) {
    if (compose_screen_name != null) {
      Account? acc = Account.query_account (compose_screen_name);
      if (acc == null) {
        critical ("No account named `%s` is configured. Exiting.",
                  compose_screen_name);
        return;
      }
      acc.init_proxy ();
      acc.query_user_info_by_screen_name.begin ();
      var cw = new ComposeTweetWindow (null, acc, null,
                                       ComposeTweetWindow.Mode.NORMAL);
      cw.show ();
      this.add_window (cw);
      return;
    }

    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    /* Handle the stupid case where only one item is in the array but it's empty */
    if (startup_accounts.length == 1 && startup_accounts[0] == "")
      startup_accounts.resize (0);

    uint n_accounts = Account.get_n ();

    if (startup_accounts.length == 0) {
      if (n_accounts == 1) {
        add_window_for_screen_name (Account.get_nth (0).screen_name);
      } else if (n_accounts == 0) {
        var window = new MainWindow (this, null);
        add_window (window);
        window.show_all ();
      } else {
        /* We have multiple configured accounts but still none in autostart.
           This should never happen but we handle the case anyway by just opening
           the first one. */
        add_window_for_screen_name (Account.get_nth (0).screen_name);
      }
    } else {
      bool opened_window = false;
      foreach (unowned string account in startup_accounts) {
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
          for (uint i = 0; i < Account.get_n (); i ++) {
            var account = Account.get_nth (i);
            if (!is_window_open_for_user_id (account.id, null)) {
              add_window_for_account (account);
              return;
            }
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
  }

  /**
   * Adds a new MainWindow instance with the account that
   * has the given screen name.
   * Note that this only works if the account is already properly
   * set up and won't warn or fail if if isn't.
   *
   * @param screen_name The screen name of the account to add a
   *                    MainWindow for.
   *
   * @return true if a window has been opened, false otherwise
   */
  public bool add_window_for_screen_name (string screen_name) {
    Account? acc = Account.query_account (screen_name);
    if (acc != null) {
      add_window_for_account (acc);
      return true;
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

  public void start_account (Account acc) {
    for (int i = 0; i < this.active_accounts.length; i ++) {
      var account = this.active_accounts.get (i);
      if (acc == account) {
        /* This can very well happen when we've been started as a service */
        debug ("Account %s is already active", acc.screen_name);
        return;
      }
    }

    acc.init_proxy ();
    acc.user_stream.start ();
    acc.init_information.begin ();

    this.active_accounts.add (acc);
  }

  public void stop_account (Account acc) {
    bool found = false;
    for (int i = 0; i < this.active_accounts.length; i ++) {
      var account = this.active_accounts.get (i);
      if (account == acc) {
        found = true;
        break;
      }
    }

    if (!found) {
      warning ("Can't stop account %s since it's not in the list of active accounts",
               acc.screen_name);
      return;
    }

    /* If we got started as a service and the given account is in the
     * startup accounts, don't stop it here */
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    if (this.started_as_service && acc.screen_name in startup_accounts) {
      // Don't stop account
    } else {
      acc.uninit ();
      this.active_accounts.remove (acc);
    }
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
    } else {
      var account = Account.query_account_by_id (account_id);
      if (account == null) {
        /* Security measure, should never happen. */
        critical ("No account with id %s found", account_id.to_string ());
        return;
      }
      main_window = new MainWindow (this, account);
      this.add_window (main_window);
      var bundle = new Bundle ();
      bundle.put_int64 ("sender_id", sender_id);
      main_window.main_widget.switch_page (Page.DM, bundle);

      main_window.show_all ();
    }
  }

  private void show_window (GLib.SimpleAction a, GLib.Variant? value) {
    int64 user_id = value.get_int64 ();
    MainWindow main_window;
    if (is_window_open_for_user_id (user_id, out main_window)) {
      main_window.present ();
    } else {
      var account = Account.query_account_by_id (user_id);
      if (account == null) {
        /* Security measure, should never happen. */
        critical ("No account with id %s found", user_id.to_string ());
        return;
      }
      main_window = new MainWindow (this, account);
      this.add_window (main_window);
      main_window.show_all ();
    }
  }

#if DEBUG
  private void print_debug (GLib.SimpleAction a, GLib.Variant? v) {
    Twitter.get ().debug ();
  }

  private void post_json (GLib.SimpleAction a, GLib.Variant? value) {
    string screen_name = value.get_child_value (0).get_string ();
    string json = value.get_child_value (1).get_string ();
    json += "\r\n";

    for (int i = 0; i < this.active_accounts.length; i ++) {
      var acc = this.active_accounts.get (i);
      if (acc.screen_name == screen_name) {
        var fake_call = acc.proxy.new_call ();
        acc.user_stream.parse_data_cb (fake_call, json, json.length, null);
        return;
      }
    }

    error ("Account @%s is not active.", screen_name);
  }
#endif
}
