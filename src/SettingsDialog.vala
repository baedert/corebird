

using Gtk;

class SettingsDialog : Gtk.Dialog {
	private MainWindow win;

	public SettingsDialog(MainWindow win){
		this.win = win;
		this.set_transient_for(win);
		this.set_modal(true);
		this.set_default_size(450, 120);
		this.title = "Settings";

		var builder = new UIBuilder(DATADIR+"ui/settings-dialog.ui", "main_notebook");
		var main_notebook = builder.get_notebook("main_notebook");

		// this.add(main_box);
		this.get_content_area().pack_start(main_notebook, true, true);

		var upload_provider_combobox = builder.get_combobox("upload_provider_combobox");
		upload_provider_combobox.active = Settings.upload_provider();
		upload_provider_combobox.changed.connect(() => {
			Settings.set_int("upload-provider", upload_provider_combobox.active);
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

		var on_new_tweets_combobox = builder.get_combobox("on_new_tweets_combobox");
		on_new_tweets_combobox.active = Settings.notify_new_tweets();
		on_new_tweets_combobox.changed.connect(() => {
			Settings.set_int("new-tweets-notify", on_new_tweets_combobox.active);
		});

		var on_new_mentions_switch = builder.get_switch("on_new_mentions_switch");
		on_new_mentions_switch.active = Settings.notify_new_mentions();
		on_new_mentions_switch.notify["active"].connect(() => {
			Settings.set_bool("new-mentions-notify", on_new_mentions_switch.active);
		});

		var on_new_dms_switch = builder.get_switch("on_new_dms_switch");
		on_new_dms_switch.active = Settings.notify_new_dms();
		on_new_dms_switch.notify["active"].connect(() => {
			Settings.set_bool("new-dms-notify", on_new_dms_switch.active);
		});

    var on_new_followers_switch = builder.get_switch("on_new_followers_switch");
    on_new_followers_switch.active = Settings.notify_new_followers();
    on_new_followers_switch.notify["active"].connect(() => {
        Settings.set_bool("new-followers-notify", on_new_followers_switch.active);
    });

		this.add_button("Close", 1);

		this.response.connect((id) => {
			if(id == 1)
				this.dispose();
		});
	}
}
