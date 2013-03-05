
using Gtk;

class MentionsTimeline : IPage, ITimeline, ScrollWidget{
	public MainWindow main_window{set;get;}
	protected int64 max_id{get;set;}
	protected Egg.ListBox tweet_list{set;get;}
	private int id;
	private RadioToolButton tool_button;

	public MentionsTimeline(int id){
		this.id = id;
		tweet_list = new Egg.ListBox();
		tweet_list.set_selection_mode(SelectionMode.NONE);
		tweet_list.get_style_context().add_class("stream");
		tweet_list.add_to_scrolled(this);
		tweet_list.set_sort_func((tle1, tle2) => {
			if(((TweetListEntry)tle1).timestamp <
			   ((TweetListEntry)tle2).timestamp)
				return 1;
			return -1;
		});



        UserStream.get().registered_timelines.append(this);
        this.stream_message_received.connect(stream_message_received_cb);
	}

	private void stream_message_received_cb(StreamMessageType type, Json.Object root){
		if(type == StreamMessageType.TWEET) {
			if(root.get_string_member("text").contains("@"+User.screen_name)) {

				GLib.DateTime now = new GLib.DateTime.now_local();
				Tweet t = new Tweet();
				t.load_from_json(root, now);
				Tweet.cache(t, Tweet.TYPE_MENTION);

				this.balance_next_upper_change(TOP);
				tweet_list.add(new TweetListEntry(t, main_window));
				tweet_list.resort();
			}
		}
	}


	/**
	 * see IPage#onJoin
	 */
	public void onJoin(int page_id, va_list arg_list){

	}

	public void update () {

	}

	public void load_cached() {
		try{
			this.load_cached_internal(Tweet.TYPE_MENTION);
		} catch(SQLHeavy.Error e){
			critical("Error while loading cached tweets of the home timeline: %s",
			         e.message);
		}
	}

	public void load_newest() {
		try {
			this.load_newest_internal("1.1/statuses/mentions_timeline.json",
	    		                   	   Tweet.TYPE_MENTION);
		} catch (SQLHeavy.Error e) {
			warning(e.message);
		}
	}

	public void load_older() {

	}


	public void create_tool_button(RadioToolButton? group){
		tool_button = new RadioToolButton.with_stock_from_widget(group, Stock.OK);
	}

	public RadioToolButton? get_tool_button(){
		return tool_button;
	}

	public int get_id(){
		return id;
	}
}