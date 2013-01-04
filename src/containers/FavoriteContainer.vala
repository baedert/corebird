using Gtk;


class FavoriteContainer : TweetContainer, ScrollWidget {
	private MainWindow main_window;
	private RadioToolButton tool_button;
	private int id;
	private TweetList tweet_list = new TweetList();


	public FavoriteContainer(int id){
		base();
		this.id = id;

		this.add_with_viewport(tweet_list);
	}


	public void refresh(){
		var call = Twitter.proxy.new_call();
		call.set_function("1.1/favorites/list.json");
		call.set_method("GET");
		call.add_param("count", "20");

		call.invoke_async.begin(null, () => {
			string back = call.get_payload();
			stdout.printf(back+"\n");
			var parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			}catch(GLib.Error e){
				warning("Problem with json data from twitter: %s\nData:%s", e.message, back);
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
			var loader_thread = new LoaderThread(root, main_window, tweet_list, 1);
			loader_thread.run();
		});
	}

	public void load_cached(){
	}

	public void create_tool_button(RadioToolButton? group){
		tool_button = new RadioToolButton.from_widget(group);
		tool_button.icon_name = "starred";
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