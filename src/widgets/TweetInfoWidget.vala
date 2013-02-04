using Gtk;

class TweetInfoWidget : IPaneWidget, Gtk.ScrolledWindow{
	private int64 tweet_id;


	public TweetInfoWidget(Tweet t, MainWindow window){
		this.tweet_id = t.id;
		UIBuilder builder = new UIBuilder("ui/tweet-info-window.ui", "main_box");
		var box = builder.get_box("main_box");


		builder.get_label("text").label = t.text;
		builder.get_label("name").label = "<big><b>"+t.user_name+"</b></big>";
		builder.get_label("screen_name").label = "<small>@"+t.screen_name+"</small>";
		builder.get_image("avatar").pixbuf = t.avatar;
		builder.get_label("time_delta").label = t.time_delta;
		builder.get_toggle("retweet_button").active = t.retweeted;
		builder.get_toggle("favorite_button").active = t.favorited;

		builder.get_button("close_button").clicked.connect(() => {
			window.toggle_right_pane(this);
		});



		this.hscrollbar_policy = PolicyType.NEVER;
		this.add_with_viewport(box);
		this.show_all();
	}

	public int64 get_id(){
		return tweet_id;
	}

	public int get_width(){
		int pref_width;
		this.get_preferred_width(null, out pref_width);
		message("PW: %d", pref_width);
		return pref_width;
	}
}