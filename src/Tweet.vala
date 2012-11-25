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
	public string time_delta = "0s";

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
				try{
					Twitter.avatars.set(user_id,
				    	new Gdk.Pixbuf.from_file(path));
				}catch(GLib.Error e){
					warning("Error while loading avatar from database: %s", e.message);
				}
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
	// public Pango.FontDescription font {get; set;}
	// public Pango.FontDescription from_font {get; set;}
	// public Pango.FontDescription rt_font {get; set;}
	private Regex hashtag_regex;

	public TweetRenderer(){
		GLib.Object();
		hashtag_regex = new Regex("#\\w+", RegexCompileFlags.OPTIMIZE);
		// this.font = Pango.FontDescription.from_string("'Droid Sans' 9");
		// this.from_font = Pango.FontDescription.from_string("'Droid Sans' Bold 9.5");
		// this.rt_font = Pango.FontDescription.from_string("'Droi Sans' 7.5");
	}

	public override void render (Cairo.Context c, Widget tree,
								 Gdk.Rectangle background_area,
								 Gdk.Rectangle cell_area,
							 	 CellRendererState flags) {
		Pango.Rectangle size;
		Gdk.Pixbuf? status_pixbuf = tweet.get_status_pixbuf();
		StyleContext style = tree.get_style_context();
		

		style.render_background(c, background_area.x, background_area.y,
		                      background_area.width, background_area.height);
		style.render_frame(c, background_area.x, background_area.y,
		                      background_area.width, background_area.height);

		if(status_pixbuf != null){
			style.render_icon(c, status_pixbuf, background_area.x+background_area.width-Twitter.retweeted_img.width,
			                  background_area.y);
		}

		//Draw the avatar
		style.render_icon(c, tweet.avatar, background_area.x + PADDING, background_area.y + PADDING);

		// Draw the tweet's author
		// style.add_class("from");
		Pango.Layout from_layout = tree.create_pango_layout(tweet.user_name);
		from_layout.set_markup("<b>"+tweet.user_name+"</b>", -1);
		style.render_layout(c, background_area.x + 2*PADDING + tweet.avatar.get_width(),
		                    background_area.y + PADDING, from_layout);
		from_layout.get_extents(null, out size);
		// style.remove_class("from");

		// Draw the actual text
		// style.add_class("tweet");
		string text = hashtag_regex.replace(tweet.text, tweet.text.length, 0, "<span foreground=\"blue\">\\0</span>");
		Pango.Layout layout = tree.create_pango_layout("");
		layout.set_markup(text, -1);
		layout.set_width((cell_area.width - 3*PADDING -
			Twitter.no_avatar.get_width()) * Pango.SCALE);

		style.render_layout(c, background_area.x + 2* PADDING + tweet.avatar.get_width(),
		          background_area.y + PADDING + (size.height / Pango.SCALE) + 3, layout);
		// style.remove_class("tweet");

		// Draw how long ago the tweet was created
		Pango.Layout delta_layout = tree.create_pango_layout(tweet.time_delta);
		delta_layout.set_markup("<span size=\"small\">"+tweet.time_delta+"</span>", -1);
		style.render_layout(c, background_area.x + PADDING, background_area.y + PADDING + tweet.avatar.get_height() + 5,
		                    delta_layout);

		// If the tweet is a retweet, we need so show who retweeted it.
		if(tweet.is_retweet){
			Pango.Layout rt_layout = tree.create_pango_layout("");
			rt_layout.set_markup("<span size=\"small\">RT by "+tweet.retweeted_by+"</span>", -1);
			rt_layout.get_extents(null, out size);
			style.render_layout(c, background_area.x+background_area.width-PADDING - (size.width/Pango.SCALE),
			          background_area.y + PADDING, rt_layout);
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