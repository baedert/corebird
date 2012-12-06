

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
	/**
	* Check whether the user wants Corebird to always use the dark gtk theme variant.
	*/
	public static bool use_dark_theme(){
		return settings.get_boolean("use-dark-theme");		
	}

	/**
	 * Returns whether the user wants to use a primary toolbar in the
	 * main window or not.
	 */
	public static bool show_primary_toolbar(){
		return settings.get_boolean("show-primary-toolbar");
	}

	/**
	 * Retuns the update interval in minutes.
	 */
	public static int get_update_interval(){
		return settings.get_int("update-interval");
	}

	public static void set_bool(string key, bool value){
		settings.set_boolean(key, value);
	}

	public static void set_int(string key, int value) {
		settings.set_int(key, value);
	}



}