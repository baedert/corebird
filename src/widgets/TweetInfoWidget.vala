using Gtk;



class TweetInfoWidget : PaneWidget, Box {
	public Tweet tweet {get; set;}


	public TweetInfoWidget(Tweet tweet){
		GLib.Object(orientation: Orientation.VERTICAL, spacing: 4);
		this.tweet = tweet;
	}



	public string get_id(){
		return tweet.id;
	}
}