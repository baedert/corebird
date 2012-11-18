
using Gtk;
using Soup;


class MainWindow : Window {
	private Toolbar main_toolbar = new Toolbar();
	private Toolbar left_toolbar = new Toolbar();
	private Box main_box = new Box(Orientation.VERTICAL, 2);
	private Box bottom_box = new Box(Orientation.HORIZONTAL, 2);
	private ListStore tweets = new ListStore(1, typeof(Tweet));
	private TreeView tweet_tree = new TreeView();

	public MainWindow(){

		ToolButton new_tweet_button = new ToolButton.from_stock(Stock.NEW);
		new_tweet_button.clicked.connect( () => {
			NewTweetWindow win = new NewTweetWindow(this);
		});
		main_toolbar.add(new_tweet_button);
		ToolButton refresh_button = new ToolButton.from_stock(Stock.REFRESH);
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

		var call = Twitter.proxy.new_call();
		call.set_function("1.1/statuses/home_timeline.json");
		call.set_method("GET");

		call.invoke_async.begin(null, () => {
			string back = call.get_payload();
			stdout.printf(back+"\n");
			var parser = new Json.Parser();
			parser.load_from_data(back);
			var root = parser.get_root().get_array();


			root.foreach_element( (array, index, node) => {
				Json.Object o = node.get_object();
				Json.Object user = o.get_object_member("user");
				Tweet t = new Tweet(o.get_string_member("text"));
				t.favorited = o.get_boolean_member("favorited");
				t.retweeted = o.get_boolean_member("retweeted");
				t.from = user.get_string_member("name");
				t.from_screenname = user.get_string_member("screen_name");
				string id = user.get_string_member("id_str");
				string avatar = user.get_string_member("profile_image_url");



				

				
				if (o.has_member("retweeted_status")){
					Json.Object rt = o.get_object_member("retweeted_status");
					t.is_retweet = true;
					t.text = rt.get_string_member("text");
					Json.Object rt_user = rt.get_object_member("user");
					t.from_screenname = rt_user.get_string_member ("screen_name");
					t.from = rt_user.get_string_member("name");
					avatar = rt_user.get_string_member("profile_image_url");
					id = rt_user.get_string_member("id_str");
				}


				string? path = null;
				SQLHeavy.Query avatar_query;
				SQLHeavy.QueryResult avatar_result;
				try{
					avatar_query = new SQLHeavy.Query(Corebird.db, "SELECT `id`, `path` FROM `avatars`
								WHERE `id`='"+id+"';");
					avatar_result = avatar_query.execute();
					path = avatar_result.fetch_string(1);
				}catch(SQLHeavy.Error e){
					error("Error while checking the avatar: %s\n", e.message);
				}


				// If path is still null at this point, we have to download the user's avatar.
				if(path == null){
					//Load Avatar
					message("Loading avatar for "+id);
					path = "assets/avatars/%s.png".printf(id);
					File a = File.new_for_uri(avatar);
					File dest = File.new_for_path(path);
					a.copy(dest, FileCopyFlags.OVERWRITE);
					try{
						Corebird.db.execute("INSERT INTO avatars(`id`, `path`, `time`) VALUES
					    	('%s', '%s', '1');".printf(id, path));
					}catch(SQLHeavy.Error e){
						error("Error while saving avatar: %s\n".printf(e.message));
					}
				}

				t.avatar = new Gdk.Pixbuf.from_file(path);


				TreeIter iter;
				tweets.append(out iter);
				tweets.set(iter, 0, t);
			});
		});


		this.add(main_box);
		this.set_default_size (450, 600);
		this.show_all();
	}


	private async void load_new_tweets(){

	}
}