

using Gtk;


class SettingsDialog : Dialog {
	private Notebook main_notebook = new Notebook();


	public SettingsDialog(){
		this.get_content_area().pack_start(main_notebook, true, true);

	}
}