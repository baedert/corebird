using Gtk;


//TODO: If the list is completely empty and you add more items than the page can handle, the scrollWidget
//      scrolls DOWN but it should stay at the top.
class StreamContainer : TweetContainer{

	public StreamContainer(){
		base();
		if(Settings.refresh_streams_on_startup())
			load_new_tweets.begin();

		//Start the update timeout
		int minutes = Settings.get_update_interval();
		GLib.Timeout.add(minutes * 60 * 1000, () => {
			load_new_tweets.begin(false);
			return true;
		});
		this.add_with_viewport(tweet_list);
	}

	public void load_cached_tweets() throws SQLHeavy.Error{
		GLib.DateTime now = new GLib.DateTime.now_local();

		SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
			"SELECT `id`, `text`, `user_id`, `user_name`, `is_retweet`,
					`retweeted_by`, `retweeted`, `favorited`, `created_at`,
					`added_to_stream`, `avatar_name`, `screen_name`, `type` FROM `cache`
			WHERE `type`='1' 
			ORDER BY `added_to_stream` DESC LIMIT 30");
		SQLHeavy.QueryResult result = query.execute();
		while(!result.finished){
			Tweet t        = new Tweet();
			t.id           = result.fetch_string(0);
			t.text         = result.fetch_string(1);
			t.user_id      = result.fetch_int(2);
			t.user_name    = result.fetch_string(3);
			t.is_retweet   = (bool)result.fetch_int(4);
			t.retweeted_by = result.fetch_string(5);
			t.retweeted    = (bool)result.fetch_int(6);
			t.favorited    = (bool)result.fetch_int(7);

			GLib.DateTime created = Utils.parse_date(result.fetch_string(8));
			t.time_delta = Utils.get_time_delta(created, now);
			t.avatar_name  = result.fetch_string(10); 
			t.screen_name = result.fetch_string(11);
			t.load_avatar();

			// Append the tweet to the TweetList
			TweetListEntry list_entry = new TweetListEntry(t, main_window);
			tweet_list.add_item(list_entry);	
			result.next();
		}
	}

	public async void load_new_tweets(bool add_spinner = true) throws SQLHeavy.Error {
		if (add_spinner){
			GLib.Idle.add( () => {
				tweet_list.show_spinner();
				return false;
			});
		}
		

		SQLHeavy.Query id_query = new SQLHeavy.Query(Corebird.db,
		 	"SELECT `id`, `added_to_stream` FROM `cache` 
		 	WHERE `type`='1' ORDER BY `added_to_stream` DESC LIMIT 1;");
		SQLHeavy.QueryResult id_result = id_query.execute();
		int64 greatest_id = id_result.fetch_int64(0);
		message("greatest_id: %s", greatest_id.to_string());

		var call = Twitter.proxy.new_call();
		call.set_function("1.1/statuses/home_timeline.json");
		call.set_method("GET");
		call.add_param("count", "10");
		call.add_param("contributor_details", "true");
		if(greatest_id > 0)
			call.add_param("since_id", greatest_id.to_string());

		call.invoke_async.begin(null, () => {
			string back = call.get_payload();
			stdout.printf(back+"\n");
			var parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			}catch(GLib.Error e){
				warning("Problem with json data from twitter: %s", e.message);
				return;
			}
			if (parser.get_root().get_node_type() != Json.NodeType.ARRAY){
				warning("Root node is no Array.");
				warning("Back: %s", back);
				return;
			}

			//TODO: The queries in that lambda can ALL be cached, but that kinda breaks.
			//	Find out how. Probably works now that it's in Tweet
			var root = parser.get_root().get_array();
			var loader_thread = new LoaderThread(root, main_window, tweet_list, 1, (num)=> {
				if(num > 0 && Settings.notify_new_tweets()&& !main_window.has_toplevel_focus){
					string tweets = "Tweets";
					if(num == 1)
						tweets = "Tweet";
					NotificationManager.notify("%d new %s".printf(num, tweets));
				}
			});
			loader_thread.run();
		});
	}


	public override void refresh(){
		load_new_tweets.begin();
	}

	public override void load_cached(){
		load_cached_tweets();
	}

	public override RadioToolButton? get_tool_button(){
		return null;
	}
}