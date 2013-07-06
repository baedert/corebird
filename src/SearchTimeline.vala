/*  This file is part of corebird.
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */


using Gtk;

// TODO: Add timeout that removes all entries after X seconds when switched away
class SearchTimeline : IPage, ITimeline, Box {
	/** The unread count here is always zero */
	public int unread_count{
		get{return 0;}
		set{;}
	}
  public Account account {get; set;}
	protected uint tweet_remove_timeout{get;set;}
	private Entry search_entry    = new Entry();
	public MainWindow main_window{set;get;}
	protected int64 max_id{get;set; default = int64.MAX-2;}
	protected Gtk.ListBox tweet_list{set;get;}
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

		tweet_list = new Gtk.ListBox();
		var result_scroller = new ScrollWidget();
    result_scroller.add (tweet_list);
		this.pack_start(result_scroller, true, true);

		tweet_list.set_sort_func(ITwitterItem.sort_func);
	}

	/**
	 * see IPage#onJoin
	 */
	public void on_join(int page_id, va_list arg_list){
		string term = arg_list.arg<string>();
		if(term != null)
			search_for.begin(term, true);
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
			LoaderThread loader_thread = new LoaderThread(statuses, account, 
                                                    main_window,
			                                              tweet_list);
			loader_thread.run();
		});
	}



	public void create_tool_button(RadioToolButton? group){
		tool_button = new RadioToolButton.with_stock_from_widget(group, "search");
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
