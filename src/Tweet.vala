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
	public string avatar_url;
	public string avatar_name;
	public string screen_name;

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
		if (Twitter.avatars.has_key(avatar_name))
			this.avatar = Twitter.avatars.get(avatar_name);
		else{
			string path = "assets/avatars/%s".printf(avatar_name);
			File f = File.new_for_path(path);
			if(f.query_exists()){
				try{
					Twitter.avatars.set(avatar_name,
				    	new Gdk.Pixbuf.from_file(path));
				}catch(GLib.Error e){
					warning("Error while loading avatar from database: %s", e.message);
				}
				this.avatar = Twitter.avatars.get(avatar_name);
			}
		}
	}

	public bool has_avatar(){
		return this.avatar != Twitter.no_avatar;
	}

	/**
	 * Fills all the data of this tweet from Json data.
	 */
	public void load_from_json(Json.Object status, GLib.DateTime now,
	            	out string created_at, out int64 added_to_stream){
		Json.Object user = status.get_object_member("user");
		this.text = status.get_string_member("text");
		this.favorited = status.get_boolean_member("favorited");
		this.retweeted = status.get_boolean_member("retweeted");
		this.id = status.get_string_member("id_str");
		this.user_name = user.get_string_member("name");
		this.user_id = (int)user.get_int_member("id");
		this.screen_name = user.get_string_member("screen_name");
		created_at = status.get_string_member("created_at");
		string display_name = user.get_string_member("screen_name");
		added_to_stream = Utils.parse_date(created_at).to_unix();

		this.avatar_url = user.get_string_member("profile_image_url");
		this.avatar_name = this.avatar_url.substring(this.avatar_url.last_index_of("/") + 1);



		if (status.has_member("retweeted_status")){
			Json.Object rt = status.get_object_member("retweeted_status");
			this.is_retweet = true;
			this.retweeted_by = user.get_string_member("name");
			this.text = rt.get_string_member("text");
			this.id = rt.get_string_member("id_str");
			Json.Object rt_user = rt.get_object_member("user");
			this.user_name = rt_user.get_string_member ("name");
			this.avatar_url = rt_user.get_string_member("profile_image_url");
			this.avatar_name = this.avatar_url.substring(this.avatar_url.last_index_of("/") + 1);
			this.user_id = (int)rt_user.get_int_member("id");
			this.screen_name = rt_user.get_string_member("screen_name");
			created_at = rt.get_string_member("created_at");
			display_name = rt_user.get_string_member("screen_name");
		}
		GLib.DateTime dt = Utils.parse_date(created_at);
		this.time_delta = Utils.get_time_delta(dt, now);


		this.load_avatar();
		if(!this.has_avatar()){
			// message("Downloading avatar for %s", t.user_name);
			File av = File.new_for_uri(this.avatar_url);
			// stdout.printf("assets/avatars/%s".printf(t.avatar_name));
			File dest = File.new_for_path("assets/avatars/%s".printf(this.avatar_name));
			try{
				av.copy(dest, FileCopyFlags.OVERWRITE); 
			}catch(GLib.Error e){
				warning("Problem while downloading avatar: %s", e.message);
			}
			this.load_avatar();
		}
	}

}