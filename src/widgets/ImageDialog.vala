

using Gtk;

class ImageDialog : Gtk.Window {
	private ScrolledWindow scroller = new ScrolledWindow(null, null);
	private Image image;
	private new Gtk.Menu popup_menu = new Gtk.Menu();


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

		Gtk.MenuItem save_item = new Gtk.MenuItem.with_label("Save As...");
		save_item.activate.connect(() => {
			var fc = new FileChooserDialog("Save Image", parent,
			                               FileChooserAction.SAVE,
			                               Stock.CANCEL, ResponseType.CANCEL,
			                               Stock.SAVE, ResponseType.ACCEPT);
			string filename = Utils.get_file_name(path);
			fc.set_current_name(filename);

			int response = fc.run();
			if(response == ResponseType.CANCEL)
				fc.close();
			else if(response == ResponseType.ACCEPT) {
				File dest = File.new_for_uri(fc.get_uri());
				message("Source: %s", path);
				message("Destin: %s", fc.get_uri());
				File source = File.new_for_path(path);
				source.copy(dest, FileCopyFlags.OVERWRITE);
				fc.close();
			}

		});
		popup_menu.add(save_item);
		popup_menu.show_all();

		// this.add(scroller);
		this.set_decorated(false);
		this.set_transient_for(parent);
		this.set_type_hint(Gdk.WindowTypeHint.DIALOG);
		this.focus_out_event.connect(() => {
			// this.destroy();
			return true;
		});
		this.button_press_event.connect((evt) => {
			message("B: %u", evt.button);
			if(evt.button != 3)
				this.destroy();
			else
				popup_menu.popup(null, null, null, evt.button, evt.time);
			return true;
		});
		this.key_press_event.connect(() => {
			this.destroy();
			return true;
		});
	}
}