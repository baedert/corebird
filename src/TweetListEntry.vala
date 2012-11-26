

using Gtk;


class TweetListEntry : Gtk.Box {
	public Tweet tweet;
	private Gtk.Image avatar = new Gtk.Image();
	private Label text = new Label("");
	private Label author = new Label("");



	public TweetListEntry(Tweet tweet){
		GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 3);
		set_has_window(false);
		get_style_context().add_class("tweet");


		avatar.pixbuf = tweet.avatar;
		avatar.set_alignment(0,0);
		this.pack_start(avatar, false, false);


		var top_box = new Box(Orientation.HORIZONTAL, 0);
		author.set_use_markup(true);
		author.label = "<span size=\"larger\"><b>"+tweet.user_name+"</b></span>";
		top_box.pack_start(author, false, false);

		var right_box = new Box(Orientation.VERTICAL, 2);
		right_box.pack_start(top_box, false, false);

		text.label = tweet.text;
		text.set_use_markup(true);
		text.set_line_wrap(true);
		text.wrap_mode = Pango.WrapMode.WORD_CHAR;
		text.set_alignment(0, 0);		
		right_box.pack_start(text, true, true);

		this.pack_start(right_box, true, true);


		this.set_size_request(150, 80);
	}

}