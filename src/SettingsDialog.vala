

using Gtk;

class SettingsDialog : Gtk.Window {
	private MainWindow win;

	public SettingsDialog(MainWindow win){
		// base("Settings", 4);
		this.win = win;
		this.set_transient_for(win);
		this.set_modal(true);
		this.set_default_size(450, 2);
		this.border_width = 5;

		var builder = new UIBuilder(DATADIR+"ui/settings-dialog.ui", "main_box");
		var main_box = builder.get_box("main_box");

		this.add(main_box);

		var updates_disabled_label = builder.get_label("updates_disabled_label");
		var tweet_interval = builder.get_spin_button("update_interval");
		tweet_interval.adjustment = new Gtk.Adjustment(0, 0, 60, 1, 0, 0);
		tweet_interval.changed.connect(() => {
			if((int)tweet_interval.value == 0)
				updates_disabled_label.visible = true;
			else
				updates_disabled_label.visible = false;
		});

		var primary_toolbar_switch = builder.get_switch("primary_toolbar_switch");
		primary_toolbar_switch.active = Settings.show_primary_toolbar();
		primary_toolbar_switch.notify["active"].connect(() => {
			Settings.set_bool("show-primary-toolbar", primary_toolbar_switch.active);
			win.set_show_primary_toolbar(primary_toolbar_switch.active);
		});

		var inline_media_switch = builder.get_switch("inline_media_switch");
		inline_media_switch.active = Settings.show_inline_media();
		inline_media_switch.notify["active"].connect(() => {
			Settings.set_bool("show-inline-media", inline_media_switch.active);
		});

		var dark_theme_switch = builder.get_switch("dark_theme_switch");
		dark_theme_switch.active = Settings.use_dark_theme();
		dark_theme_switch.notify["active"].connect(() => {
			bool val = dark_theme_switch.active;
			Settings.set_bool("use-dark-theme", val);
			Gtk.Settings.get_default().gtk_application_prefer_dark_theme = val;
		});

		// // GENERAL SETTINGS
		// int general = append_page("General");
		// add_heading(general, "Updates");
		// add_int_option(general, "Tweet update interval:", 1,
		//                Settings.get_update_interval(), 60, (val) => {
		//     Settings.set_int("update-interval", val);
		// });
		// add_bool_option(general, "Refresh streams on startup:",
		//                 Settings.refresh_streams_on_startup(),
		//                 (val) => {
		//     Settings.set_bool("refresh-streams-on-startup", val);
		// });

		// // BEHAVIOR SETTINGS
		// int behavior = append_page("Behavior");
		// add_heading(behavior, "Application");
		// add_bool_option(behavior, "Show tray icon:", false, (val) => {
		// 	if (val){

		// 	}else{

		// 	}
		// });

	}
}