

class Settings : GLib.Object {
	private static GLib.Settings settings;

	public static void init(){
		settings = new GLib.Settings("org.baedert.corebird");
	}

	/**
	 * Returns how many tweets should be stacked before a
	 * notification should be created.
	 */
	public static int get_tweet_stack_count() {
		int setting_val = settings.get_int("new-tweets-notify");
		switch(setting_val){
			case 2:
				return 5;
			case 3:
				return 10;
			case 4:
				return 25;
			case 5: return 50;
			default:
				return setting_val;
		}
	}




	/**
	* Checks whether the current run is the first run of Corebird.
	* Notice that this only relies on the information saved in GSettings, nothing else.
	*/
	public static bool is_first_run(){
    // If the database file exists, this is NOT the first run...
    string db_file = Utils.user_file("Corebird.db");
    return !FileUtils.test(db_file, FileTest.EXISTS);
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

	public static int notify_new_tweets(){
		return settings.get_int("new-tweets-notify");
	}

	public static bool notify_new_mentions(){
		return settings.get_boolean("new-mentions-notify");
	}

	public static bool notify_new_dms(){
		return settings.get_boolean("new-dms-notify");
	}

	public static int upload_provider(){
		return settings.get_int("upload-provider");
	}

	public static bool refresh_streams_on_startup(){
		return settings.get_boolean("refresh-streams-on-startup");
	}

	public static bool show_tray_icon(){
		return settings.get_boolean("show-tray-icon");
	}

	public static bool show_inline_media(){
		return settings.get_boolean("show-inline-media");
	}

	public static int get_animation_duration() {
		return settings.get_int("animation-duration");
	}



	public static void set_bool(string key, bool value){
		settings.set_boolean(key, value);
	}

	public static void set_int(string key, int value) {
		settings.set_int(key, value);
	}

	public static void set_string(string key, string value){
		settings.set_string(key, value);
	}


	public static string get_string(string key){
		return settings.get_string(key);
	}


}
