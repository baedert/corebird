
using Gtk;

class ProgressItem : Box {
	private Spinner spinner = new Spinner();

	public ProgressItem(int size = 35){
		this.pack_start(spinner, true, true);
		this.set_size_request(size, size);
		spinner.start();
	}

}