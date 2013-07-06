/*  This file is part of corebird.
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

class Corebird : Gtk.Application {
  // TODO: Is the static here needed?
  public  static SQLHeavy.VersionedDatabase db;
  private static GLib.OutputStream log_stream;
  public  static GLib.Menu account_menu;

  public Corebird() throws GLib.Error{
    GLib.Object(application_id: "org.baedert.corebird",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                register_session: true);
    this.set_inactivity_timeout(500);


    // If the user wants the dark theme, apply it
    if(Settings.use_dark_theme()){
      Gtk.Settings settings = Gtk.Settings.get_default();
      settings.gtk_application_prefer_dark_theme = true;
    }
  }

  public override int command_line(ApplicationCommandLine cmd){
    this.hold();
    message("Parsing command line options...");
    bool new_instance = false;
    bool show_tweet_window = false;
    bool not_in_cmd = false;
   

    OptionEntry[] options = new OptionEntry[2];
    options[0] = {"tweet", 't', 0, OptionArg.NONE, ref show_tweet_window,
            "Shows only the 'compose tweet' window, nothing else.", null};
    options[1] = {"mode", 'u', 0, OptionArg.NONE, ref not_in_cmd,
            "Use this flag to indicate that the application does NOT run on the command line", 
            null};

    string[] args = cmd.get_arguments();
    string*[] _args = new string[args.length];
    for(int i = 0; i < args.length; i++){
      _args[i] = args[i];
    }

    try{
      var opt_context = new OptionContext("");
      opt_context.set_help_enabled(true);
      opt_context.add_main_entries(options, null);
      unowned string[] tmp = _args;
      opt_context.parse(ref tmp);
    } catch (GLib.OptionError e) {
      cmd.print("Use --help to see available options\n");
      quit();
      return -1;
    }

    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    
    if(startup_accounts.length == 1)
      message("Using account '@%s'", startup_accounts[0]);
    message("Startup accounts: %d", startup_accounts.length);

    if (!show_tweet_window){
      if (Settings.is_first_run ())
        critical ("Implement this.");
      else{
        if (startup_accounts.length == 1)
          add_window (new MainWindow (this, Account.list_accounts().data));
        else if(startup_accounts.length == 0)
          add_window (new MainWindow (this, null));
        else {
          foreach (string a in startup_accounts)
            message("TODO: ADD %s", a);
        }
      }
    } else {
/*      add_window (new ComposeTweetWindow (null, null, this));*/
      critical ("Implement.");
    }
    /* First, create that log file */
    var now = new GLib.DateTime.now_local();
    File log_file = File.new_for_path(Utils.user_file("log/%s.txt".printf(now.to_string())));
    log_stream = log_file.create(FileCreateFlags.REPLACE_DESTINATION);
    /* If we do not run on the command line, we simply redirect stdout
       to a log file*/
    GLib.Log.set_handler (null, LogLevelFlags.LEVEL_MESSAGE, print_to_log_file);
    GLib.Log.set_handler (null, LogLevelFlags.LEVEL_ERROR, print_to_log_file);
    GLib.Log.set_handler (null, LogLevelFlags.LEVEL_CRITICAL, print_to_log_file);
    GLib.Log.set_handler (null, LogLevelFlags.LEVEL_WARNING, print_to_log_file);
    GLib.Log.set_handler (null, LogLevelFlags.LEVEL_DEBUG, print_to_log_file);


    this.release();
    return 0;
  }

  public override void startup () {
    base.startup();
    // Load Database
    Corebird.db = new SQLHeavy.VersionedDatabase(Utils.user_file("Corebird.db"),
                                                 DATADIR+"/sql/init/");
    db.journal_mode = SQLHeavy.JournalMode.MEMORY;
    db.temp_store   = SQLHeavy.TempStoreMode.MEMORY;

    // Construct app menu
    Gtk.Builder builder = new Gtk.Builder ();
    builder.add_from_resource ("/org/baedert/corebird/ui/menu.ui");
    GLib.MenuModel app_menu = (MenuModel)builder.get_object ("app-menu");
    var acc_menu = app_menu.get_item_link(0, "section");
    account_menu = new GLib.Menu();

    unowned GLib.SList<Account> accounts = Account.list_accounts ();
    foreach (var acc in accounts) {
      var mi = new GLib.MenuItem ("@"+acc.screen_name, "app.show-win");
      mi.set_action_and_target_value ("app.show-win", new Variant.string (acc.screen_name));
      account_menu.append_item (mi);
    }
    ((GLib.Menu)acc_menu).append_submenu ("Open Account", account_menu);

    this.set_app_menu (app_menu);
    if(!FileUtils.test(Utils.user_file(""), FileTest.EXISTS)){
      bool success = File.new_for_path(Utils.user_file("")).make_directory();
      if(!success){
        critical("Couldn't create the ~/.corebird directory");
      }

      create_user_folder ("assets/");
      create_user_folder ("assets/avatars/");
      create_user_folder ("assets/banners/");
      create_user_folder ("assets/user");
      create_user_folder ("assets/media/");
      create_user_folder ("assets/media/thumbs/");
      create_user_folder ("log/");
      create_user_folder ("accounts");
    }

    Corebird.db = new SQLHeavy.VersionedDatabase(Utils.user_file("Corebird.db"),
                                                 DATADIR+"/sql/init/");
    db.journal_mode = SQLHeavy.JournalMode.MEMORY;
    db.temp_store   = SQLHeavy.TempStoreMode.MEMORY;

    Twitter.init();
    Twitter.update_config.begin ();


		// Set up the actions
    var settings_action = new SimpleAction("show-settings", null);
    settings_action.activate.connect(() => {
      var dialog = new SettingsDialog();
      dialog.show_all ();
    });
    add_action (settings_action);
    var about_dialog_action = new SimpleAction("show-about-dialog", null);
    about_dialog_action.activate.connect(() => {
      var b = new Gtk.Builder();
      b.add_from_file(DATADIR+"/ui/about-dialog.ui");
      Gtk.AboutDialog ad = b.get_object("about-dialog") as Gtk.AboutDialog;
      ad.show();
    });
    add_action(about_dialog_action);
		var quit_action = new SimpleAction("quit", null);
		quit_action.activate.connect(() => {
        quit();
		});
		add_action(quit_action);
    var show_win_action = new SimpleAction ("show-win", VariantType.STRING);
    show_win_action.activate.connect((acc_screen_name)=> {
        message(acc_screen_name.get_string ());
    });
    add_action(show_win_action);

    // Load custom CSS stuff
    try{
      CssProvider provider = new CssProvider();
      string style = Utils.user_file("style.css");
      if(!FileUtils.test(style, FileTest.EXISTS))
        style = DATADIR+"/ui/style.css";

      provider.load_from_file(File.new_for_path(style));
      Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
                                             STYLE_PROVIDER_PRIORITY_APPLICATION);
    }catch(GLib.Error e){
      warning("Error while loading ui/style.css: %s", e.message);
    }

    // Load custom icons
    IconSet micon = new IconSet.from_pixbuf(new Gdk.Pixbuf.from_file(DATADIR+"/mentions.svg"));
    IconSet sicon = new IconSet.from_pixbuf(new Gdk.Pixbuf.from_file(DATADIR+"/stream.svg"));
    IconSet search_icon = new IconSet.from_pixbuf(new Gdk.Pixbuf.from_file(DATADIR+"/search.svg"));
    IconFactory mfac = new IconFactory();
    mfac.add("mentions", micon);
    mfac.add("stream", sicon);
    mfac.add("search", search_icon);
    mfac.add_default();

    message("STARTUP");
  }

  public override void shutdown () {
    base.shutdown();
  }

  /**
   * Adds a main window to this application
   */
  public void add_main_window(){
    this.add_window(new MainWindow(this));
  }

  private void create_user_folder(string name) {
    try {
      bool success = File.new_for_path(Utils.user_file(name))
                     .make_directory();
      if(!success)
        critical("Couldn't create user folder %s", name);
      } catch (GLib.Error e) {
        critical("%s(%s)", e.message, name);
      }
  }

  /**
   * Log handler in case the application is not
   * started from the command line.
   */
  public static void print_to_log_file(string? log_domain, LogLevelFlags flags,
                                       string msg) {
    string out_string;
    if(log_domain == null)
      out_string = msg+"\n";
    else
      out_string = "(%s) %s".printf(log_domain, msg);

    log_stream.write_all (out_string.data, null);
    log_stream.flush();
    if (flags != LogLevelFlags.LEVEL_DEBUG)
      stdout.printf(out_string);
  }
}


int main (string[] args){
  try{
    //no initialisation of static fields :(
    Settings.init();
    new Utils();
    new WidgetReplacer();
    var corebird = new Corebird();
    return corebird.run(args);
  } catch(GLib.Error e){
    error(e.message);
  }
}
