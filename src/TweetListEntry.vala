using Gtk;


class TweetListEntry : Gtk.Box {
	private static GLib.Regex? hashtag_regex = null;
	private static GLib.Regex? link_regex    = null;
	private static GLib.Regex? user_regex    = null;
	public Tweet tweet;
	private Button avatar_button = new Button();
	private Label text           = new Label("");
	private Label author         = new Label("");
	private Label rt_label       = new Label("");
	private Label time_delta     = new Label("");



	public TweetListEntry(Tweet tweet){
		GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 3);
		if (hashtag_regex == null){
			try{
				hashtag_regex = new GLib.Regex("#\\w*", RegexCompileFlags.OPTIMIZE);	
				link_regex  = new GLib.Regex("(http|https)://[a-zA-Z.-\\?\\-\\+\\&]*",
					RegexCompileFlags.OPTIMIZE);
				user_regex = new GLib.Regex("@\\w*", RegexCompileFlags.OPTIMIZE);
			}catch(GLib.RegexError e){
				warning("Error while creating regexes: %s", e.message);
			}
		}
		set_has_window(false);
		this.get_style_context().add_class("tweet");
		this.border_width = 4;

		var left_box = new Box(Orientation.VERTICAL, 2);
		avatar_button.clicked.connect( () => {
			ProfileDialog pd = new ProfileDialog(tweet.screen_name);
			pd.show_all();
		});
		avatar_button.image = new Gtk.Image.from_pixbuf(tweet.avatar);
		avatar_button.set_alignment(0,0);
		avatar_button.border_width = 0;
		left_box.pack_start(avatar_button, false, false);
		time_delta.set_use_markup(true);
		time_delta.label = "<small>"+tweet.time_delta+"</small>";
		time_delta.set_alignment(0,0);
		time_delta.get_style_context().add_class("time-delta");
		left_box.pack_start(time_delta, false, false);
		this.pack_start(left_box, false, false);

		var top_box = new Box(Orientation.HORIZONTAL, 4);
		author.set_use_markup(true);
		author.label = "<span size=\"larger\"><b>"+tweet.user_name+"</b></span>";
		author.get_style_context().add_class("author");
		top_box.pack_start(author, false, false);
		if (tweet.is_retweet){
			rt_label.set_use_markup(true);
			rt_label.label = "<small>RT by "+tweet.retweeted_by+"</small>";
		}
		top_box.pack_end(rt_label, false, false);

		var right_box = new Box(Orientation.VERTICAL, 2);
		right_box.pack_start(top_box, false, false);

		string real_text = tweet.text;
		try{
			real_text = hashtag_regex.replace(real_text, -1, 0, "<a href='cb://search/\\0'>\\0</a>");
			real_text = link_regex.replace(real_text, -1, 0, "<a href='\\0'>\\0</a>");
			real_text = user_regex.replace(real_text, -1, 0, "<a href='cb://profile/\\0'>\\0</a>");
		}catch(GLib.RegexError e){
			warning("Error while applying regexes: %s", e.message);
		}
		text.label = real_text;
		text.set_use_markup(true);
		text.set_line_wrap(true);
		text.wrap_mode = Pango.WrapMode.WORD_CHAR;
		text.set_alignment(0, 0);		
		right_box.pack_start(text, true, true);


		this.pack_start(right_box, true, true);

		this.enter_notify_event.connect( () => {
			stdout.printf(tweet.text+"\n");
			return true;
		}) ;

		text.activate_link.connect( (uri) => {
			if (uri.has_prefix("cb://")){
				// Format: cb://foo/bar
				string[] tokens = uri.split("/");
				string action = tokens[2];
				string value = tokens[3];
				handle_link(action, value);
				return true;
			}
			return false;
		});
		


		this.set_size_request(150, 80);
		this.show_all();
	}


	private void handle_link(string action, string value){
		if (action == "profile"){
			// Value: @name
			ProfileDialog pd = new ProfileDialog(value.substring(1));
			pd.show_all();
		}else if(action == "search"){
			
		}
	}
}