using Gtk;

// TODO: Make tweet loading in the main-timeline work!
// TODO: Look at EggListBox's source code
class Tweet : GLib.Object{
	public static int TYPE_NORMAL   = 1;
	public static int TYPE_MENTION  = 2;
	public static int TYPE_FAVORITE = 3;

	private static SQLHeavy.Query cache_query;
	private static SQLHeavy.Query author_query;
	private static GLib.Regex link_regex;


	public int64 id;
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

	public Tweet(){
		this.avatar = Twitter.no_avatar;
		if(cache_query == null){
			cache_query = new SQLHeavy.Query(Corebird.db,
			"INSERT INTO `cache`(`id`, `text`,`user_id`, `user_name`, `is_retweet`,
			                     `retweeted_by`, `retweeted`, `favorited`, `created_at`,
			                     `added_to_stream`, `avatar_name`, `screen_name`, `type`) 
			VALUES (:id, :text, :user_id, :user_name, :is_retweet, :retweeted_by,
			        :retweeted, :favorited, :created_at, :added_to_stream, :avatar_name,
			        :screen_name, :type);");		
			author_query = new SQLHeavy.Query(Corebird.db,
			"SELECT `id`, `screen_name`, `avatar_url` FROM `people`
			WHERE `id`=:id;");			
		}
	}

	public void load_avatar(){
		if (Twitter.avatars.has_key(avatar_name))
			this.avatar = Twitter.avatars.get(avatar_name);
		else{
			string path = "assets/avatars/%s".printf(avatar_name);
			if(FileUtils.test(path, FileTest.EXISTS)){
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
	 * @param status The Json object to get the data from
	 * @param now The current time
	 * @param created_at When the tweet was created
	 * @param added_to_stream when the tweet was added to the stream
	 */
	public void load_from_json(Json.Object status, GLib.DateTime now,
	            	out string created_at, out int64 added_to_stream){
		Json.Object user    = status.get_object_member("user");
		this.text           = status.get_string_member("text");
		this.favorited      = status.get_boolean_member("favorited");
		this.retweeted      = status.get_boolean_member("retweeted");
		this.id             = status.get_int_member("id");
		this.user_name      = user.get_string_member("name");
		this.user_id        = (int)user.get_int_member("id");
		this.screen_name    = user.get_string_member("screen_name");
		created_at          = status.get_string_member("created_at");
		added_to_stream     = Utils.parse_date(created_at).to_unix();
		this.avatar_url     = user.get_string_member("profile_image_url");



		var entities = status.get_object_member("entities");
		if (status.has_member("retweeted_status")){
			Json.Object rt      = status.get_object_member("retweeted_status");
			Json.Object rt_user = rt.get_object_member("user");
			this.is_retweet   = true;
			this.retweeted_by = user.get_string_member("name");
			this.text         = rt.get_string_member("text");
			this.user_name    = rt_user.get_string_member ("name");
			this.avatar_url   = rt_user.get_string_member("profile_image_url");
			this.user_id      = (int)rt_user.get_int_member("id");
			this.screen_name  = rt_user.get_string_member("screen_name");
			created_at        = rt.get_string_member("created_at");
			entities 		  = rt.get_object_member("entities");
		}
		this.avatar_name = Utils.get_avatar_name(this.avatar_url);



		// 'Resolve' the used URLs
		
		var urls = entities.get_array_member("urls");
		urls.foreach_element((arr, index, node) => {
			var url = node.get_object();
			string expanded_url = url.get_string_member("expanded_url");
			// message("Text: %s, expanded: %s", this.text, expanded_url);	
			expanded_url = expanded_url.replace("&", "&amp;");
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
			});
		}




		GLib.DateTime dt = Utils.parse_date(created_at);
		this.time_delta  = Utils.get_time_delta(dt, now);


		this.load_avatar();
		if(!this.has_avatar()){
			// File dest = File.new_for_path("assets/avatars/"+this.avatar_name);
			string dest = "assets/avatars/"+this.avatar_name;
			// FileIOStream io_stream = dest.create_readwrite(FileCreateFlags.PRIVATE);
			GLib.Idle.add(() => {
				var session = new Soup.SessionAsync();
				var msg = new Soup.Message("GET", this.avatar_url);
				session.send_message(msg);
				
				var memory_stream = new MemoryInputStream.from_data(msg.response_body.data,
				                                                    null);
				var pixbuf = new Gdk.Pixbuf.from_stream_at_scale(memory_stream, 48, 48, 
				                                                 false);
				pixbuf.save(dest, Utils.get_file_type(avatar_name));
				this.load_avatar();
				message("Loaded avatar for %s", screen_name);
				return false;
			});

			//Make the corners round
			// TODO: How to write it as gif/jpg file?
			// Cairo.ImageSurface frame = new Cairo.ImageSurface.from_png("assets/frame.png");
			// Cairo.ImageSurface result = new Cairo.ImageSurface(Cairo.Format.ARGB32, 48, 48);
			// surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 48, 48);
			// Cairo.Context context = new Cairo.Context(result);
			// context.set_source_surface(surface, 0, 0);
			// context.rectangle(0, 0, 48,48);
			// context.fill();


			// context.set_operator(Cairo.Operator.DEST_OUT);
			// context.set_source_surface(frame, 0, 0);
			// context.rectangle(0, 0, 48, 48);
			// context.paint();
			
			// context.fill();

			// result.write_to_png("avatar_changed.png");
		}
	}

	/**
	 * Caches the given tweet by writing it into the database.
	 *
	 * @param t The tweet to cache.
	 * @param created_at The 'created_at' string received from Twitter 
	 * @param added_to_stream A unix timestamp indicating when the tweet was added to the
	 *                        user's timeline
	 * @param type The type of the tweet, see Tweet.TYPE_* constants.
	 * 
	 */
	public static void cache(Tweet t, string created_at, int64 added_to_stream, int type){
		// Check the tweeter's details and update them if necessary
		try{
			author_query.set_int64(":id", t.user_id);
			SQLHeavy.QueryResult author_result = author_query.execute();
			if (author_result.finished){
				//The author is not in the DB so we insert him
				message("Inserting new author %s", t.screen_name);
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
			cache_query.set_string(":text", t.text);
			cache_query.set_int64(":user_id", t.user_id);
			cache_query.set_string(":user_name", t.user_name);
			cache_query.set_int(":is_retweet", t.is_retweet ? 1 : 0);
			cache_query.set_string(":retweeted_by", t.retweeted_by);
			cache_query.set_int(":retweeted", t.retweeted ? 1 : 0);
			cache_query.set_int(":favorited", t.favorited ? 1 : 0);
			cache_query.set_string(":created_at", created_at);
			cache_query.set_int64(":added_to_stream", added_to_stream);
			cache_query.set_string(":avatar_name", t.avatar_name);
			cache_query.set_string(":screen_name", t.screen_name);
			cache_query.set_int(":type", type); // 1 = normal tweet
			cache_query.execute();
		}catch(SQLHeavy.Error e){
			error("Error while caching tweet: %s", e.message);
		}
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
			link_regex = new GLib.Regex("http[s]{0,1}:\\/\\/[a-zA-Z\\_.\\+\\?\\/#=&;\\-0-9%,]+",
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