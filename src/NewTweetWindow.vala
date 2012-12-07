
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

		//Configure actions
		cancel_button.clicked.connect( () => {
			this.destroy();
		});

		//No text, so disable the send button
		send_button.set_sensitive(false);
		send_button.clicked.connect(() => {
			send_tweet();
		});

		tweet_text.key_release_event.connect( () => {
			if (tweet_text.too_long || tweet_text.get_length() == 0)
				send_button.set_sensitive(false);
			else
				send_button.set_sensitive(true);
			return false;
		});




		var main_box = new Box(Orientation.VERTICAL, 5);

		var middle_box = new Box(Orientation.HORIZONTAL, 3);
		var av = new Gtk.Image.from_file("assets/avatars/%s".printf(Utils.get_avatar_name(User.avatar_url)));
		av.set_alignment(0,0);


		middle_box.pack_start(av, false, false);
		tweet_text.wrap_mode = WrapMode.WORD_CHAR;
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
	

	private void send_tweet(){
		TextIter start, end;
		tweet_text.buffer.get_start_iter(out start);
		tweet_text.buffer.get_end_iter(out end);
		string text = tweet_text.buffer.get_text(start, end, true);
		if(text.strip() == "")
			return;
			
		var call = Twitter.proxy.new_call();
		call.set_function("1.1/statuses/update.json");
		call.set_method("POST");
		call.add_param("status", text);
		call.invoke_async.begin(null, () => {
			message("Sent: %s", call.get_payload());
		});
		this.destroy();		
	}
}