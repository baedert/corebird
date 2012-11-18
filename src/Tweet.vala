using Gtk;


class Tweet : GLib.Object{
	public bool retweeted = false;
	public bool favorited = false;
	public string text;
	public string from;
	public string from_screenname;
	public string retweeded_by;
	public bool is_retweet;
	public Gdk.Pixbuf avatar;

	public Tweet(string text){
		this.text = text;
		this.avatar = Twitter.no_avatar;
	}

	public Gdk.Pixbuf? get_status_pixbuf(){
		if (retweeted && favorited)
			return Twitter.retweeted_favorited_img;
		else if (retweeted)
			return Twitter.retweeted_img;
		else if (favorited)
			return Twitter.favorited_img;

		return null;
	}

}



class TweetRenderer : Gtk.CellRenderer {
	private static const int PADDING = 5;
	public Tweet tweet {get; set;}
	public Pango.FontDescription font {get; set;}
	public Pango.FontDescription from_font {get; set;}

	public TweetRenderer(){
		GLib.Object();
		this.font = Pango.FontDescription.from_string("Ubuntu 9");
		this.from_font = this.font.copy();
		this.from_font.set_weight(Pango.Weight.BOLD);
	}

	public override void render (Cairo.Context c, Widget tree,
								 Gdk.Rectangle background_area,
								 Gdk.Rectangle cell_area,
							 	 CellRendererState flags) {
		Pango.Rectangle size;
		Gdk.Pixbuf? status_pixbuf = tweet.get_status_pixbuf();


		if(status_pixbuf != null){
			c.save();
			Gdk.cairo_rectangle(c, background_area);
			Gdk.cairo_set_source_pixbuf (c, status_pixbuf,
			    background_area.x+background_area.width-Twitter.retweeted_img.width,
			    background_area.y);
			c.fill();
			c.restore();
		}

		c.save();
		Gdk.cairo_rectangle(c, background_area);
		Gdk.cairo_set_source_pixbuf (c, tweet.avatar,
				PADDING, background_area.y + PADDING);
		c.fill();
		c.restore();


		c.move_to(background_area.x + 2*PADDING + tweet.avatar.get_width(), 
		          background_area.y + PADDING);
		Pango.Layout from_layout = Pango.cairo_create_layout(c);
		from_layout.set_text(tweet.from, -1);
		Pango.cairo_show_layout(c, from_layout);
		from_layout.get_extents(null, out size);

		c.move_to(background_area.x + 2* PADDING + tweet.avatar.get_width(),
		          background_area.y + PADDING + (size.height / Pango.SCALE) + 3);


		Pango.Layout layout = Pango.cairo_create_layout(c);
		layout.set_width((cell_area.width - 3*PADDING -
			Twitter.no_avatar.get_width()) * Pango.SCALE);
		layout.set_font_description(font);
		layout.set_text(tweet.text, tweet.text.length);
		Pango.cairo_show_layout(c, layout);

	}

    public override void get_size (Widget widget, Gdk.Rectangle? cell_area,
                                   out int x_offset, out int y_offset,
                                   out int width, out int height) {
        x_offset = 0;
        y_offset = 0;
        width = 120;
        height = 80;
    }
}