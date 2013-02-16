using Gtk;
// TODO: Deleted tweets don't get deleted in the stream
// TODO: Open 'new windows' in a new window, an extended main window,
//       or just replace the main window's content?
class TweetListEntry : Gtk.Box {
	private Gdk.Window event_window;
	private static GLib.Regex? hashtag_regex = null;
	private static GLib.Regex? user_regex    = null;
	private Image avatar                 = new Image();
	private Label text                   = new Label("");
	private TextButton author_button;
	private Label screen_name            = new Label("");
	private Label time_delta             = new Label("");
	private ToggleButton retweet_button  = new ToggleButton();
	private ToggleButton favorite_button = new ToggleButton();
	private MainWindow window;
	// Timestamp used for sorting
	public int64 timestamp;



	public TweetListEntry(Tweet tweet, MainWindow? window){
		GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 5);
		this.window = window;
		this.vexpand = false;
		// this.set_has_window(true);


		if (hashtag_regex == null){
			try{
				hashtag_regex = new GLib.Regex("#\\w+", RegexCompileFlags.OPTIMIZE);
				user_regex    = new GLib.Regex("@\\w+", RegexCompileFlags.OPTIMIZE);
			}catch(GLib.RegexError e){
				warning("Error while creating regexes: %s", e.message);
			}
		}

		timestamp = tweet.created_at;


		// If the tweet's avatar changed, also reset it in the widgets
		tweet.notify["avatar"].connect( () => {
			avatar.pixbuf = tweet.avatar;
			avatar.queue_draw();
		});


		// Set the correct CSS style class
		get_style_context().add_class("tweet");
		get_style_context().add_class("row");



		if (tweet.screen_name == User.screen_name){
			get_style_context().add_class("user-tweet");
		}

		this.enter_notify_event.connect( ()=> {
			// GLib.Idle.add(() => {
				favorite_button.show();
				retweet_button.show();
				message("OUT");
				// return false;
			// });

			return false;
		});
		this.leave_notify_event.connect( () => {
			// GLib.Idle.add(() => {
				favorite_button.hide();
				retweet_button.hide();
				message("OUT");
			// 	return false;
			// });

			return false;
		});


		var left_box = new Box(Orientation.VERTICAL, 3);
		avatar.set_valign(Align.START);
		avatar.get_style_context().add_class("avatar");
		avatar.pixbuf = tweet.avatar;
		avatar.margin_top = 3;
		avatar.margin_left = 3;
		left_box.pack_start(avatar, false, false);

		var status_box = new Box(Orientation.HORIZONTAL, 5);
		favorite_button.get_style_context().add_class("favorite-button");
		favorite_button.set_window(this.get_window());
		// favorite_button.no_show_all = true;
		status_box.pack_start(favorite_button, false, false);
		retweet_button.get_style_context().add_class("retweet-button");
		retweet_button.no_show_all = true;
//		status_box.pack_start(retweet_button, false, false);
		left_box.pack_start(status_box, true, false);
		this.pack_start(left_box, false, false);


		var middle_box = new Box(Orientation.VERTICAL, 3);
		var author_box = new Box(Orientation.HORIZONTAL, 8);
		author_button = new TextButton(tweet.user_name);
		author_button.clicked.connect(() => {
			if(window != null){
				window.switch_page(MainWindow.PAGE_PROFILE, tweet.user_id);
			}else
				critical("main window instance is null!");
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

		this.pack_start(right_box, false, false);


		this.set_size_request(20, 80);
		this.show_all();
		favorite_button.hide();
		retweet_button.hide();


	}


	public void update_time_delta() {
		GLib.DateTime now = new GLib.DateTime.now_local();
		GLib.DateTime then = new GLib.DateTime.from_unix_local(timestamp);
		this.time_delta.label = "<small>%s</small>".printf(
			Utils.get_time_delta(then, now));
	}



	public override bool draw(Cairo.Context c){
		var style = this.get_style_context();
		int w = get_allocated_width();
		int h = get_allocated_height();
		style.render_background(c, 0, 0, w, h);
		style.render_frame(c, 0, 0, w, h);
		base.draw(c);
		return false;
	}


	/**
	* Handle uris in the tweets
	*/
	private bool handle_uri(string uri){
		string term = uri.substring(1);

		if(uri.has_prefix("@")){
			// FIXME: Use the id OR the handle in ProfileDialog
			// ProfileDialog pd = new ProfileDialog(term);
			// pd.show_all();
			return true;
		}else if(uri.has_prefix("#")){
			debug("TODO: Implement search");
			return true;
		}
		return false;
	}

	public override void realize() {
		message("realize");
		Allocation alloc;
		Gdk.WindowAttr attr = {};
		Gdk.Window window;

		this.get_allocation(out alloc);

		this.set_realized(true);


		attr.x = alloc.x;
		attr.y = alloc.y;
		attr.width = alloc.width;
		attr.height = alloc.height;
		attr.window_type = Gdk.WindowType.CHILD;
		attr.event_mask = this.get_events();
		attr.event_mask |= (Gdk.EventMask.ENTER_NOTIFY_MASK |
							Gdk.EventMask.LEAVE_NOTIFY_MASK |
							Gdk.EventMask.EXPOSURE_MASK);

		var attr_type = Gdk.WindowAttributesType.X |
						Gdk.WindowAttributesType.Y;



		bool visible_window = get_has_window();
		if(visible_window) {
			// attr.visual  = get_visual();
			// attr.wclass  = Gdk.WindowWindowClass.INPUT_OUTPUT;
			// attr_type   |= Gdk.WindowAttributesType.VISUAL;

		 //    window = new Gdk.Window(get_parent_window(),
		 //                            attr, attr_type);
		 //    this.set_window(window);
		 //    window.set_user_data(this);
		 //    message("Visible window");
		}else {
			window = get_parent_window();
			set_window(window);
			window.ref(); // TODO:?

			attr.wclass = Gdk.WindowWindowClass.INPUT_ONLY;

			this.event_window = new Gdk.Window(window, attr, attr_type);
			this.event_window.set_user_data(this);
			event_window.lower();
			message("No visible window");

		}

	}

	public override void unrealize() {
		message("unrealize");
		if(this.event_window != null) {
			this.event_window.set_user_data(null);
			this.event_window.destroy();
			this.event_window = null;
		}

		base.unrealize();
	}

	public override void map(){

		message("map");

		if(event_window != null)
			event_window.show();

		base.map();

		if(event_window != null)
			event_window.show();
	}

	public override void unmap() {
		message("unmap");

		if(event_window != null)
			event_window.hide();

		base.unmap();
	}

	public override void size_allocate(Allocation alloc) {
		message("size_allocate");
		base.size_allocate(alloc);

		this.set_allocation(alloc);


		if(this.get_realized()) {
			if(event_window != null)
				event_window.move_resize(alloc.x, alloc.y,
				                         alloc.width, alloc.height);

			if(this.get_has_window()) {
				this.get_window().move_resize(alloc.x, alloc.y,
				                              alloc.width, alloc.height);
			}
		}


	}
}
