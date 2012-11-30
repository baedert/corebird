
using Gtk;

class ProgressItem : Box {
	private Spinner spinner = new Spinner();

	public ProgressItem(){
		this.pack_start(spinner, true, true);
		this.set_size_request(35, 35);
		spinner.start();
	}

}