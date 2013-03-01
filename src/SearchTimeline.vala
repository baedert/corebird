


using Gtk;


class SearchTimeline : IPage, ITimeline, Box {
	private Entry search_entry    = new Entry();
	public MainWindow main_window{set;get;}
	protected int64 max_id{get;set; default = int64.MAX-2;}
	protected Egg.ListBox tweet_list{set;get;}
	private int id;
	private RadioToolButton tool_button;


	public SearchTimeline(int id) {
		GLib.Object(orientation: Orientation.VERTICAL);
		this.id = id;
		search_entry.margin = 5;
		search_entry.placeholder_text = "Search keyword(s)";
		search_entry.primary_icon_stock = Stock.FIND;
		search_entry.icon_press.connect( (pos) => {
			if (pos == EntryIconPosition.PRIMARY){
				search_for.begin(search_entry.get_text());
			}
		});
		search_entry.key_release_event.connect( (event) => {
			if (event.keyval == Gdk.Key.Return){
				// tweet_list.clear();
				search_for.begin(search_entry.get_text());
				return true;
			}

			return false;
		});
		this.pack_start(search_entry, false, true);

		tweet_list = new Egg.ListBox();
		var result_scroller = new ScrollWidget();
		tweet_list.add_to_scrolled(result_scroller);
		this.pack_start(result_scroller, true, true);

		tweet_list.set_sort_func((tle1, tle2) => {
			if(((TweetListEntry)tle1).timestamp <
			   ((TweetListEntry)tle2).timestamp)
				return 1;
			return -1;
		});
	}

	/**
	 * see IPage#onJoin
	 */
	public void onJoin(int page_id, va_list arg_list){

	}

	public void load_cached() {

	}
	public void load_newest() {

	}
	public void load_older () {

	}
	public void update () {}

	public async void search_for(string search_term, bool set_text = false){
		if(search_term.length == 0)
			return;

		// tweet_list.clear();
		// GLib.Idle.add( () => {
		// 	tweet_list.show_spinner();
		// 	return false;
		// });

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
				critical(" %s\nDATA:\n%s", e.message, back);
			}
			var statuses = parser.get_root().get_object().get_array_member("statuses");
			LoaderThread loader_thread = new LoaderThread(statuses, main_window,
			                                              tweet_list);
			loader_thread.run();
		});
	}



	public void create_tool_button(RadioToolButton? group){
		tool_button = new RadioToolButton.with_stock_from_widget(group, Stock.FIND);
	}

	public RadioToolButton? get_tool_button(){
		return tool_button;
	}

	public void set_main_window(MainWindow main_window){
		this.main_window = main_window;
	}

	public int get_id(){
		return id;
	}
}