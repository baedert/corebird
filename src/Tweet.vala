using Gtk;


class Tweet : GLib.Object{
	public string id;
	public bool retweeted = false;
	public bool favorited = false;
	public string text;
	public int user_id;
	public string user_name;
	public string retweeted_by;
	public bool is_retweet;
	public Gdk.Pixbuf avatar;

	public Tweet(){
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

	public void load_avatar(){
		if (Twitter.avatars.has_key(user_id))
			this.avatar = Twitter.avatars.get(user_id);
		else{
			string path = "assets/avatars/%d.png".printf(user_id);
			File f = File.new_for_path(path);
			if(f.query_exists()){
				Twitter.avatars.set(user_id,
				    new Gdk.Pixbuf.from_file(path));
				this.avatar = Twitter.avatars.get(user_id);
			}
		}
	}

	public bool has_avatar(){
		return this.avatar != Twitter.no_avatar;
	}

}



class TweetRenderer : Gtk.CellRenderer {
	private static const int PADDING = 5;
	public Tweet tweet {get; set;}
	public Pango.FontDescription font {get; set;}
	public Pango.FontDescription from_font {get; set;}
	public Pango.FontDescription rt_font {get; set;}

	public TweetRenderer(){
		GLib.Object();
		this.font = Pango.FontDescription.from_string("'Droid Sans' 9");
		this.from_font = Pango.FontDescription.from_string("'Droid Sans' Bold 9.5");
		this.rt_font = Pango.FontDescription.from_string("'Droi Sans' 7.5");
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
		from_layout.set_font_description(this.from_font);
		from_layout.set_text(tweet.user_name, -1);
		Pango.cairo_show_layout(c, from_layout);
		from_layout.get_extents(null, out size);

		c.move_to(background_area.x + 2* PADDING + tweet.avatar.get_width(),
		          background_area.y + PADDING + (size.height / Pango.SCALE) + 3);


		// Draw the actual text
		Pango.Layout layout = Pango.cairo_create_layout(c);
		layout.set_font_description(this.font);
		layout.set_width((cell_area.width - 3*PADDING -
			Twitter.no_avatar.get_width()) * Pango.SCALE);
		layout.set_font_description(font);
		layout.set_text(tweet.text, tweet.text.length);
		Pango.cairo_show_layout(c, layout);


		// If the tweet is a retweet, we need so show who retweeted it.
		if(tweet.is_retweet){
			Pango.Layout rt_layout = Pango.cairo_create_layout(c);
			rt_layout.set_text("RT by "+tweet.retweeted_by, -1);
			rt_layout.set_font_description(rt_font);
			rt_layout.get_extents(null, out size);
			c.move_to(background_area.x+PADDING,
			          background_area.y + background_area.height - PADDING - (size.height / Pango.SCALE));
			Pango.cairo_show_layout(c, rt_layout);
		}

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