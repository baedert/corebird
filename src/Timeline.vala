

/**
 * Describes everything a timeline should provide, in an abstract way.
 * Default implementations are given through the *_internal methods.
 */
interface Timeline : Gtk.Widget {
	protected abstract int64 max_id{get;set;}
	public    abstract MainWindow main_window{get;set;}
	protected abstract Egg.ListBox tweet_list{get;set;}


	public abstract void load_cached();
	public abstract void load_newest();
	public abstract void load_older ();
	public abstract void create_tool_button(Gtk.RadioToolButton? group);
	public abstract int get_id();
	public abstract Gtk.RadioToolButton? get_tool_button();


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
			`rt_created_at`, `avatar_name`, `screen_name`, `type`
			FROM `cache` WHERE `type`='$tweet_type'
			ORDER BY `created_at` DESC LIMIT 15");
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


			if(t.id < max_id)
				max_id = t.id;

			int64 created = -1;
			if(t.is_retweet)
				created = result.fetch_int64(9);
			else
				created = t.created_at;

			// GLib.DateTime created = Utils.parse_date(result.fetch_string(8));
			t.time_delta   = Utils.get_time_delta(new DateTime.from_unix_local(created), now);
			t.avatar_name  = result.fetch_string(10);
			t.screen_name  = result.fetch_string(11);
			t.load_avatar();

			// Append the tweet to the TweetList
			TweetListEntry list_entry = new TweetListEntry(t, main_window);
			list_entry.visible = true;
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
	protected void load_newest_internal(string function, int tweet_type) {
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
				warning("Problem with json data from twitter: %s", e.message);
				return;
			}
			if (parser.get_root().get_node_type() != Json.NodeType.ARRAY){
				warning("Root node is no Array.");
				warning("Back: %s", back);
				return;
			}

			var root = parser.get_root().get_array();
			var loader_thread = new LoaderThread(root, main_window,
												 tweet_list, tweet_type);
			loader_thread.run();
		});
	}

	/**
	 * Default implementation to load older tweets using
	 * the max_id method from the given function
	 *
	 * @param function The Twitter function to use
	 * @param max_id The highest id of tweets to receive
	 */
	protected void load_older_internal(string function, int max_id) {

	}

}