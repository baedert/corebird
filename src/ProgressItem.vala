using Gtk;

class ProgressItem : Box {
	private Spinner spinner = new Spinner();

	public ProgressItem(int size = 35){
		this.pack_start(spinner, true, true);
		this.border_width = 5;
		spinner.set_size_request(size, size);
		this.set_size_request(size, size);
	}


	public void start(){
		spinner.start();
	}

	public void stop(){
		spinner.stop();
	}
}