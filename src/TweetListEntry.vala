

using Gtk;


class TweetListEntry : Gtk.Box {
	public Tweet tweet{get; set;}
	



	public TweetListEntry(Tweet tweet){
		// this.tweet = tweet;
		GLib.Object(orientation: Orientation.HORIZONTAL);
		set_has_window(false);
		get_style_context().add_class("tweet");


		Label a = new Label(tweet.text);
		a.set_use_markup(true);
		a.set_line_wrap(true);
		a.justify = Justification.LEFT;
		a.wrap_mode = Pango.WrapMode.WORD_CHAR;
		a.set_alignment(0,0);
		this.pack_start(a, true, true);


		this.set_size_request(150, 80);
	}

}