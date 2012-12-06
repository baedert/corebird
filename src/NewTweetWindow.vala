
using Gtk;
using Rest;


class NewTweetWindow : Window {
	private TweetTextView tweet_text = new TweetTextView();
	private Button send_button       = new Button.with_label("Send");
	private Button cancel_button	 = new Button.with_label("Cancel");


	public NewTweetWindow(Window parent) {
		this.set_transient_for(parent);
		this.set_modal(true);
		this.set_type_hint(Gdk.WindowTypeHint.DIALOG);
		this.set_title("New Tweet");
		this.border_width = 5;

		//No text, so disable the send button
		// send_button.set_sensitive(false);


		// ToolItem left_item = new ToolItem();
		// Box left_box = new Box(Orientation.HORIZONTAL, 0);
		// left_item.add(left_box);

		// tweet_text.key_release_event.connect( () => {
		// 	if (tweet_text.too_long || tweet_text.get_length() == 0)
		// 		send_button.set_sensitive(false);
		// 	else
		// 		send_button.set_sensitive(true);
		// 	return false;
		// });


		// Toolbar bottom_bar = new Toolbar();
		// bottom_bar.show_arrow = false;
		// bottom_bar.toolbar_style = ToolbarStyle.ICONS;
		// bottom_bar.get_style_context().add_class("inline-toolbar");

		// Button img_button = new Button();
		// img_button.image = new Image.from_icon_name("insert-object", IconSize.SMALL_TOOLBAR);
		// img_button.clicked.connect( () => {
		// 	message("Show window...");
		// });
		// left_box.pack_start(img_button, false, false);

		// bottom_bar.add(left_item);
		// var sep1 = new SeparatorToolItem();
		// sep1.draw = false;
		// sep1.set_expand(true);
		// bottom_bar.add(sep1);


		// ToolItem right_item  = new ToolItem();
		// Box right_box        = new Box(Orientation.HORIZONTAL, 0);
		// Button cancel_button = new Button();
		// cancel_button.image  = new Image.from_icon_name("window-close", IconSize.SMALL_TOOLBAR);
		// cancel_button.clicked.connect( () => {
		// 	this.destroy();
		// });
		// right_box.pack_start(cancel_button, false, false);
		// send_button.image = new Image.from_icon_name("document-send", IconSize.SMALL_TOOLBAR);
		// send_button.clicked.connect( () => {
		// 	TextIter start, end;
		// 	tweet_text.buffer.get_start_iter(out start);
		// 	tweet_text.buffer.get_end_iter(out end);
		// 	string text = tweet_text.buffer.get_text(start, end, true);
		// 	if(text.strip() == "")
		// 		return;
				
		// 	var call = Twitter.proxy.new_call();
		// 	call.set_function("1.1/statuses/update.json");
		// 	call.set_method("POST");
		// 	call.add_param("status", text);
		// 	call.invoke_async.begin(null, () => {
		// 		message("Sent: %s", call.get_payload());
		// 	});
		// 	this.destroy();
		// });
		// right_box.pack_end(send_button, false, false);
		// right_item.add(right_box);
		// bottom_bar.add(right_item);

		//Configure actions
		cancel_button.clicked.connect( () => {
			this.destroy();
		});



		var main_box = new Box(Orientation.VERTICAL, 5);
		// main_box.pack_start(text_scroller, true, true);
		// main_box.pack_end(bottom_bar, false, true);

		var middle_box = new Box(Orientation.HORIZONTAL, 3);
		var av = new Gtk.Image.from_file("assets/avatars/omg-twitter_normal.png");
		av.set_alignment(0,0);


		middle_box.pack_start(av, false, false);
		var text_scroller = new ScrolledWindow(null, null);
		text_scroller.add(tweet_text);
		middle_box.pack_start(text_scroller, true, true);
		main_box.pack_start(middle_box, true, true);
		var button_box = new Box(Orientation.HORIZONTAL, 5);
		send_button.get_style_context().add_class("suggested-action");

		var right_button_box = new ButtonBox(Orientation.HORIZONTAL);
		right_button_box.set_spacing(5);
		right_button_box.pack_start(cancel_button, false, false);
		right_button_box.pack_end(send_button, false, false);

		var attachment_button_box = new Box(Orientation.HORIZONTAL, 0);
		attachment_button_box.get_style_context().add_class("linked");

		var add_image_button = new Button();
		add_image_button.image = new Image.from_icon_name("insert-image", IconSize.SMALL_TOOLBAR);
		var add_video_button = new Button();
		add_video_button.image = new Image.from_icon_name("insert-object", IconSize.SMALL_TOOLBAR);
		attachment_button_box.pack_start(add_image_button, false, false);
		attachment_button_box.pack_start(add_video_button, false, false);

		button_box.pack_start(attachment_button_box, false, false);
		button_box.pack_end(right_button_box, false, false);

		main_box.pack_end(button_box, false, true);
		this.add(main_box);
		this.set_default_size(380, 175);
	}
	
}