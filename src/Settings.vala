

class Settings{
	private static GLib.Settings settings;




	public static void init(){
		settings = new GLib.Settings("org.baedert.corebird");
	}



	/**
	* Checks whether the current run is the first run of Corebird.
	* Notice that this only relies on the information saved in GSettings, nothing else.
	*/
	public static bool is_first_run(){
		return settings.get_boolean("first-run");
	}


}