using Gtk;
class TweetListEntry : Gtk.Box {
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
	private int64 tweet_id;
	private Tweet tweet;


	public TweetListEntry(Tweet tweet, MainWindow? window){
		GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 5);
		this.window = window;
		this.vexpand = false;
		this.tweet = tweet;

		if (hashtag_regex == null){
			try{
				hashtag_regex = new GLib.Regex("#\\w+", RegexCompileFlags.OPTIMIZE);
				user_regex    = new GLib.Regex("@\\w+", RegexCompileFlags.OPTIMIZE);
			}catch(GLib.RegexError e){
				warning("Error while creating regexes: %s", e.message);
			}
		}

		this.timestamp = tweet.created_at;
		this.tweet_id  = tweet.id;


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
			favorite_button.show();
			retweet_button.show();
			return false;
		});
		this.leave_notify_event.connect( () => {
			favorite_button.hide();
			retweet_button.hide();
			return false;
		});


		var left_box = new Box(Orientation.VERTICAL, 3);
		avatar.set_valign(Align.START);
		avatar.pixbuf = tweet.avatar;
		avatar.margin_top = 3;
		avatar.margin_left = 3;
		left_box.pack_start(avatar, false, false);

		var status_box = new Box(Orientation.HORIZONTAL, 5);
		favorite_button.get_style_context().add_class("favorite-button");
		favorite_button.active = tweet.favorited;
		favorite_button.toggled.connect(favorite_tweet);

		// favorite_button.no_show_all = true;
		status_box.pack_start(favorite_button, false, false);
		retweet_button.get_style_context().add_class("retweet-button");
		retweet_button.active = tweet.retweeted;
		retweet_button.toggled.connect(retweet_tweet);

		// retweet_button.no_show_all = true;
		status_box.pack_start(retweet_button, false, false);
		left_box.pack_start(status_box, true, false);
		this.pack_start(left_box, false, false);


		var right_box = new Box(Orientation.VERTICAL, 8);
		var top_box = new Box(Orientation.HORIZONTAL, 5);



		author_button = new TextButton(tweet.user_name);
		author_button.clicked.connect(() => {
			if(window != null){
				window.switch_page(MainWindow.PAGE_PROFILE, tweet.user_id);
			}else
				critical("main window instance is null!");
		});
		top_box.pack_start(author_button, false, false);
		screen_name.set_use_markup(true);
		screen_name.label = "<small>@%s</small>".printf(tweet.screen_name);
		screen_name.ellipsize = Pango.EllipsizeMode.END;
		top_box.pack_start(screen_name, false, false);


		time_delta.set_use_markup(true);
		time_delta.label = "<small>%s</small>".printf(tweet.time_delta);
		time_delta.set_alignment(1, 0.5f);
		time_delta.get_style_context().add_class("time-delta");
		time_delta.margin_right = 3;
		top_box.pack_end(time_delta, false, false);

		right_box.pack_start(top_box, false, true);

		if(tweet.reply_id != 0)
			top_box.pack_end(new Image.from_pixbuf(Twitter.conversation_img),
			                 false, false);


	    // Also set User/Hashtag links
		text.label = Tweet.replace_links(tweet.text);
		text.set_use_markup(true);
		text.set_line_wrap(true);
		text.wrap_mode = Pango.WrapMode.WORD_CHAR;
		text.set_alignment(0, 0);
		text.activate_link.connect(handle_uri);
		right_box.pack_start(text, true, true);

		this.pack_start(right_box, true, true);

		tweet.inline_media_added.connect((pic) => {
			var img = new Image.from_pixbuf(pic);
			img.visible = true;
			this.pack_start(img, false, false);
		});

		this.set_size_request(20, 80);
		this.show_all();
	}

	public void update_time_delta() {
		GLib.DateTime now = new GLib.DateTime.now_local();
		GLib.DateTime then = new GLib.DateTime.from_unix_local(timestamp);
		this.time_delta.label = "<small>%s</small>".printf(
			Utils.get_time_delta(then, now));
	}

	private void favorite_tweet() {

		var call = Twitter.proxy.new_call();
		if(favorite_button.active)
			call.set_function("1.1/favorites/create.json");
		else
			call.set_function("1.1/favorites/destroy.json");
		call.set_method("POST");
		call.add_param("id", tweet_id.to_string());
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end(res);
			} catch (GLib.Error e) {
				critical(e.message);
			}

			try{
				SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
				                           @"UPDATE `cache` SET
				                            `favorited`='1' WHERE
				                            `id`='$tweet_id';");
				q.execute();
			} catch(SQLHeavy.Error e) {
				critical(e.message);
			}
		});
	}

	private void retweet_tweet() {
		var call = Twitter.proxy.new_call();
		call.set_function(@"1.1/statuses/retweet/$tweet_id.json");
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


}
