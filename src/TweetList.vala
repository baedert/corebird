using Gtk;

class TweetList : Box {
	
	public TweetList(){
		GLib.Object(orientation: Orientation.VERTICAL);
		set_has_window(false);
	}



	public void add_tweet(TweetEntry entry){
		this.pack_end(entry, false, true);
	}
}