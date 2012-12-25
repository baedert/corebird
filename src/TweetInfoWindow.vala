using Gtk;


/**
 * A Window showing information about the given tweet.
 * Gives the user the opportunity to:
 * · (un)Favorite a tweet
 * · (un)Retweet a tweet
 * · Reply to that tweet
 * · See how often this tweet was retweeted
 * · See how often this tweet was favorited
 * · Who retweeted this tweet
 * · Who favorited this tweet
 * · Replies to this tweet
 * · Access to the media in this tweet
**/
class TweetInfoWindow {
	public Tweet tweet {get; set;}
	private Window window;

	public TweetInfoWindow(Tweet tweet){
		this.tweet = tweet;

		UIBuilder builder = new UIBuilder("ui/tweet-info-window.ui");
		window = builder.get_window("main_window");

		builder.get_image("avatar").pixbuf = tweet.avatar;
		builder.get_label("name_label").label = "<big><b>"+tweet.user_name+"</b></big>";
		builder.get_label("screen_name_label").label = "@"+tweet.screen_name;
		builder.get_label("tweet_text").label = tweet.text;
		builder.get_label("time_delta").label = tweet.time_delta;

		//Connect signals
		builder.get_button("reply_button").clicked.connect(() => {
			message("reply");
		});
		builder.get_toggle("retweet_button").toggled.connect(() => {
			message("reteet");
		});
		builder.get_toggle("favorite_button").toggled.connect(() => {
			message("favorite");
		});
		
		window.resize(350, 500);
	}

	public void show_all(){
		window.show_all();
	}


	private async void load_data(){
		var call = Twitter.proxy.new_call();
		call.set_function("1.1/statuses/show/"+tweet.id+".json");
		call.set_method("GET");
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end(res);
			}catch(GLib.Error e){
				critical("Error while retrieving tweet info: %s", e.message);
				return;
			}

			Json.Parser parser = new Json.Parser();
			string back = call.get_payload();
			try{
				parser.load_from_data(back);
			}catch(GLib.Error e){
				critical("Error with Json data: %s\nDATA:%s", e.message, back);
			}
			var root = parser.get_root().get_object();

			message(back);

		});
	}
}
