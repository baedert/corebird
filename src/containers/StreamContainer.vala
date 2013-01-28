using Gtk;


//TODO: If the list is completely empty and you add more items
//		than the page can handle, the scrollWidget
//      scrolls DOWN but it should stay at the top.
class StreamContainer : TweetContainer, ScrollWidget{
	private Egg.ListBox tweet_list = new Egg.ListBox();
	private MainWindow main_window;
	private RadioToolButton tool_button;
	private int id;
	/** If we are currently downloading/processing data */
	private bool loading = false;
	private int64 max_id = int64.MAX;


	public StreamContainer(int id){
		base();
		this.id = id;
		this.hscrollbar_policy = PolicyType.NEVER;

		//Start the update timeout
		int minutes = Settings.get_update_interval();
		GLib.Timeout.add(minutes * 60 * 1000, () => {
			load_new_tweets.begin(false);
			return true;
		});
		this.add_with_viewport(tweet_list);



		

		this.vadjustment.value_changed.connect( () => {
			int max = (int)(this.vadjustment.upper - this.vadjustment.page_size);
			int value = (int)this.vadjustment.value;
			if (value >= (max * 0.9f) && !loading){
				//Load older tweets
				loading = true;
				message("end! %d/%d", value, max);
				// https://dev.twitter.com/docs/working-with-timelines
				load_older_tweets.begin();
				message(":/");
			}
		});
	}

	public void load_cached_tweets() throws SQLHeavy.Error{
		GLib.DateTime now = new GLib.DateTime.now_local();

		SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
			"SELECT `id`, `text`, `user_id`, `user_name`, `is_retweet`,
					`retweeted_by`, `retweeted`, `favorited`, `created_at`,
					`added_to_stream`, `avatar_name`, `screen_name`, `type` FROM `cache`
			WHERE `type`='%d' 
			ORDER BY `added_to_stream` DESC LIMIT 10".printf(Tweet.TYPE_NORMAL));
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


			if(t.id < max_id)
				max_id = t.id;

			GLib.DateTime created = Utils.parse_date(result.fetch_string(8));
			t.time_delta   = Utils.get_time_delta(created, now);
			t.avatar_name  = result.fetch_string(10); 
			t.screen_name  = result.fetch_string(11);
			t.load_avatar();

			// Append the tweet to the TweetList
			TweetListEntry list_entry = new TweetListEntry(t, main_window);
			tweet_list.add(list_entry);	
			result.next();
		}
	}

	public async void load_new_tweets(bool add_spinner = true) throws SQLHeavy.Error {
		if (add_spinner){
			GLib.Idle.add( () => {
				// tweet_list.show_spinner();
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
		call.add_param("count", "20");
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
			var loader_thread = new LoaderThread(root, main_window, 
												 tweet_list, Tweet.TYPE_NORMAL);
			loader_thread.run();
		});
	}


	private async void load_older_tweets() {
		message(@"Loading older tweets(max_id: $max_id)");
		GLib.DateTime now = new GLib.DateTime.now_local();
		var call  = Twitter.proxy.new_call();
		call.set_function("1.1/statuses/home_timeline.json");
		call.set_method("GET");
		call.add_param("count", "3");
		call.add_param("max_id", (max_id - 1).to_string());
		call.add_param("contributor_details", "true");

		call.invoke_async.begin(null, (obj, res) => {
			call.invoke_async.end(res);
			string back = call.get_payload();
			var parser = new Json.Parser();
			parser.load_from_data(back);
			var root = parser.get_root().get_array();
			message("Older tweets: %u", root.get_length());
			root.foreach_element((array, index, node) => {
				var o = node.get_object();
				Tweet t = new Tweet();
				string created_at;
				int64 added_to_stream;
				t.load_from_json(o, now, out created_at, out added_to_stream);
				message(t.user_name);
				tweet_list.add(new TweetListEntry(t, null));
			});
		});
	}



	public void refresh(){
		load_new_tweets.begin();
	}

	public void load_cached(){
		try{
			load_cached_tweets();
		}catch(SQLHeavy.Error e){
			critical("Error while loading cached tweets: %s", e.message);
		}
	}

	public void create_tool_button(RadioToolButton? group){
		GLib.Icon icon = new GLib.FileIcon(File.new_for_path("assets/icons/stream.png"));
		if(group == null)
			tool_button = new RadioToolButton.from_stock(null, Stock.HOME);
		else
			tool_button = new RadioToolButton.with_stock_from_widget(group, Stock.HOME);
	}

	public RadioToolButton? get_tool_button(){
		return tool_button;
	}

	public void set_main_window(MainWindow main_window){
		this.main_window = main_window;
	}

	public int get_id(){
		return id;
	}

}