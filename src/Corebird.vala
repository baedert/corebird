


using Gtk;
// TODO: Profile startup when adding e.g. 300 tweets.
// TODO: Check the spec and add exception handling(e.g. different http status codes)
class Corebird : Gtk.Application {
	public static SQLHeavy.Database db;

	public Corebird() throws GLib.Error{
		GLib.Object(application_id: "org.baedert.corebird",
		            flags: ApplicationFlags.FLAGS_NONE);
		this.register_session = true;

		//TODO: This is possibly wrong:
		this.register();

		// If the user wants the dark theme, apply it
		if(Settings.use_dark_theme()){
			Gtk.Settings settings = Gtk.Settings.get_default();
			settings.gtk_application_prefer_dark_theme = true;
		}

		NotificationManager.init();

		// Create ~/.corebird if neccessary
		if(!FileUtils.test(Utils.get_user_file_path(""), FileTest.EXISTS)){
			bool success = File.new_for_path(Utils.get_user_file_path(""))
								.make_directory();
			if(!success){
				critical("Couldn't create the ~/.corebird directory");
			}

			success = File.new_for_path(Utils.get_user_file_path("assets/"))
								.make_directory();
			success = File.new_for_path(Utils.get_user_file_path("assets/avatars/"))
								.make_directory();
			success = File.new_for_path(Utils.get_user_file_path("assets/banners/"))
								.make_directory();
			success = File.new_for_path(Utils.get_user_file_path("assets/user/"))
								.make_directory();
		}


		//Create the database needed almost everywhere
		try{
			Corebird.db = new SQLHeavy.Database(Utils.get_user_file_path("Corebird.db"));
			db.journal_mode = SQLHeavy.JournalMode.MEMORY;

			Corebird.create_tables();

		}catch(SQLHeavy.Error e){
			error("SQL ERROR: %s", e.message);
		}

		stdout.printf("SQLite version: %d\n", SQLHeavy.Version.sqlite_library());

		Twitter.init();

		if (Settings.is_first_run()) {
			this.add_window(new FirstRunWindow(this));
		} else {
			UIBuilder builder = new UIBuilder(DATADIR+"/ui/menu.ui");
			this.set_app_menu(builder.get_menu_model("app-menu"));
			this.add_window(new MainWindow(this));
		}


		this.activate.connect( ()  => {});
		this.set_inactivity_timeout(500);

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
			FileUtils.get_contents("sql/init.sql", out sql);
			db.run(sql);
		} catch (SQLHeavy.Error e) {
			error("Error while creating the tables: %s", e.message);
		} catch (GLib.FileError e){
			error("Error while loading sql file: %s", e.message);
		}
	}
}


int main (string[] args){
	try{
		Settings.init();
		new Utils(); //no initialisation of static fields :(
		var corebird = new Corebird();
		return corebird.run(args);
	} catch(GLib.Error e){
		error(e.message);
	}
}
