
using Gtk;



class MentionsContainer : TweetContainer, ScrollWidget {
	private int id;
	public MainWindow main_window;
	private Egg.ListBox tweet_list = new Egg.ListBox();
	private RadioToolButton tool_button;
	

	public MentionsContainer(int id){
		base();
		this.id = id;
		this.add_with_viewport(tweet_list);
	}

	// TODO: Save this somewhere else, it's needed more than once.
	private async void load_cached_mentions() throws SQLHeavy.Error{
		GLib.DateTime now = new GLib.DateTime.now_local();

		SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
			"SELECT `id`, `text`, `user_id`, `user_name`, `is_retweet`,
					`retweeted_by`, `retweeted`, `favorited`, `created_at`,
					`added_to_stream`, `avatar_name`, `screen_name`,`type` FROM `cache`
			WHERE `type`='2' 
			ORDER BY `added_to_stream` DESC LIMIT 30");
		SQLHeavy.QueryResult result = query.execute();
		while(!result.finished){
			Tweet t        = new Tweet();
			t.id           = result.fetch_int(0);
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
			tweet_list.add(list_entry);	
			result.next();
		}
	}


	private async void load_new_mentions() throws SQLHeavy.Error{
		SQLHeavy.Query id_query = new SQLHeavy.Query(Corebird.db,
		 	"SELECT `id`, `added_to_stream` FROM `cache` 
		 	WHERE `type`='2' ORDER BY `added_to_stream` DESC LIMIT 1;");
		SQLHeavy.QueryResult id_result = id_query.execute();
		int64 greatest_id = id_result.fetch_int64(0);
		message("greatest_id: %s", greatest_id.to_string());



		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/statuses/mentions_timeline.json");
		if(greatest_id > 0)
			call.add_param("since_id", greatest_id.to_string());
			
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end(res);
			} catch(GLib.Error e){
				critical("Error while loading mentions: %s", e.message);
				return;
			}
			string back = call.get_payload();
			Json.Parser parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			}catch(GLib.Error e){
				critical("Error while parsing mentions json: %s\nData:%s", e.message, back);
			}
			Json.Array root = parser.get_root().get_array();
			var loader_thread = new LoaderThread(root, main_window, tweet_list, Tweet.TYPE_MENTION);
			loader_thread.balance_upper_change = false;
			loader_thread.run();

		});
	}



	public void refresh(){
		load_new_mentions.begin();
	}

	public void load_cached(){
		load_cached_mentions.begin();
	}

	public void create_tool_button(RadioToolButton? group){
		tool_button = new RadioToolButton.from_widget(group);
		tool_button.icon_name = "user-info";
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