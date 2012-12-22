using Gtk;



//TODO: is there a better way to insert a widget than
//      adding and reordering?

public class TweetList : Box {
	private ProgressItem spinner = new ProgressItem();
	private int childCount = 0;

	public TweetList(){
		GLib.Object(orientation: Orientation.VERTICAL, spacing: 0);
	}

	/**
	 * Appends the given entry to the end of the list.
	 *
	 * @param entry The entry to add.
	 */
	public void add_item(Box entry){

		if (childCount % 2 == 0){
			entry.get_style_context().add_region(STYLE_REGION_ROW, RegionFlags.EVEN);
		}else{
			entry.get_style_context().add_region(STYLE_REGION_ROW, RegionFlags.ODD);
		}
		
		entry.show_all();
		base.pack_start(entry, false, true);
		childCount++;
	}
	/**
	 * Inserts the given entry into the place at the given position.
	 * If there is an entry already at that position, it will be pushed back.
	 *
	 * @param entry The entry to insert
	 * @param pos The entry's position
	 */
	public void insert_item(Box entry, uint pos){
		entry.show_all();
		base.pack_start(entry, false, false);
		base.reorder_child(entry, (int)pos);
	}
	
	/**
	 * Removes all item from this list.
	 */
	public void clear(){
		this.forall( (w) => {
			this.remove(w);
		});
	}

	/**
	 * Displays a spinner(work indicator) at the given position.
	 * Use hide_spinner to hide it.
	 * For int.MIN, the spinner will be displayed at the top of the list,
	 * int.MAX means the end of the list, everything else is used as the 
	 * discrete value in the list.
	 *
	 * @param pos The position of the spinner.
	 */
	public void show_spinner(int pos = 0){

		if (spinner.get_parent() != null){
			warning("Spinner is already added elsewhere.");
			return;
		}
		if(pos == int.MAX)
			this.pack_end(spinner, false, true);
		else
			this.insert_item(spinner, pos);

		spinner.start();
	}

	/**
	 * Hides the spinner at the given position. If there is no spinner at the given
	 * position, a warning will be generated, that's it.
	 *
	 * @pos The spinner is at this position.
	 */
	public void hide_spinner(int pos = 0){
		if (pos == int.MAX)
			pos = (int)this.get_children().length();

		if(spinner.parent != null){
			this.remove(spinner);
			spinner.stop();
		}
	}

	public new void pack_start(Widget container, bool a = true, bool b = true, int i = 0){
		error("pack_start on a TweetList is bullshit, use add_item or insert_item.");
	}
	public new void pack_end(Widget container, bool a = true, bool b = true, int i = 0){
		error("pack_end on a TweetList is bullshit, use add_item or insert_item.");
	}
}