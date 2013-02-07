
using Gtk;
using Rest;



class NewTweetWindow : Gtk.ApplicationWindow {
	private TweetTextView tweet_text = new TweetTextView();
	private Button send_button       = new Button.with_label("Send");
	private Button cancel_button	 = new Button.from_stock(Stock.CANCEL);
	private Box left_box			 = new Box(Orientation.VERTICAL, 4);
	private Button add_image_button  = new Button();
	private int media_count			 = 0;
	private ImageButton media_image  = new ImageButton();
	private string media_uri;


	public NewTweetWindow(Window? parent, string? answer_to = null, Gtk.Application? app = null) {
		// if(app != null)
			GLib.Object(application: app);
		// else
			// GLib.Object();


		this.show_menubar = false;
		if(parent != null){
			this.set_type_hint(Gdk.WindowTypeHint.DIALOG);
			this.set_modal(true);
			this.set_transient_for(parent);
		} else {
			// If the dialog has no parent window, we just make it an actual window
			set_position(WindowPosition.CENTER);
		}
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
		var av = new Gtk.Image.from_file(Utils.get_user_file_path("assets/avatars/"
		                                 +Utils.get_avatar_name(User.avatar_url)));
		av.set_alignment(0,0);
		left_box.pack_start(av, false, false);
		left_box.pack_start(new Separator(Orientation.HORIZONTAL), false, false);
		media_image.set_halign(Align.CENTER);
		media_image.set_valign(Align.START);
		media_image.clicked.connect(remove_media);
		media_image.tooltip_text = "Click to remove";
		left_box.pack_start(media_image, false, false);

		middle_box.pack_start(left_box, false, false);

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

		add_image_button.image = new Image.from_icon_name("insert-image", IconSize.SMALL_TOOLBAR);
		add_image_button.clicked.connect(() => {
			FileChooserDialog fcd = new FileChooserDialog("Select Image", null,
				FileChooserAction.OPEN, Stock.CANCEL, ResponseType.CANCEL,
				Stock.OPEN, ResponseType.ACCEPT);
			fcd.set_modal(true);
			FileFilter filter = new FileFilter();
			filter.add_mime_type("image/png");
			filter.add_mime_type("image/jpeg");
			filter.add_mime_type("image/gif");
			fcd.set_filter(filter);
			if(fcd.run() == ResponseType.ACCEPT){
				string file = fcd.get_filename();
				this.media_uri = file;
				try{
				media_image.set_bg(new Gdk.Pixbuf.from_file_at_size(file, 40, 40));
				}catch(GLib.Error e){critical("Loading scaled image: %s", e.message);}
				media_image.set_visible(true);
				media_count++;
				if(media_count >= Twitter.get_max_media_per_upload()){
					add_image_button.set_sensitive(false);
				}
			}
			fcd.close();
		});
		attachment_button_box.pack_start(add_image_button, false, false);
		button_box.pack_start(attachment_button_box, false, false);
		button_box.pack_end(right_button_box, false, false);

		main_box.pack_end(button_box, false, true);
		this.add(main_box);
		this.set_default_size(380, 175);
		this.show_all();
	}

	private void remove_media(){
		media_image.set_visible(false);
		media_count--;
		if(media_count <= Twitter.get_max_media_per_upload())
			add_image_button.set_sensitive(true);
	}


	private void send_tweet(){
		TextIter start, end;
		tweet_text.buffer.get_start_iter(out start);
		tweet_text.buffer.get_end_iter(out end);
		string text = tweet_text.buffer.get_text(start, end, true);
		if(text.strip() == "")
			return;

		var call = Twitter.proxy.new_call();
		call.set_method("POST");
		if(media_count == 0){
			call.set_function("1.1/statuses/update.json");
		} else {
/*			call.set_function("/statuses/update_with_media.json");
			Gdk.Pixbuf pic = new Gdk.Pixbuf.from_file(media_uri);
			pixels = pic.get_pixels_with_length();

			this.param = new Param.full("media[]", MemoryUse.COPY, pixels,
			                            "multipart/form-data", media_uri);
			call.add_param_full(param);*/
			debug("Not yet implemented.");
		}

		call.add_param("status", text);

		// message("Back: %s", call.get_payload());
		message("Code: %u, Status: %s", call.get_status_code(), call.get_status_message());
		call.invoke_async.begin(null, () => {
			message("Back: %s", call.get_payload());
			message("Code: %u, Status: %s", call.get_status_code(), call.get_status_message());
		});
		this.destroy();
	}

}