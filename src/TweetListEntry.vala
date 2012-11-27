using Gtk;


class TweetListEntry : Gtk.Box {
	public Tweet tweet;
	private Gtk.Image avatar   = new Gtk.Image();
	private Label text         = new Label("");
	private Label author       = new Label("");
	private Label rt_label     = new Label("");
	private Label time_delta   = new Label("");



	public TweetListEntry(Tweet tweet){
		GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 3);
		set_has_window(false);
		get_style_context().add_class("tweet");
		this.border_width = 4;


		var left_box = new Box(Orientation.VERTICAL, 2);
		avatar.pixbuf = tweet.avatar;
		avatar.set_alignment(0, 0);
		left_box.pack_start(avatar, false, false);
		time_delta.set_use_markup(true);
		time_delta.label = "<small>"+tweet.time_delta+"</small>";
		time_delta.set_alignment(0,0);
		left_box.pack_start(time_delta, false, false);
		this.pack_start(left_box, false, false);

		var top_box = new Box(Orientation.HORIZONTAL, 4);
		author.set_use_markup(true);
		author.label = "<span size=\"larger\"><b>"+tweet.user_name+"</b></span>";
		top_box.pack_start(author, false, false);
		if (tweet.is_retweet){
			rt_label.set_use_markup(true);
			rt_label.label = "<small>RT by "+tweet.retweeted_by+"</small>";
		}
		top_box.pack_end(rt_label, false, false);

		var right_box = new Box(Orientation.VERTICAL, 2);
		right_box.pack_start(top_box, false, false);

		text.label = tweet.text;
		text.set_use_markup(true);
		text.set_line_wrap(true);
		text.wrap_mode = Pango.WrapMode.WORD_CHAR;
		text.set_alignment(0, 0);		
		right_box.pack_start(text, true, true);

		this.pack_start(right_box, true, true);

		this.button_press_event.connect( (btn) => {
			if (btn.type == Gdk.EventType.@2BUTTON_PRESS){
				message("double click");
				return true;
			}
			message("evt");
			return false;
		});


		this.set_size_request(150, 80);
		this.show_all();
	}

}