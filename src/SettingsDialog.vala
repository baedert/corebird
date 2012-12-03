

using Gtk;

class SettingsDialog : Dialog{
	private Notebook main_notebook = new Notebook();
	private MainWindow win;

	public SettingsDialog(MainWindow win){
		this.win = win;
		this.get_content_area().pack_start(main_notebook, true, true);

		Grid common_grid = new Grid();
		common_grid.border_width = 4;
		common_grid.attach(new Label("Update interval(minutes)"), 0, 0, 1, 1);
		SpinButton interval_spinner = new SpinButton.with_range(1, 60, 1);
		interval_spinner.value_changed.connect( () => {
			Settings.set_int("update-interval", (int)interval_spinner.value);
		});
		common_grid.attach(interval_spinner, 1, 0, 1, 1);

		main_notebook.append_page(common_grid, new Label("Common"));



		Grid interface_grid =  new Grid();
		interface_grid.border_width=  4;
		interface_grid.attach(new Label("Show primary toolbar:"), 0, 0, 1, 1);
		Switch pt_switch = new Switch();
		pt_switch.notify["active"].connect(() => {
			Settings.set_bool("show-primary-toolbar", pt_switch.active);
			win.set_show_primary_toolbar(pt_switch.active);
			message("Toggle primary toolbar");
		});
		interface_grid.attach(pt_switch, 1, 0, 1,1 );
		main_notebook.append_page(interface_grid, new Label("Interface"));
	}
}