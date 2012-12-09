
using Gtk;



class MentionsContainer : ScrollWidget {
	public MainWindow window;
	private TweetList list = new TweetList();

	public MentionsContainer(){
		base();
		this.add_with_viewport(list);

		load_new_mentions.begin();
	}


	// TODO: Cache this.
	private async void load_new_mentions(){
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