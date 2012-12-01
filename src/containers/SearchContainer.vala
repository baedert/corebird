


using Gtk;


class SearchContainer : Box{
	private Entry search_entry = new Entry();


	public SearchContainer() {
		GLib.Object(orientation: Orientation.VERTICAL);
		this.border_width = 4;

		search_entry.placeholder_text = "Search keyword(s)";
		search_entry.secondary_icon_stock = Stock.FIND;
		search_entry.icon_press.connect( (pos) => {
			if (pos == EntryIconPosition.SECONDARY){
				search_for(search_entry.get_text());
			}
		});
		search_entry.key_release_event.connect( (event) => {
			if (event.keyval == Gdk.Key.Return){
				search_for(search_entry.get_text());	
				return true;
			}
			
			return false;
		});
		this.pack_start(search_entry, false, true);
	}

	public void search_for(string search_term){
		if(search_term.length == 0)
			return;

		var call = Twitter.proxy.new_call();
		call.set_function("1.1/search/tweets.json");
		call.set_method("GET");
		call.add_param("q", GLib.Uri.escape_string(search_entry.get_text()));
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end(res);
			} catch (GLib.Error e){
				warning("Error while ending search call: %s", e.message);
				return;
			}
			string back = call.get_payload();
			Json.Parser parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			} catch (GLib.Error e){
				critical("Problem with json data from search call: %s\nDATA:\n%s", e.message, back);
			}
		});
	}
}