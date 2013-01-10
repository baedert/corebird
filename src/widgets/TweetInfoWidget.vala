using Gtk;

class TweetInfoWidget : PaneWidget, Gtk.ScrolledWindow{
	private int64 tweet_id;


	public TweetInfoWidget(Tweet t){
		this.tweet_id = t.id;
		UIBuilder builder = new UIBuilder("ui/tweet-info-window.ui", "main_box");
		var box = builder.get_box("main_box");


		builder.get_label("text").label = t.text;
		builder.get_label("name").label = "<big><b>"+t.user_name+"</b></big>";
		builder.get_label("screen_name").label = "<small>@"+t.screen_name+"</small>";



		this.hscrollbar_policy = PolicyType.NEVER;
		this.add_with_viewport(box);
		this.show_all();
	}

	public int64 get_id(){
		return tweet_id;
	}
}