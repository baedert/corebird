

using Gtk;

class ImageDialog : Gtk.Window {
	private ScrolledWindow scroller = new ScrolledWindow(null, null);
	private Image image;


	public ImageDialog(Window parent, string path) {

		//Choose proper width/height
		Gdk.Pixbuf pixbuf = null;
		try {
			pixbuf = new Gdk.Pixbuf.from_file(path);
		} catch (GLib.Error e) {
			critical(e.message);
		}
		int img_width = pixbuf.get_width();
		int img_height = pixbuf.get_height();

		if (img_width <= Gdk.Screen.width()*0.7 &&
		    		img_height <= Gdk.Screen.height()*0.7){

			this.resize(img_width, img_height);
		}

		image = new Gtk.Image.from_pixbuf(pixbuf);
		scroller.add_with_viewport(image);
		this.add(scroller);
		this.set_decorated(false);
		this.set_transient_for(parent);
		this.set_type_hint(Gdk.WindowTypeHint.DIALOG);
		this.focus_out_event.connect(() => {
			this.destroy();
			return false;
		});
	}
}