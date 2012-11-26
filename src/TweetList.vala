using Gtk;






class TweetList : Box {
	


	public TweetList(){
		GLib.Object(orientation: Orientation.VERTICAL);
		set_has_window(false);
	}



	public void add_tweet(TweetListEntry entry){
		this.pack_start(entry, false, true);
	}
}