using Gtk;

// TODO: resolve the links in the tweet
// TODO: Deleted tweets don't get deleted in the stream
class TweetListEntry : Gtk.Box {
	private static GLib.Regex? hashtag_regex = null;
	private static GLib.Regex? link_regex    = null;
	private static GLib.Regex? user_regex    = null;
	private ImageButton avatar_button = new ImageButton();
	private Label text                = new Label("");
	private TextButton author_button;
	private Label rt_label            = new Label("");
	private Label screen_name	      = new Label("");
	private Label time_delta		  = new Label("");
	private MainWindow window;
	private new Gtk.Menu popup_menu	  = new Gtk.Menu();


	public TweetListEntry(Tweet tweet, MainWindow window){
		GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 5);
		this.window = window;
		this.margin_left   = 5;
		this.margin_right  = 5;
		this.margin_top    = 2;
		this.margin_bottom = 2;




		if (hashtag_regex == null){
			try{
				hashtag_regex = new GLib.Regex("#\\w*", RegexCompileFlags.OPTIMIZE);	
				link_regex  = new GLib.Regex("(http|https)://[\\w\\.\\/\\?\\-\\+\\&]*",
					RegexCompileFlags.OPTIMIZE);
				user_regex = new GLib.Regex("@\\w*", RegexCompileFlags.OPTIMIZE);
			}catch(GLib.RegexError e){
				warning("Error while creating regexes: %s", e.message);
			}
		}
		// If the tweet's avatar changed, also reset it in the widgets
		tweet.notify["avatar"].connect( () => {
			avatar_button.bg = tweet.avatar;
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

		string real_text = tweet.text;
		try{
			real_text = hashtag_regex.replace(real_text, -1, 0, "<a href='cb://search/\\0'>\\0</a>");
			real_text = link_regex.replace(real_text, -1, 0, "<a href='\\0'>\\0</a>");
			real_text = user_regex.replace(real_text, -1, 0, "<a href='cb://profile/\\0'>\\0</a>");
		}catch(GLib.RegexError e){
			warning("Error while applying regexes: %s", e.message);
		}


		avatar_button.set_valign(Align.START);
		avatar_button.get_style_context().add_class("avatar");
		avatar_button.set_size_request(48, 48);
		avatar_button.bg = tweet.avatar;
		avatar_button.margin_top = 3;
		this.pack_start(avatar_button, false, false);


		var middle_box = new Box(Orientation.VERTICAL, 3);
		var author_box = new Box(Orientation.HORIZONTAL, 8);
		author_button = new TextButton(tweet.user_name);
		author_box.pack_start(author_button, false, false);
		screen_name.set_use_markup(true);
		screen_name.label = "<small>@%s</small>".printf(tweet.screen_name);
		screen_name.ellipsize = Pango.EllipsizeMode.END;
		author_box.pack_start(screen_name, false, false);

		middle_box.pack_start(author_box, false, false);

		text.label = real_text;
		text.set_use_markup(true);
		text.set_line_wrap(true);
		text.wrap_mode = Pango.WrapMode.WORD_CHAR;
		text.set_alignment(0, 0);		
		middle_box.pack_start(text, true, true);
		this.pack_start(middle_box, true, true);

		var right_box = new Box(Orientation.VERTICAL, 2);
		time_delta.set_use_markup(true);
		time_delta.label = "<small>%s</small>".printf(tweet.time_delta);
		time_delta.set_alignment(1, 0.5f);
		time_delta.get_style_context().add_class("time-delta");
		right_box.pack_start(time_delta, false, false);
		var ab = new ArrowButton();
		ab.vexpand = true;
		ab.hexpand = false;
		ab.set_halign(Align.END);
		ab.set_valign(Align.FILL);
		// EXPAND, FILL
		right_box.pack_start(ab, false, true);

		this.pack_start(right_box, false, false);

		this.set_size_request(150, 80);
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
		if (uri.has_prefix("cb://")){
			// Format: cb://foo/bar
			string[] tokens = uri.split("/");
			string action = tokens[2];
			string value = tokens[3];

		
			if (action == "profile"){
				// Value: @name
				ProfileDialog pd = new ProfileDialog(value.substring(1));
				pd.show_all();
			}else if(action == "search"){
				message("Search for %s", value);
				window.switch_to_search(value);
			}
			return true;
		}
		return false;
	}
}