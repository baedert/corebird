using Gtk;






class TweetList : Box {
	


	public TweetList(){
		GLib.Object(orientation: Orientation.VERTICAL, spacing: 0);
		set_has_window(false);
	}



	public void add_tweet(Box entry){
		this.pack_start(entry, false, true);
		entry.set_visible(true);
		// message(entry.get_style_context().get_path().to_string());
	}

	public void insert_tweet(Box entry, uint pos){
		this.pack_start(entry, false, true);
		this.reorder_child(entry, (int)pos);
	}
}