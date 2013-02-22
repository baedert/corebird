

/**
 * Describes everything a timeline should provide, in an abstract way.
 * Default implementations are given through the *_internal methods.
 */
interface ITimeline : Gtk.Widget, IPage {
	protected abstract int64 max_id{get;set;}
	public    abstract MainWindow main_window{get;set;}
	protected abstract Egg.ListBox tweet_list{get;set;}

	public abstract void load_cached();
	public abstract void load_newest();
	public abstract void load_older ();


	protected void start_updates(bool notify, string function, int tweet_type) {
		GLib.Timeout.add(Settings.get_update_interval() * 1000 * 60, () => {
			try {
				load_newest_internal(function, tweet_type, (count) => {
					//Update all current tweets
					tweet_list.forall_internal(false, (w) => {
						((TweetListEntry)w).update_time_delta();
					});
					if(count > 0)
						NotificationManager.notify("%d new tweets!".printf(count));
				});
			} catch(SQLHeavy.Error e) {
				warning(e.message);
			}
			return true;
		});
	}


	/**
	 * Default implementation to load cached tweets from the
	 * 'cache' sql table
	 *
	 * @param tweet_type The type of tweet to load
	 */
	protected void load_cached_internal(int tweet_type) throws SQLHeavy.Error {
		GLib.DateTime now = new GLib.DateTime.now_local();

		SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
			@"SELECT `id`, `text`, `user_id`, `user_name`, `is_retweet`,
			`retweeted_by`, `retweeted`, `favorited`, `created_at`,
			`rt_created_at`, `avatar_name`, `screen_name`, `type`,
			`reply_id`, `media`, `rt_id`, `reply_id`
			FROM `cache` WHERE `type`='$tweet_type'
			ORDER BY `created_at` DESC LIMIT 15;");
		SQLHeavy.QueryResult result = query.execute();
		while(!result.finished){
			Tweet t        = new Tweet();
			t.id           = result.fetch_int64(0);
			t.text         = result.fetch_string(1);
			t.user_id      = result.fetch_int64(2);
			t.user_name    = result.fetch_string(3);
			t.is_retweet   = (bool)result.fetch_int(4);
			t.retweeted_by = result.fetch_string(5);
			t.retweeted    = (bool)result.fetch_int(6);
			t.favorited    = (bool)result.fetch_int(7);
			t.created_at   = result.fetch_int64(8);
			t.reply_id     = result.fetch_int64(13);
			t.media        = result.fetch_string(14);
			t.rt_id		   = result.fetch_int64(15);
			t.reply_id     = result.fetch_int64(16);




			if(t.id < max_id)
				max_id = t.id;

			int64 created = -1;
			if(t.is_retweet)
				created = result.fetch_int64(9);
			else
				created = t.created_at;

			t.time_delta   = Utils.get_time_delta(new DateTime.from_unix_local(created),
												  now);
			t.avatar_name  = result.fetch_string(10);
			t.screen_name  = result.fetch_string(11);
			t.load_avatar();

			// Append the tweet to the TweetList
			TweetListEntry list_entry = new TweetListEntry(t, main_window);
			if(t.media != null){
				string thumb_path = Utils.get_user_file_path("assets/media/thumbs/"+
							Utils.get_file_name(t.media));
				try {
					t.inline_media_added(new Gdk.Pixbuf.from_file(thumb_path));
				} catch (GLib.Error e) {
					warning(e.message);
				}
			}
			tweet_list.add(list_entry);
			result.next();
		}
	}

	/**
	 * Default implementation for loading the newest tweets
	 * from the given function of the twitter api.
	 *
	 * @param function The twitter function to use
	 * @param tweet_type The type of tweets to load
	 */
	protected void load_newest_internal(string function, int tweet_type,
	                                    LoaderThread.EndLoadFunc? end_load_func = null)
	                                    throws SQLHeavy.Error {
		SQLHeavy.Query id_query = new SQLHeavy.Query(Corebird.db,
		 	@"SELECT `id`, `created_at` FROM `cache`
		 	WHERE `type`='$tweet_type' ORDER BY `created_at` DESC LIMIT 1;");
		SQLHeavy.QueryResult id_result = id_query.execute();
		int64 greatest_id = id_result.fetch_int64(0);
		message("greatest_id: %s", greatest_id.to_string());

		var call = Twitter.proxy.new_call();
		call.set_function(function);
		call.set_method("GET");
		call.add_param("count", "20");
		call.add_param("contributor_details", "true");
		if(greatest_id > 0)
			call.add_param("since_id", greatest_id.to_string());

		call.invoke_async.begin(null, () => {
			string back = call.get_payload();
			stdout.printf(back+"\n");
			var parser = new Json.Parser();
			try {
				parser.load_from_data(back);
			} catch(GLib.Error e) {
				stdout.printf(back+"\n");
				critical("Problem with json data from twitter: %s", e.message);
				return;
			}

			var root = parser.get_root().get_array();
			var loader_thread = new LoaderThread(root, main_window,
												 tweet_list, tweet_type);
			loader_thread.run(end_load_func);
		});
	}

	/**
	 * Default implementation to load older tweets using
	 * the max_id method from the given function
	 *
	 * @param function The Twitter function to use
	 * @param max_id The highest id of tweets to receive
	 */
	protected void load_older_internal(string function, int tweet_type,
	                                   LoaderThread.EndLoadFunc? end_load_func = null) {
		// return;
		var call = Twitter.proxy.new_call();
		call.set_function(function);
		call.set_method("GET");
		message(@"using max_id: $max_id");
		call.add_param("max_id", (max_id - 1).to_string());
		call.invoke_async.begin(null, (obj, result) => {
			try{
				call.invoke_async.end(result);
			} catch (GLib.Error e) {
				critical(e.message);
				critical("Code: %u", call.get_status_code());
			}


			string back = call.get_payload();
			var parser = new Json.Parser();
			try{
				parser.load_from_data (back);
			} catch (GLib.Error e) {
				stdout.printf (back+"\n");
				critical(e.message);
			}

			var root = parser.get_root().get_array();
			var loader_thread = new LoaderThread(root, main_window, tweet_list,
			                                     tweet_type);
			loader_thread.run(end_load_func);
		});
	}

}