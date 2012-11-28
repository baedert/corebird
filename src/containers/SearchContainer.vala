


using Gtk;


class SearchContainer : Box{
	private Entry search_entry = new Entry();


	public SearchContainer() {
		GLib.Object(orientation: Orientation.VERTICAL);
		this.border_width = 4;

		search_entry.placeholder_text = "Search keyword(s)";
		search_entry.secondary_icon_stock = Stock.FIND;
		this.pack_start(search_entry, false, true);
	}
}