


using Gtk;


class SearchContainer : Box{
	private Entry search_entry    = new Entry();
	private TweetList result_list = new TweetList();
	private ProgressItem progress_item = new ProgressItem(50);
	public MainWindow window;



	public SearchContainer() {
		GLib.Object(orientation: Orientation.VERTICAL);
		this.border_width = 4;

		search_entry.placeholder_text = "Search keyword(s)";
		search_entry.secondary_icon_stock = Stock.FIND;
		search_entry.icon_press.connect( (pos) => {
			if (pos == EntryIconPosition.SECONDARY){
				search_for.begin(search_entry.get_text());
			}
		});
		search_entry.key_release_event.connect( (event) => {
			if (event.keyval == Gdk.Key.Return){
				result_list.clear();
				result_list.add_item(progress_item);
				search_for.begin(search_entry.get_text());	
				return true;
			}
			
			return false;
		});
		this.pack_start(search_entry, false, true);
		var result_scroller = new ScrolledWindow(null, null);
		result_scroller.add_with_viewport(result_list);
		this.pack_start(result_scroller, true, true);
	}

	public async void search_for(string search_term, bool set_text = false){
		if(search_term.length == 0)
			return;

		result_list.clear();

		if (set_text)
			search_entry.set_text(search_term);


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
			GLib.DateTime now = new GLib.DateTime.now_local();
			var statuses = parser.get_root().get_object().get_array_member("statuses");
			statuses.foreach_element((array, index, node) => {
				Tweet t = new Tweet();
				t.load_from_json(node.get_object(), now, null, null);
				result_list.add_item(new TweetListEntry(t, window));
			});
		});
		result_list.remove(progress_item);
	}
}