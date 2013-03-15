
using Gtk;

class HomeTimeline : IPage, ITimeline, IMessageReceiver, ScrollWidget{
	public int unread_count{
		get {return unread_tweets;}
	}
	public MainWindow main_window{set;get;}
	protected int64 max_id{get;set; default = int64.MAX-2;}
	protected Egg.ListBox tweet_list{set;get;}
	private int id;
	private RadioToolButton tool_button;
	private bool loading = false;
	private int unread_tweets = 0;

	public HomeTimeline(int id){
		this.id = id;
		tweet_list = new Egg.ListBox();
		tweet_list.get_style_context().add_class("stream");
		tweet_list.set_selection_mode(SelectionMode.NONE);
		tweet_list.add_to_scrolled(this);
		tweet_list.set_sort_func((tle1, tle2) => {
			if(((TweetListEntry)tle1).timestamp <
			   ((TweetListEntry)tle2).timestamp)
				return 1;
			return -1;
		});

	    this.vadjustment.value_changed.connect( () => {
            int max = (int)(this.vadjustment.upper - this.vadjustment.page_size);
            int value = (int)this.vadjustment.value;
            if (value >= (max * 0.9f) && !loading){
                //Load older tweets
                loading = true;
                message("end! %d/%d", value, max);
                load_older();
            }
        });

        UserStream.get().register(this);
	}

	private void stream_message_received(StreamMessageType type, Json.Object root) {
		if(type == StreamMessageType.TWEET) {
			GLib.DateTime now = new GLib.DateTime.now_local();
			Tweet t = new Tweet();
			t.load_from_json(root, now);
			Tweet.cache(t, Tweet.TYPE_NORMAL);

			this.balance_next_upper_change(TOP);
			tweet_list.add(new TweetListEntry(t, main_window));
			tweet_list.resort();
		}
	}


	/**
	 * see IPage#onJoin
	 */
	public void onJoin(int page_id, va_list arg_list){

	}

	/**
	 * see ITimeline#load_cached()
	 */
	public void load_cached() {
		try{
			this.load_cached_internal(Tweet.TYPE_NORMAL);
		} catch(SQLHeavy.Error e){
			critical("Error while loading cached tweets of the home timeline: %s",
			         e.message);
		}
		tweet_list.resort();
	}

	public void load_newest() {
		try {
			this.balance_next_upper_change(TOP);
			this.load_newest_internal("1.1/statuses/home_timeline.json",
	    		                      Tweet.TYPE_NORMAL,
            (count, max_id) => {
        		if(max_id < this.max_id)
        			this.max_id = max_id;

            });
		} catch(SQLHeavy.Error e){
			warning("SQL Error while loading newest tweets of timeline %d: %s",
			        this.id, e.message);
		}
	}

	public void load_older() {
		this.balance_next_upper_change(BOTTOM);
		this.load_older_internal("1.1/statuses/home_timeline.json",
		                         Tweet.TYPE_NORMAL,
        (count, mid) => {
        	if(mid < this.max_id)
        		this.max_id = mid;

        	this.loading = false;
        });
	}


	public void create_tool_button(RadioToolButton? group){
		if(group == null)
			tool_button = new RadioToolButton.from_stock(null, Stock.HOME);
		else
			tool_button = new RadioToolButton.with_stock_from_widget(group, Stock.HOME);
	}

	public RadioToolButton? get_tool_button(){
		return tool_button;
	}

	public int get_id(){
		return id;
	}
}