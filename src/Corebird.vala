


using Gtk;
// TODO: Profile startup when adding e.g. 300 tweets.
// TODO: Check the spec and add exception handling(e.g. different http status codes)
class Corebird : Gtk.Application {
	public static SQLHeavy.Database db;

	public Corebird() throws GLib.Error{
		GLib.Object(application_id: "org.baedert.corebird",
		            flags: ApplicationFlags.FLAGS_NONE);
		this.register_session = true;
		this.register();

		// If the user wants the dark theme, apply it
		if(Settings.use_dark_theme()){
			Gtk.Settings settings = Gtk.Settings.get_default();
			settings.gtk_application_prefer_dark_theme = true;
		}

		Notify.init("Corebird");


		//Create the database needed almost everywhere
		try{
			Corebird.db = new SQLHeavy.Database("Corebird.db");
			Corebird.create_tables();
		}catch(SQLHeavy.Error e){
			error("SQL ERROR: %s", e.message);
		}

		stdout.printf("SQLite version: %d\n", SQLHeavy.Version.sqlite_library());

		Twitter.init();



		if (Settings.is_first_run()){
			this.add_window(new FirstRunWindow(this));
		} else
			this.add_window(new MainWindow(this));


		this.activate.connect( ()  => {});
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
		corebird.run(args);
	} catch(GLib.Error e){
		error(e.message);
	}

	return 0;
}
