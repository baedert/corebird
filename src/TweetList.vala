using Gtk;






class TweetList : Box {
	


	public TweetList(){
		GLib.Object(orientation: Orientation.VERTICAL, spacing: 0);
		set_has_window(false);
		this.get_style_context().add_class("stream");
	}



	public void add_tweet(TweetListEntry entry){
		this.pack_start(entry, false, true);
		entry.set_visible(true);
	}

	public void insert_tweet(TweetListEntry entry, uint pos){
		this.pack_start(entry, false, true);
		this.reorder_child(entry, (int)pos);
	}
}