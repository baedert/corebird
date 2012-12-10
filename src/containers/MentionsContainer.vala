
using Gtk;



class MentionsContainer : ScrollWidget {
	public MainWindow window;
	private TweetList list = new TweetList();

	public MentionsContainer(){
		base();
		this.add_with_viewport(list);

		load_new_mentions.begin();
	}

	private async void load_cached_mentions(){
		GLib.DateTime now = new GLib.DateTime.now_local();

		SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
			"SELECT `id`, `text`, `user_id`, `user_name`, `is_retweet`,
					`retweeted_by`, `retweeted`, `favorited`, `created_at`,
					`added_to_stream`, `avatar_name`, `screen_name` FROM `cache`
			WHERE `type`='2' 
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
			TweetListEntry list_entry = new TweetListEntry(t, window);
			list.add_item(list_entry);	
			result.next();
		}
	}



	// TODO: Cache this.
	private async void load_new_mentions(){
		SQLHeavy.Query id_query = new SQLHeavy.Query(Corebird.db,
		 	"SELECT `id`, `added_to_stream` FROM `cache` 
		 	WHERE `type`='2' ORDER BY `added_to_stream` DESC LIMIT 1;");
		SQLHeavy.QueryResult id_result = id_query.execute();
		int64 greatest_id = id_result.fetch_int64(0);
		message("greatest_id: %s", greatest_id.to_string());



		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/statuses/mentions_timeline.json");
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end(res);
			} catch(GLib.Error e){
				critical("Error while loading mentions: %s", e.message);
			}
			string back = call.get_payload();
			Json.Parser parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			}catch(GLib.Error e){
				critical("Error while parsing mentions json: %s\nData:%s", e.message, back);
			}
			Json.Array root = parser.get_root().get_array();
			var loader_thread = new LoaderThread(root, window, list);
			loader_thread.balance_upper_change = false;
			loader_thread.run();

		});
	}

}