using Gtk;





class TweetList : Box {

	public TweetList(){
		GLib.Object(orientation: Orientation.VERTICAL, spacing: 0);
		set_has_window(false);
	}



	public void add_item(Box entry){
		this.pack_start(entry, false, true);
		entry.set_visible(true);
	}

	public void insert_item(Box entry, uint pos){
		this.pack_start(entry, false, true);
		this.reorder_child(entry, (int)pos);
	}
	
	/**
	 * Removes all item from this list.
	 */
	public void clear(){
		this.forall( (w) => {
			this.remove(w);
		});
	}
}