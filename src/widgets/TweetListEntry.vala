using Gtk;

// TODO: Deleted tweets don't get deleted in the stream
// TODO: margin between avatar, author and text is not the same.
// TODO: Open 'new windows' in a new window, an extended main window,
//       or just replace the main window's content?
class TweetListEntry : Gtk.Box{
	private static GLib.Regex? hashtag_regex = null;
	private static GLib.Regex? user_regex    = null;
	// private ImageButton avatar_button = new ImageButton();
	private Image avatar_button 	  = new Image();
	private Label text                = new Label("");
	private TextButton author_button;
	private Label screen_name	      = new Label("");
	private Label time_delta		  = new Label("");
	private MainWindow window;
	private new Gtk.Menu popup_menu	  = new Gtk.Menu();


	public TweetListEntry(Tweet tweet, MainWindow? window){
		GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 5);
		this.window = window;
		this.vexpand = false;


		if (hashtag_regex == null){
			try{
				hashtag_regex = new GLib.Regex("#\\w+", RegexCompileFlags.OPTIMIZE);	
				user_regex = new GLib.Regex("@\\w+", RegexCompileFlags.OPTIMIZE);
			}catch(GLib.RegexError e){
				warning("Error while creating regexes: %s", e.message);
			}
		}


		// If the tweet's avatar changed, also reset it in the widgets
		tweet.notify["avatar"].connect( () => {
			// avatar_button.set_bg(tweet.avatar);
			avatar_button.pixbuf = tweet.avatar;

			avatar_button.queue_draw();
		});


		// Set the correct CSS style class
		get_style_context().add_class("tweet");
 		//if (tweet.screen_name == User.screen_name)
		//	get_style_context().add_class("user-tweet");
		get_style_context().add_class("row");
			


		if (tweet.screen_name == User.screen_name){
			get_style_context().add_class("user-tweet");
			var delete_item = new Gtk.MenuItem.with_label("Delete");
			popup_menu.add(delete_item);
		}else{
			var rt_item = new Gtk.CheckMenuItem.with_label("Retweet");
			popup_menu.add(rt_item);
			var fav_item = new Gtk.CheckMenuItem.with_label("Favorite");
			popup_menu.add(fav_item);
			var answer_item = new Gtk.MenuItem.with_label("Answer");
			popup_menu.add(answer_item);
		}
		popup_menu.show_all();


		var left_box = new Box(Orientation.VERTICAL, 3);
		avatar_button.set_valign(Align.START);
		avatar_button.get_style_context().add_class("avatar");
		avatar_button.pixbuf = tweet.avatar;
		// avatar_button.set_bg(tweet.avatar);
		avatar_button.margin_top = 3;
		avatar_button.margin_left = 3;
		left_box.pack_start(avatar_button, false, false);

		if(tweet.favorited){
			left_box.pack_start(new Image.from_pixbuf(Twitter.favorited_img), false, false);
		}
		this.pack_start(left_box, false, false);


		var middle_box = new Box(Orientation.VERTICAL, 3);
		var author_box = new Box(Orientation.HORIZONTAL, 8);
		author_button = new TextButton(tweet.user_name);
		author_button.clicked.connect(() => {
			ProfileDialog d = new ProfileDialog(tweet.screen_name);
			d.show_all();
		});
		author_box.pack_start(author_button, false, false);
		screen_name.set_use_markup(true);
		screen_name.label = "<small>@%s</small>".printf(tweet.screen_name);
		screen_name.ellipsize = Pango.EllipsizeMode.END;
		author_box.pack_start(screen_name, false, false);

		middle_box.pack_start(author_box, false, false);



		// Also set User/Hashtag links
		text.label = Tweet.replace_links(tweet.text);
		text.set_use_markup(true);
		text.set_line_wrap(true);
		text.wrap_mode = Pango.WrapMode.WORD_CHAR;
		text.track_visited_links = true;
		text.set_alignment(0, 0);
		text.activate_link.connect(handle_uri);		
		middle_box.pack_start(text, true, true);
		this.pack_start(middle_box, true, true);

		var right_box = new Box(Orientation.VERTICAL, 2);
		time_delta.set_use_markup(true);
		time_delta.label = "<small>%s</small>".printf(tweet.time_delta);
		time_delta.set_alignment(1, 0.5f);
		time_delta.get_style_context().add_class("time-delta");
		time_delta.margin_right = 3;
		right_box.pack_start(time_delta, false, false);
		var ab = new ArrowButton();  //TODO: Rename this
		ab.vexpand = true;
		ab.hexpand = false;
		ab.set_halign(Align.END);
		ab.set_valign(Align.FILL);
		ab.clicked.connect(() => {
			var w = new TweetInfoWindow(tweet);
			w.show_all();
		});
		// EXPAND, FILL
		right_box.pack_start(ab, false, true);

		this.pack_start(right_box, false, false);

		this.set_size_request(20, 80);
		this.show_all();
	}

	public override bool draw(Cairo.Context c){
		var style = this.get_style_context();
		style.render_background(c, 0, 0, get_allocated_width(), get_allocated_height());
		style.render_frame(c, 0, 0, get_allocated_width(), get_allocated_height());
		base.draw(c);
		return false;
	}


	/**
	* Handle uris in the tweets
	*/
	private bool handle_uri(string uri){
		if(uri.has_prefix("@")){
			ProfileDialog pd = new ProfileDialog(uri.substring(1));
			pd.show_all();
			return true;
		}else if(uri.has_prefix("#")){
			debug("TODO: Implement search");
			return true;
		}
		return false;
	}
}
