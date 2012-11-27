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
	public string time_delta = "-1s";
	public int retweets;
	public int favorites;

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