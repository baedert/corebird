
using Gtk;

class HomeTimeline : IPage, ITimeline, IMessageReceiver, ScrollWidget{
	public int unread_count{
		get {return unread_tweets;}
	}
	protected int64 max_id{
		get {return lowest_id;}
		set {lowest_id = value;}
	}
	public MainWindow main_window{set;get;}
	protected Egg.ListBox tweet_list{set;get;}
	private int id;
	private BadgeRadioToolButton tool_button;
	private bool loading = false;
	private int unread_tweets = 0;
	private int64 lowest_id = int64.MAX-2;
	private uint tweet_remove_timeout = -1;

	public HomeTimeline(int id){
		this.id = id;
		tweet_list = new Egg.ListBox();
		tweet_list.get_style_context().add_class("stream");
		tweet_list.set_selection_mode(SelectionMode.NONE);
		tweet_list.add_to_scrolled(this);
		tweet_list.set_sort_func(TweetListEntry.sort_func);

	    this.vadjustment.value_changed.connect( () => {
            int max = (int)(this.vadjustment.upper - this.vadjustment.page_size);
            int value = (int)this.vadjustment.value;
            if (value >= (max - 100) && !loading){
                //Load older tweets
                loading = true;
                message("end! %d/%d", value, max);
                load_older();
            }
        });

        this.vadjustment.notify["value"].connect(() => {
        	double value = vadjustment.value;
        	if(value == 0 && tweet_list.get_size() > ITimeline.REST) {
        		tweet_remove_timeout = GLib.Timeout.add(5000, () => {
        			tweet_list.remove_last(tweet_list.get_size() - ITimeline.REST);
        			return false;
        		});
        	} else {
        		if(tweet_remove_timeout != 0){
        			GLib.Source.remove(tweet_remove_timeout);
        			tweet_remove_timeout = 0;
        		}
        	}
        	if(unread_tweets > 0 && get_last_scroll_dir() == -1){
		       	tweet_list.forall_internal(false, (w) => {
		       		TweetListEntry tle = (TweetListEntry)w;
		       		if(tle.seen)
		       			return;
		       		Allocation alloc;
		       		tle.get_allocation(out alloc);
		       		if(alloc.y+(alloc.height/2.0) >= vadjustment.value) {
		       			tle.seen = true;
		       			unread_tweets--;
		       			update_unread_count();
		       		}
	        	});
	       	}

        });



        UserStream.get().register(this);
	}

	private void stream_message_received(StreamMessageType type, Json.Object root) {
		if(type == StreamMessageType.TWEET) {
			GLib.DateTime now = new GLib.DateTime.now_local();
			Tweet t = new Tweet();
			t.load_from_json(root, now);

			Tweet.cache.begin(t, Tweet.TYPE_NORMAL);

			this.balance_next_upper_change(TOP);
			var entry = new TweetListEntry(t, main_window);
			entry.seen = false;
			tweet_list.add(entry);
			tweet_list.resort();

			unread_tweets++;
			update_unread_count();

			int stack_size = Settings.get_tweet_stack_count();
			if(stack_size != 0 && unread_tweets >= stack_size) {
				string summary = "%d new Tweets!".printf(unread_tweets);
				NotificationManager.notify(summary);
			}
		}
	}


	/**
	 * see IPage#onJoin
	 */
	public void on_join(int page_id, va_list arg_list){
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
		this.vadjustment.set_upper(0);
	}

	public void load_newest() {
		try {
			// this.balance_next_upper_change(TOP);
			this.load_newest_internal("1.1/statuses/home_timeline.json",
	    		                      Tweet.TYPE_NORMAL,
            (count, lowest_id) => {
        		if(lowest_id < this.lowest_id)
        			this.lowest_id = lowest_id;

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
        (count, lowest_id) => {
        	if(lowest_id < this.lowest_id){
        		this.lowest_id = lowest_id;
        		message("Setting lowest_id to new value(%s)", lowest_id.to_string());
        	}

        	this.loading = false;
        });

	}


	public void create_tool_button(RadioToolButton? group){
		tool_button = new BadgeRadioToolButton(group, Stock.HOME);
	}

	public RadioToolButton? get_tool_button(){
		return tool_button;
	}

	public int get_id(){
		return id;
	}

	private void update_unread_count() {
		tool_button.set_badge_value(unread_tweets);
		tool_button.queue_draw();
	}
}