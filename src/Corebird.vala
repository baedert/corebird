using Gtk;

class Corebird : Gtk.Application {
	public static SQLHeavy.Database db;
	private bool show_tweet_window = false;
	private string role_name = "corebird";

	public Corebird() throws GLib.Error{
		GLib.Object(application_id: "org.baedert.corebird",
		            flags: ApplicationFlags.HANDLES_COMMAND_LINE);
		this.register();
		this.set_default();
		this.activate.connect( ()  => {});
		this.set_inactivity_timeout(500);

		// If the user wants the dark theme, apply it
		if(Settings.use_dark_theme()){
			Gtk.Settings settings = Gtk.Settings.get_default();
			settings.gtk_application_prefer_dark_theme = true;
		}


		// Create ~/.corebird if neccessary
		if(!FileUtils.test(Utils.get_user_file_path(""), FileTest.EXISTS)){
			bool success = File.new_for_path(Utils.get_user_file_path(""))
								.make_directory();
			if(!success){
				critical("Couldn't create the ~/.corebird directory");
			}

			create_user_folder("assets/");
			create_user_folder("assets/avatars/");
			create_user_folder("assets/banners/");
			create_user_folder("assets/user");
			create_user_folder("assets/media/");
			create_user_folder("assets/media/thumbs/");
		}


		//Create the database needed almost everywhere
		try{
			Corebird.db = new SQLHeavy.Database(Utils.get_user_file_path("Corebird.db"));
			db.journal_mode = SQLHeavy.JournalMode.MEMORY;
			db.temp_store   = SQLHeavy.TempStoreMode.MEMORY;

			Corebird.create_tables();
		}catch(SQLHeavy.Error e){
			error("SQL ERROR: %s", e.message);
		}

		stdout.printf("SQLite version: %d\n", SQLHeavy.Version.sqlite_library());


		//Load custom style sheet
		try{
			CssProvider provider = new CssProvider();
			string style = Utils.get_user_file_path("style.css");
			if(!FileUtils.test(style, FileTest.EXISTS))
				style = DATADIR+"/ui/style.css";

			provider.load_from_file(File.new_for_path(style));
			Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
		                                         STYLE_PROVIDER_PRIORITY_APPLICATION);
		}catch(GLib.Error e){
			warning("Error while loading ui/style.css: %s", e.message);
		}

		//Load & set the corebird icon
		// TODO: Find out how to do this the right way.
		Gtk.IconTheme.add_builtin_icon("corebird", 64,
		                               new Gdk.Pixbuf.from_file(DATADIR+"/icon.png"));


		Twitter.init();
		//Load the user's sceen_name used for identifying him
		User.load();
		//Update the Twitter config
		Twitter.update_config.begin();
	}

	public override int command_line(ApplicationCommandLine cmd){
		message("Parsing command line options...");
		this.hold();
		bool new_instance = false;

		OptionEntry[] options = new OptionEntry[3];
		options[0] = {"tweet", 't', 0, OptionArg.NONE, ref show_tweet_window,
					  "Shows only the 'compose tweet' window, nothing else.", null};
		options[1] = {"new-instance", 'n', 0, OptionArg.NONE, ref new_instance,
					  "Force a new instance", null};
		options[2] = {"role", 'r', 0, OptionArg.STRING, ref role_name,
					  "Sets the role name of the main window(default is 'corebird')",
					  "ROLE"};

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
			return -1;
		}

		add_windows();


		this.release();
		return 0;
	}

	public void add_windows() {
		if(!show_tweet_window){
			if (Settings.is_first_run()) {
				this.add_window(new FirstRunWindow(this));
			} else {
				UIBuilder builder = new UIBuilder(DATADIR+"/ui/menu.ui");
				this.set_app_menu(builder.get_menu_model("app-menu"));
				var mw = new MainWindow(this);
				NotificationManager.init(mw);
				mw.set_role(role_name);
				this.add_window(mw);
			}
		} else {
			ComposeTweetWindow win = new ComposeTweetWindow(null, null, this);
			this.add_window(win);
		}
	}

	/**
	 * Adds a main window to this application
	 */
	public void add_main_window(){
		this.add_window(new MainWindow(this));
	}

	/**
	 * Creates the tables in the SQLite database
	 */
	public static void create_tables(){
		try{
			string sql;
			FileUtils.get_contents(DATADIR+"/sql/init.sql", out sql);
			db.run(sql);
		} catch (SQLHeavy.Error e) {
			error("Error while creating the tables: %s", e.message);
		} catch (GLib.FileError e){
			error("Error while loading sql file: %s", e.message);
		}
	}

	private void create_user_folder(string name) {
		try {
			bool success = File.new_for_path(Utils.get_user_file_path(name))
									.make_directory();
	        if(!success)
	        	critical("Couldn't create user folder %s", name);
    	} catch (GLib.Error e) {
    		critical(e.message);
    	}
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
