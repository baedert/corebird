using Gtk;



class TweetInfoWidget : PaneWidget, Box {
	public Tweet tweet {get; set;}


	public TweetInfoWidget(Tweet tweet){
		GLib.Object(orientation: Orientation.VERTICAL, spacing: 4);
		this.tweet = tweet;


//		this.pack_start(new TweetListEntry(tweet, null), false, false);
		this.pack_start(new TweetListEntry(tweet, null), false, false);
	}



	public string get_id(){
		return tweet.id;
	}
}