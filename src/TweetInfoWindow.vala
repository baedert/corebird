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
class TweetInfoWindow : Gtk.Window {
	public Tweet tweet {get; set;}

	public TweetInfoWindow(){
		// this.tweet = tweet;
		/*TweetListEntry entry = new TweetListEntry(tweet, null);


		Box top_box = new Box(Orientation.HORIZONTAL, 5);
		top_box.pack_start(new Image.from_pixbuf(tweet.avatar));
		Box author_box = new Box(Orientation.VERTICAL, 3);
		Label name_label = new Label("");
		name_label.xalign = 0;
		name_label.set_markup("<big><b>"+tweet.user_name+"</b></big>");
		author_box.pack_start(name_label, false, true);
		Label screen_name_label = new Label("");
		screen_name_label.set_markup("<small>"+tweet.screen_name+"</small>");
		screen_name_label.xalign = 0;
		author_box.pack_start(screen_name_label, false, false);
		top_box.pack_start(author_box, false, true);

		main_box.pack_start(top_box, false, true);

		ButtonBox bb = new ButtonBox(Orientation.HORIZONTAL);
		bb.layout_style = ButtonBoxStyle.CENTER;

		ToggleButton rt_button = new ToggleButton.with_label("Retweet");
		rt_button.active = tweet.retweeted;
		bb.pack_start(rt_button, false, false);

		ToggleButton fav_button = new ToggleButton.with_label("Favorite");
		fav_button.active = tweet.favorited;
		bb.pack_start(fav_button, false, false);

		bb.get_style_context().add_class("linked");
		main_box.pack_start(bb, false, false);
		this.add(main_box);*/

		//load_data.begin();
	}


	public static Window load_from_file(string path, Tweet tweet){
		Builder builder = new Builder();
		builder.add_from_file(path);
		builder.connect_signals(null);
		var win = builder.get_object("main_window") as Window;

		((Image)builder.get_object("avatar")).pixbuf = tweet.avatar;
		((Label)builder.get_object("name_label")).label = 
				"<big><b>"+tweet.user_name+"</b></big>";
		((Label)builder.get_object("screen_name_label")).label = "@"+tweet.screen_name;
		((Label)builder.get_object("tweet_text")).label = tweet.text;
		

		win.resize(350, 500);
		return win;
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
