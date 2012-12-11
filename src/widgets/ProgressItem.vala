using Gtk;

class ProgressItem : Box {
	private Spinner spinner 		= new Spinner();
	private Button cancel_button 	= new Button();

	public ProgressItem(int size = 35){
		GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 3);
		this.get_style_context().add_class("progress-item");
		this.pack_start(spinner, true, true);
		cancel_button.image = new Image.from_stock(Stock.CANCEL, IconSize.LARGE_TOOLBAR);
		cancel_button.clicked.connect( () => {
			this.stop();
			this.parent.remove(this);
		});
		this.pack_start(cancel_button, false, false);
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