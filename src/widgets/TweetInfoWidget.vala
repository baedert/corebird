using Gtk;



class TweetInfoWidget : PaneWidget, Box {
	public Tweet tweet {get; set;}
	private TweetList tweet_list = new TweetList();


	public TweetInfoWidget(Tweet tweet){
		GLib.Object(orientation: Orientation.VERTICAL, spacing: 4);
		this.tweet = tweet;

		this.pack_start(new TweetListEntry(tweet, null), false, false);
		this.hexpand = false;


		// Show list with answers to this tweet
		this.pack_start(tweet_list, true, true);
		tweet_list.show_spinner();
		load_answers.begin();
		
	}


	private async void load_answers(){

		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/statuses/retweets/%s.json".printf(tweet.id));
		call.add_param("id", tweet.id);
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end(res);
			}catch(GLib.Error e){
				critical("Error while ending answer call: %s", e.message);
				return;
			}
			string back = call.get_payload();
			Json.Parser parser = new Json.Parser();
			parser.load_from_data(back);
			var root = parser.get_root().get_array();


			LoaderThread lt = new LoaderThread(root, null, tweet_list);
			lt.balance_upper_change = false;
			lt.run();
		});

		
	}


	public string get_id(){
		return tweet.id;
	}
}