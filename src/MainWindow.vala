
using Gtk;
using Soup;


class MainWindow : Window {
	private Toolbar main_toolbar = new Toolbar();
	private Toolbar left_toolbar = new Toolbar();
	private Box main_box = new Box(Orientation.VERTICAL, 0);
	private Box bottom_box = new Box(Orientation.HORIZONTAL, 0);
	private ListStore tweets = new ListStore(1, typeof(Tweet));
	private TreeView tweet_tree = new TreeView();

	public MainWindow(){

		ToolButton new_tweet_button = new ToolButton.from_stock(Stock.NEW);
		new_tweet_button.clicked.connect( () => {
			NewTweetWindow win = new NewTweetWindow(this);
			win.show_all();
		});
		main_toolbar.add(new_tweet_button);
		ToolButton refresh_button = new ToolButton.from_stock(Stock.REFRESH);
		refresh_button.clicked.connect( () => {
			try{
				load_new_tweets();
			}catch(SQLHeavy.Error e){
				error("Warning while fetching new tweets: %s", e.message);
			}
		});
		main_toolbar.add(refresh_button);
		main_toolbar.get_style_context().add_class("primary-toolbar");
		main_toolbar.orientation = Orientation.HORIZONTAL;
		main_box.pack_start(main_toolbar, false, false);



		ToolButton b = new ToolButton.from_stock(Stock.ADD);
		left_toolbar.add(b);
		ToolButton c = new ToolButton.from_stock(Stock.DELETE);
		left_toolbar.add(c);
		left_toolbar.orientation = Orientation.VERTICAL;
		left_toolbar.set_style(ToolbarStyle.ICONS);
		bottom_box.pack_start(left_toolbar, false, true);



		var tweet_renderer = new TweetRenderer();
		var column = new TreeViewColumn();
		column.pack_start(tweet_renderer, true);
		column.set_title("Tweets");
		column.add_attribute(tweet_renderer, "tweet", 0);
		tweet_tree.append_column(column);


		tweet_tree.headers_visible = false;
		tweet_tree.set_model (tweets);
		ScrolledWindow tweet_scroller = new ScrolledWindow(null, null);
		tweet_scroller.add(tweet_tree);
		bottom_box.pack_end (tweet_scroller, true, true);
		main_box.pack_end(bottom_box, true, true);


		//TODO: Parse date
		GLib.Date date = {};
		date.set_parse("Wed Jun 20 19:01:28 +0000 2012");
		GLib.DateDay day = date.get_day();
		GLib.DateMonth month = date.get_month();
		GLib.DateYear year = date.get_year();

		stdout.printf("Date: %d.%d.%d\n", day, month, year);


return;

		try{
			load_new_tweets();
			refresh_profile.begin();
		}catch(SQLHeavy.Error e){
			error("Warning while fetching new tweets: %s", e.message);
		}

		this.add(main_box);
		this.set_default_size (450, 600);
		this.show_all();
	}


	private void load_new_tweets() throws SQLHeavy.Error {
		tweets.clear();

		SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
			"SELECT `id`, `text`, `user_id`, `user_name`, `retweet` FROM `cache`
			ORDER BY `id` DESC LIMIT 25");
		SQLHeavy.QueryResult result = query.execute();
		
		while(!result.finished){

			Tweet t = new Tweet();
			t.id = result.fetch_string(0);
			t.text = result.fetch_string(1);
			t.user_id = result.fetch_int(2);
			t.user_name = result.fetch_string(3);
			t.load_avatar();


			// Append the tweet to the ListStore
			TreeIter iter;
			tweets.append(out iter);
			tweets.set(iter, 0, t);

			result.next();
		}



		SQLHeavy.Query id_query = new SQLHeavy.Query(Corebird.db,
			"SELECT `id`, `time` FROM `cache` ORDER BY `id` DESC LIMIT 1;");
		SQLHeavy.QueryResult id_result = id_query.execute();
		int64 greatest_id = id_result.fetch_int64(0);
		message("Greatest_id: %s", greatest_id.to_string());


		var call = Twitter.proxy.new_call();
		call.set_function("1.1/statuses/home_timeline.json");
		call.set_method("GET");
		call.add_param("count", "30");
		call.add_param("include_entities", "false");
		if(greatest_id > 0)
			call.add_param("since_id", greatest_id.to_string());

		call.invoke_async.begin(null, () => {
			string back = call.get_payload();
			stdout.printf(back+"\n");
			var parser = new Json.Parser();
			parser.load_from_data(back);
			if (parser.get_root().get_node_type() != Json.NodeType.ARRAY){
				warning("Root node is no Array.");
				warning("Back: %s", back);
				return;
			}


			var root = parser.get_root().get_array();


			SQLHeavy.Query cache_query = new SQLHeavy.Query(Corebird.db,
				"INSERT INTO `cache`(`id`, `text`,`user_id`, `user_name`, `time`) 
				VALUES (:id, :text, :user_id, :user_name, :time);");

			root.foreach_element( (array, index, node) => {
				Json.Object o = node.get_object();
				Json.Object user = o.get_object_member("user");
				Tweet t = new Tweet();
				t.text = o.get_string_member("text");
				t.favorited = o.get_boolean_member("favorited");
				t.retweeted = o.get_boolean_member("retweeted");
				t.id = o.get_string_member("id_str");
				t.user_name = user.get_string_member("name");
				t.user_id = (int)user.get_int_member("id");

				string avatar = user.get_string_member("profile_image_url");
				
				if (o.has_member("retweeted_status")){
					Json.Object rt = o.get_object_member("retweeted_status");
					t.is_retweet = true;
					t.text = rt.get_string_member("text");
					t.id = rt.get_string_member("id_str");
					Json.Object rt_user = rt.get_object_member("user");
					t.user_name = rt_user.get_string_member ("name");
					avatar = rt_user.get_string_member("profile_image_url");
					t.user_id = (int)rt_user.get_int_member("id");
				}

				stdout.printf("%u: %s\n", index, t.user_name);


				t.load_avatar();
				if(!t.has_avatar()){
					message("Downloading avatar for %s", t.user_name);
					File a = File.new_for_uri(avatar);
					File dest = File.new_for_path("assets/avatars/%d.png".printf(t.user_id));
					a.copy(dest, FileCopyFlags.OVERWRITE); 
					t.load_avatar();
				}
	

				// Insert tweet into cache table
				try{
					TimeVal time = {};
					time.get_current_time();
					cache_query.set_string(":id", t.id);
					cache_query.set_string(":text", t.text);
					cache_query.set_int(":user_id", t.user_id);
					cache_query.set_string(":user_name", t.user_name);
					cache_query.set_int64(":time", (int64)time.tv_usec);
					cache_query.execute();
				}catch(SQLHeavy.Error e){
					error("Error while caching tweet: %s", e.message);
				}

				TreeIter iter;
				tweets.insert(out iter, (int)index);
				// tweets.insert(out iter, 0);
				// tweets.append(out iter);
				tweets.set(iter, 0, t);
				index--;
			});
		});

	}

	private async void refresh_profile(){
		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/users/show.json");
		call.add_param("user_id", "15");
		call.invoke_async.begin(null, () => {
			string json_string = call.get_payload();
			Json.Parser parser = new Json.Parser();
			try{
				parser.load_from_data (json_string);
				// stdout.printf(json_string+"\n");
			}catch(GLib.Error e){
				error("Error while refreshing profile: %s", e.message);
			}
		});
	}
}