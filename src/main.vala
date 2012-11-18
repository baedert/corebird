
using Soup;
using Rest;
using Gtk;


using Json;

class Corebird : Gtk.Application {
	public static SQLHeavy.Database db;

	public Corebird() throws GLib.Error{
		GLib.Object(application_id: "org.baedert.corebird",
		            flags: ApplicationFlags.FLAGS_NONE);
		this.register_session = true;
		this.register();


		//Create the database needed almost everywhere
		try{
			Corebird.db = new SQLHeavy.Database("Corebird.db");
		}catch(SQLHeavy.Error e){
			stderr.printf("SQL ERROR: "+e.message);
		}

		stdout.printf("SQLite version: %d\n", SQLHeavy.Version.sqlite_library());

		Twitter.init();



		if (Settings.is_first_run())
		    this.add_window(new FirstRunWindow());
		else
			this.add_window(new MainWindow());


		this.activate.connect( ()  => {});
	}

	public static void create_tables(){
		try{
			db.execute("CREATE TABLE IF NOT EXISTS `common`(token VARCHAR(255), 
				token_secret VARCHAR(255));");
			db.execute("CREATE TABLE IF NOT EXISTS `avatars`(id INTEGER(11), path VARCHAR(255), time INTEGER(11));");
		}catch(SQLHeavy.Error e){
			stderr.printf("Error while initing creating the tables: %s\n", e.message);
		}
	}
}


int main (string[] args){
	Gtk.init(ref args);

	try{
		Settings.init();
		var corebird = new Corebird();
		corebird.run(args);
	} catch(GLib.Error e){
		stderr.printf(e.message+"\n");
		return -1;
	}
	return 0;
}
