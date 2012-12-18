

using Gtk;

class SettingsDialog : PreferencesDialog {
	private MainWindow win;

	public SettingsDialog(MainWindow win){
		base("Settings", 4);
		this.win = win;
		this.set_transient_for(win);
		this.set_modal(true);
		this.set_default_size(450, 2);


		// GENERAL SETTINGS
		int general = append_page("General");
		add_heading(general, "Updates");
		add_int_option(general, "Tweet update interval:", 1, 
		               Settings.get_update_interval(), 60, (val) => {
		    Settings.set_int("update-interval", val);
		});
		add_bool_option(general, "Refresh streams on startup:", Settings.refresh_streams_on_startup(), 
		                (val) => {
		    Settings.set_bool("refresh-streams-on-startup", val);
		});

		// BEHAVIOR SETTINGS
		int behavior = append_page("Behavior");
		add_bool_option(behavior, "Show tray icon", false, (val) => {
			if (val){

			}else{
				
			}
		});



		// INTERFACE SETTINGS
		int inter = append_page("Interface");
		add_heading(inter, "Main window");
		add_bool_option(inter, "Use dark theme:", Settings.use_dark_theme(), (val) => {
			Settings.set_bool("use-dark-theme", val);
			Gtk.Settings.get_default().gtk_application_prefer_dark_theme = val;
		});
		add_bool_option(inter, "Show primary toolbar:", Settings.show_primary_toolbar(), (val) => {
			Settings.set_bool("show-primary-toolbar", val);
			this.win.set_show_primary_toolbar(val);
		});


		// NOTIFICATION SETTINGS
		int notify = append_page("Notifications");
		add_heading(notify, "Actions");
		add_bool_option(notify, "On new Tweets:", Settings.notify_new_tweets(), (val) => {
			Settings.set_bool("new-tweets-notify", val);
		});
		add_bool_option(notify, "On new mentions:", Settings.notify_new_mentions(), (val) => {
			Settings.set_bool("new-mentions-notify", val);
		});
	}
}