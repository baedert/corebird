
using Gtk;


class NewTweetWindow : Window {
	


	public NewTweetWindow() {
		// GLib.Object(type : WindowType.POPUP);



		Toolbar bottom_bar = new Toolbar();
		bottom_bar.show_arrow = false;
		bottom_bar.get_style_context().add_class("inline-toolbar");

		ToolButton a = new ToolButton(null, "START");
		a.halign = Align.START;
		a.hexpand = true;
		bottom_bar.add(a);

		ToolButton send_button = new ToolButton(null, "Send");

		send_button.halign = Align.END;
		send_button.set_expand(true);
		bottom_bar.add(send_button);


		TextView text_view = new TextView();
		text_view.margin = 5;
		ScrolledWindow text_scroller = new ScrolledWindow(null, null);
		text_scroller.add(text_view);



		var main_box = new Box(Orientation.VERTICAL, 0);
		main_box.pack_start(text_scroller, true, true);
		main_box.pack_end(bottom_bar, false, true);

		this.add(main_box);
		this.set_default_size(300, 150);
		this.show_all();
		// this.set_resizable(false);
	}
	
}