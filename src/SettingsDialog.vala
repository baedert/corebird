

using Gtk;

class SettingsDialog : Dialog{
	private Notebook main_notebook = new Notebook();
	private MainWindow win;
	private Button close_button = new Button.from_stock(Stock.CLOSE);

	public SettingsDialog(MainWindow win){
		this.win = win;
		this.get_content_area().pack_start(main_notebook, true, true);

		Grid common_grid = new Grid();
		common_grid.border_width = 4;
		common_grid.attach(new Label("Update interval(minutes)"), 0, 0, 1, 1);
		SpinButton interval_spinner = new SpinButton.with_range(1, 60, 1);
		interval_spinner.value = Settings.get_update_interval();
		interval_spinner.value_changed.connect( () => {
			Settings.set_int("update-interval", (int)interval_spinner.value);
		});
		common_grid.attach(interval_spinner, 1, 0, 1, 1);

		main_notebook.append_page(common_grid, new Label("Common"));



		Grid interface_grid =  new Grid();
		interface_grid.border_width=  4;
		interface_grid.attach(new Label("Show primary toolbar:"), 0, 0, 1, 1);
		Switch pt_switch = new Switch();
		pt_switch.active = Settings.show_primary_toolbar();
		pt_switch.notify["active"].connect(() => {
			Settings.set_bool("show-primary-toolbar", pt_switch.active);
			win.set_show_primary_toolbar(pt_switch.active);
			message("Toggle primary toolbar");
		});
		interface_grid.attach(pt_switch, 1, 0, 1,1 );
		interface_grid.attach(new Label("Use dark theme:"), 0, 1, 1, 1);
		Switch dark_theme_switch = new Switch();
		dark_theme_switch.active = Settings.use_dark_theme();
		dark_theme_switch.notify["active"].connect(() => {
			Settings.set_bool("use-dark-theme", dark_theme_switch.active);
			Gtk.Settings s = Gtk.Settings.get_default();
			s.gtk_application_prefer_dark_theme = dark_theme_switch.active;
		});		
		interface_grid.attach(dark_theme_switch, 1, 1, 1, 1);
		main_notebook.append_page(interface_grid, new Label("Interface"));
		close_button.set_alignment(0, 1);
		get_content_area().pack_end(close_button, false, false);
		close_button.clicked.connect( ()=> {
			this.destroy();
		});
	}
}