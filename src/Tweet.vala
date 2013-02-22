using Gtk;

// TODO: Make tweet loading in the main-timeline work!
// TODO: Look at EggListBox's source code
class Tweet : GLib.Object{
	public static const int THUMB_SIZE    = 50;

	public static const int TYPE_NORMAL   = 1;
	public static const int TYPE_MENTION  = 2;
	public static const int TYPE_FAVORITE = 3;

	private static SQLHeavy.Query cache_query;
	private static SQLHeavy.Query author_query;
	private static GLib.Regex link_regex;


	public int64 id;
	public int64 rt_id;
	public bool retweeted = false;
	public bool favorited = false;
	public string text;
	public int64 user_id;
	public string user_name;
	public string retweeted_by;
	public bool is_retweet;
	public Gdk.Pixbuf avatar {get; set;}
	public string time_delta = "-1s";
	/** The avatar url on the server */
	public string avatar_url;
	/** The name of the avatar image file on the hard disk */
	public string avatar_name;
	public string screen_name;
	public int64 created_at;
	public int64 rt_created_at;

    /** if 0, this tweet is NOT part of a conversation */
    public int64 reply_id = 0;
    public string media;
    public signal void inline_media_added(Gdk.Pixbuf? media);


	public Tweet(){
		this.avatar = Twitter.no_avatar;
		if(cache_query == null){
			try {
				cache_query = new SQLHeavy.Query(Corebird.db,
				"REPLACE INTO `cache`(`id`, `text`,`user_id`, `user_name`, `is_retweet`,
				                     `retweeted_by`, `retweeted`, `favorited`,
				                     `created_at`,`rt_created_at`, `avatar_name`,
				                     `screen_name`, `type`,`rt_id`, `reply_id`)
				VALUES (:id, :text, :user_id, :user_name, :is_retweet, :retweeted_by,
				        :retweeted, :favorited, :created_at, :rt_created_at, :avatar_name,
				        :screen_name, :type, :rt_id, :reply_id);");
				author_query = new SQLHeavy.Query(Corebird.db,
				"SELECT `id`, `screen_name`, `avatar_url` FROM `people`
				WHERE `id`=:id;");
			} catch (SQLHeavy.Error e) {
				critical(e.message);
			}
		}
	}

	public void load_avatar(Gdk.Pixbuf? pixbuf = null){
		if(pixbuf != null){
			Twitter.avatars.set(avatar_name, pixbuf);
			this.avatar = pixbuf;
			return;
		}

		if (Twitter.avatars.has_key(avatar_name)){
		 	this.avatar = Twitter.avatars.get(avatar_name);
		 }else{
			string path = Utils.get_user_file_path("assets/avatars/"+avatar_name);
			if(FileUtils.test(path, FileTest.EXISTS)){
				try{
					Twitter.avatars.set(avatar_name, new Gdk.Pixbuf.from_file(path));
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
	 * @param status The Json object to get the data from
	 * @param now The current time
	 */
	public void load_from_json(Json.Object status, GLib.DateTime now){
		Json.Object user = status.get_object_member("user");
		this.text        = status.get_string_member("text");
		this.favorited   = status.get_boolean_member("favorited");
		this.retweeted   = status.get_boolean_member("retweeted");
		this.id          = status.get_int_member("id");
		this.user_name   = user.get_string_member("name");
		this.user_id     = user.get_int_member("id");
		this.screen_name = user.get_string_member("screen_name");
		this.created_at  = Utils.parse_date(status.get_string_member("created_at"))
										.to_unix();
		this.avatar_url  = user.get_string_member("profile_image_url");
        if(!status.get_null_member("in_reply_to_status_id"))
                this.reply_id  = status.get_int_member("in_reply_to_status_id");


		if (status.has_member("retweeted_status")){
			Json.Object rt      = status.get_object_member("retweeted_status");
			Json.Object rt_user = rt.get_object_member("user");
			this.is_retweet    = true;
			this.rt_id         = rt.get_int_member("id");
			this.retweeted_by  = user.get_string_member("name");
			this.text          = rt.get_string_member("text");
			this.user_name     = rt_user.get_string_member ("name");
			this.avatar_url    = rt_user.get_string_member("profile_image_url");
			this.user_id       = rt_user.get_int_member("id");
			this.screen_name   = rt_user.get_string_member("screen_name");
			this.rt_created_at = Utils.parse_date(rt.get_string_member("created_at"))
			                            .to_unix();
            if(!rt.get_null_member("in_reply_to_status_id"))
                                this.reply_id = rt.get_int_member("in_reply_to_status_id");
		}
		this.avatar_name = Utils.get_avatar_name(this.avatar_url);



		// 'Resolve' the used URLs
		var entities = status.get_object_member("entities");

		var urls = entities.get_array_member("urls");
		urls.foreach_element((arr, index, node) => {
			var url = node.get_object();
			string expanded_url = url.get_string_member("expanded_url");
			// message("Text: %s, expanded: %s", this.text, expanded_url);
			expanded_url = expanded_url.replace("&", "&amp;");
			if(Settings.show_inline_media() &&
			   expanded_url.has_prefix("http://instagr.am")) {
				load_instagram_media.begin(expanded_url);
			}
			if(Settings.show_inline_media() &&
			   expanded_url.has_prefix("http://i.imgur.com")) {
				load_inline_media.begin(expanded_url);
			}
			this.text = this.text.replace(url.get_string_member("url"),
			    expanded_url);
		});

		// The same with media
		if(entities.has_member("media")){
			var medias = entities.get_array_member("media");
			medias.foreach_element((arr, index, node) => {
				var url = node.get_object();
				string expanded_url = "https://"+url.get_string_member("display_url");
				expanded_url = expanded_url.replace("&", "&amp;");
				this.text = this.text.replace(url.get_string_member("url"),
				    expanded_url);
				if(Settings.show_inline_media()) {
					load_inline_media.begin(url.get_string_member("media_url"));
				}
			});
		}




		var dt = new DateTime.from_unix_local(is_retweet ? rt_created_at : created_at);
		this.time_delta  = Utils.get_time_delta(dt, now);


		this.load_avatar();
		if(!this.has_avatar()){
			string dest = Utils.get_user_file_path("assets/avatars/"+this.avatar_name);
			GLib.Idle.add(() => {
				try{
					var session = new Soup.SessionAsync();
					var msg     = new Soup.Message("GET", this.avatar_url);
					session.send_message(msg);

					var memory_stream = new MemoryInputStream.from_data(msg.response_body.data,
					                                                    null);
					var pixbuf = new Gdk.Pixbuf.from_stream_at_scale(memory_stream, 48, 48,
					                                                 false);
					pixbuf.save(dest, Utils.get_file_type(avatar_name));
					this.load_avatar(pixbuf);
					message("Loaded avatar for %s", screen_name);
				} catch (GLib.Error e) {
					critical(e.message);
				}
				return false;
			});
		}
	}

	/**
	 * Caches the given tweet by writing it into the database.
	 *
	 * @param t The tweet to cache.
	 * @param type The type of the tweet, see Tweet.TYPE_* constants.
	 *
	 */
	public static void cache(Tweet t, int type){
		// Check the tweeter's details and update them if necessary
		try{
			author_query.set_int64(":id", t.user_id);
			SQLHeavy.QueryResult author_result = author_query.execute();
			if (author_result.finished){
				//The author is not in the DB so we insert him
				// message("Inserting new author %s", t.screen_name);
				Corebird.db.execute("INSERT INTO `people`(id,name,screen_name,avatar_url,
				                    avatar_name) VALUES ('%d', '%s', '%s', '%s', '%s');",
				                    t.user_id, t.user_name, t.screen_name, t.avatar_url,
				                    t.avatar_name);
			}else{
				string old_avatar = author_result.fetch_string(2);
				if (old_avatar != t.avatar_url){
					Corebird.db.execute("UPDATE `people` SET `avatar_url`='%s'
					                    WHERE `id`='%d';", t.avatar_url, t.user_id);
				}
				if (t.user_name != author_result.fetch_string(1)){
					Corebird.db.execute("UPDATE `people` SET `screen_name`='%s'
					                    WHERE `id`='%d';", t.user_name, t.user_id);
				}
			}
		}catch(SQLHeavy.Error e){
			warning("Error while updating author: %s", e.message);
		}


		// Insert tweet into cache table
		try{
			cache_query.set_int64(":id", t.id);
			cache_query.set_int64(":rt_id", t.rt_id);
			cache_query.set_string(":text", t.text);
			cache_query.set_int64(":user_id", t.user_id);
			cache_query.set_string(":user_name", t.user_name);
			cache_query.set_int(":is_retweet", t.is_retweet ? 1 : 0);
			cache_query.set_string(":retweeted_by", t.retweeted_by);
			cache_query.set_int(":retweeted", t.retweeted ? 1 : 0);
			cache_query.set_int(":favorited", t.favorited ? 1 : 0);
			cache_query.set_int64(":created_at", t.created_at);
			cache_query.set_int64(":rt_created_at", t.rt_created_at);
			// TODO: Set the avatar_url
			cache_query.set_string(":avatar_name", t.avatar_name);
			cache_query.set_string(":screen_name", t.screen_name);
			cache_query.set_int(":type", type); // 1 = normal tweet
			cache_query.set_int64(":reply_id", t.reply_id);
			cache_query.execute();
		}catch(SQLHeavy.Error e){
			error("Error while caching tweet: %s", e.message);
		}
	}

	private async void load_inline_media(string url) {
		var session = new Soup.SessionAsync();
		var msg     = new Soup.Message("GET", url);

		session.queue_message(msg, (s, m) => {
			try {
				var ms    = new MemoryInputStream.from_data(m.response_body.data, null);
				var pic   = new Gdk.Pixbuf.from_stream(ms);
				var thumb = pic.scale_simple(THUMB_SIZE, THUMB_SIZE, Gdk.InterpType.TILES);
				string path = Utils.get_user_file_path("assets/media/"+id.to_string()+
														"_"+user_id.to_string()+".png");
				string thumb_path = Utils.get_user_file_path("assets/media/thumbs/"+
															id.to_string()+
														"_"+user_id.to_string()+".png");
				Corebird.db.execute("UPDATE `cache` SET `media`='%s' WHERE `id`='%s';"
											.printf(path, this.id.to_string()));
				this.media = path;
				pic.save(path, "png");
				thumb.save(thumb_path, "png");
				inline_media_added(thumb);
			} catch (GLib.Error e) {
				critical(e.message);
			}
		});
	}

	private async void load_instagram_media(string url) {
		message("Loading instagram media...");
		var session = new Soup.SessionAsync();
		var msg = new Soup.Message("GET", url);
		session.queue_message(msg, (s,m) => {
			try {
				string back = (string)m.response_body.data;
				GLib.Regex regex = new GLib.Regex(
					"<img class=\"photo\" src=\"(.*?)\"", RegexCompileFlags.OPTIMIZE);
				MatchInfo mi;
				regex.match(back, 0, out mi);
				string link = mi.fetch(1);
				load_inline_media.begin(link);
			}catch (GLib.Error e) {
				critical(e.message);
			}
		});
	}

	/**
	 * Replaces the links in the given text with html tags to be used in
	 * pango layouts.
	 *
	 * @param text The text to replace the links in
	 * @return The text with replaced links
	 */
	public static string replace_links(string text){
		if(link_regex == null){
			//TODO: Most regexes can be truly static.
			link_regex = new GLib.Regex("http[s]{0,1}:\\/\\/[a-zA-Z\\_.\\+\\?\\/#=&;\\-0-9%,~]+",
			                            RegexCompileFlags.OPTIMIZE);
		}
		string real_text = text;
		try{
			MatchInfo mi;
			if (link_regex.match(real_text, 0, out mi)){
				do{

					string link = mi.fetch(0);
					if (link.length > 25){
						if(link.has_prefix("http://"))
							link = link.substring(7);
						else //https
							link = link.substring(8);

						if(link.has_prefix("www."))
							link = link.substring(4);

						if(link.length > 25){
							link = link.substring(0, 25);
							link += "…";
						}

					}
					real_text = real_text.replace(mi.fetch(0),
						"<a href='%s'>%s</a>".printf(mi.fetch(0), link));
				}while(mi.next());
			}

		}catch(GLib.RegexError e){
			warning("Error while applying regexes: %s", e.message);
		}

		return real_text;
	}
}