

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

		image = new Gtk.Image.from_pixbuf(pixbuf);
		var ebox = new EventBox();
		ebox.add(image);
		scroller.add_with_viewport(ebox);
		this.add(scroller);

		int img_width = pixbuf.get_width();
		int img_height = pixbuf.get_height();

		int win_width  = 800;
		int win_height = 600;
		if(img_width <= Gdk.Screen.width()*0.7)
			win_width = img_width;

		if(img_height <= Gdk.Screen.height()*0.7)
			win_height = img_height;

		if(win_width < 800 && win_height == 600) {
			int add_width;
			scroller.get_vscrollbar().get_preferred_width(null, out add_width);
			win_width += add_width;
		}

		if(win_width == 800 && win_height < 600) {
			int add_height;
			scroller.get_hscrollbar().get_preferred_width(null, out add_height);
			win_height += add_height;
		}

		scroller.set_size_request(win_width, win_height);

		// this.add(scroller);
		this.set_decorated(false);
		this.set_transient_for(parent);
		this.set_type_hint(Gdk.WindowTypeHint.DIALOG);
		this.focus_out_event.connect(() => {
			this.destroy();
			return false;
		});
		this.button_press_event.connect(() => {
			this.destroy();
			return false;
		});
		this.key_press_event.connect(() => {
			this.destroy();
			return false;
		});
	}
}