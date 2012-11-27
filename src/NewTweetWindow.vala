
using Gtk;
using Rest;


class NewTweetWindow : Window {
	private TextView text_view = new TextView();


	public NewTweetWindow(Window parent) {
		this.set_transient_for(parent);
		this.set_modal(true);
		this.set_type_hint(Gdk.WindowTypeHint.DIALOG);


		ToolItem left_item = new ToolItem();
		Box left_box = new Box(Orientation.HORIZONTAL, 0);
		left_item.add(left_box);




		Toolbar bottom_bar = new Toolbar();
		bottom_bar.show_arrow = false;
		bottom_bar.toolbar_style = ToolbarStyle.ICONS;
		bottom_bar.get_style_context().add_class("inline-toolbar");

		Button img_button = new Button.with_label("Add Image");
		Button location_button = new Button.with_label("Add Location");

		left_box.pack_start(img_button, false, false);
		left_box.pack_start(location_button, false, false);

		bottom_bar.add(left_item);
		var sep1 = new SeparatorToolItem();
		sep1.draw = false;
		sep1.set_expand(true);
		bottom_bar.add(sep1);


		ToolItem right_item = new ToolItem();
		Box right_box = new Box(Orientation.HORIZONTAL, 0);
		Button cancel_button = new Button();
		cancel_button.image = new Image.from_icon_name("send-to", IconSize.SMALL_TOOLBAR);
		cancel_button.clicked.connect( () => {
			this.destroy();
		});
		right_box.pack_start(cancel_button, false, false);
		Button send_button = new Button();
		send_button.image = new Image.from_icon_name("list-add-symbolic", IconSize.SMALL_TOOLBAR);
		send_button.clicked.connect( () => {
			TextIter start, end;
			text_view.buffer.get_start_iter(out start);
			text_view.buffer.get_end_iter(out end);
			string text = text_view.buffer.get_text(start, end, true);
			if(text.strip() == "")
				return;
				
			var call = Twitter.proxy.new_call();
			call.set_function("1.1/statuses/update.json");
			call.set_method("POST");
			call.add_param("status", text);
			call.invoke_async.begin(null);
			this.destroy();
		});
		right_box.pack_end(send_button, false, false);
		right_item.add(right_box);
		bottom_bar.add(right_item);



		
		text_view.margin = 5;
		text_view.wrap_mode = WrapMode.WORD_CHAR;
		ScrolledWindow text_scroller = new ScrolledWindow(null, null);
		text_scroller.add(text_view);



		var main_box = new Box(Orientation.VERTICAL, 0);
		main_box.pack_start(text_scroller, true, true);
		main_box.pack_end(bottom_bar, false, true);

		this.add(main_box);
		this.set_default_size(300, 150);
	}
	
}