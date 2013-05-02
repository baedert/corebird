
using Gtk;

class MentionsTimeline : IPage, ITimeline, IMessageReceiver, ScrollWidget{
	public int unread_count {
		get{return unread_messages;}
	}
	protected int64 max_id{
		get {return lowest_id;}
		set {lowest_id = value;}
	}
	public MainWindow main_window{set;get;}
	protected Egg.ListBox tweet_list{set;get;}
	private int id;
	private RadioToolButton tool_button;
	private int unread_messages = 0;
	private bool loading = false;
	private int64 lowest_id = int64.MAX-2;
	private uint tweet_remove_timeout = -1;


	public MentionsTimeline(int id){
		this.id = id;
		tweet_list = new Egg.ListBox();
		tweet_list.set_selection_mode(SelectionMode.NONE);
		tweet_list.get_style_context().add_class("stream");
		tweet_list.add_to_scrolled(this);
		tweet_list.set_sort_func(TweetListEntry.sort_func);

		this.scrolled_to_end.connect(() => {
			if(!loading) {
				loading = true;
				load_older();
			}
		});

	    this.scrolled_to_start.connect(() => {
        	if(tweet_list.get_size() > ITimeline.REST) {
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
	    });

        UserStream.get().register(this);
	}

	private void stream_message_received(StreamMessageType type, Json.Object root){
		if(type == StreamMessageType.TWEET) {
			if(root.get_string_member("text").contains("@"+User.screen_name)) {

				GLib.DateTime now = new GLib.DateTime.now_local();
				Tweet t = new Tweet();
				t.load_from_json(root, now);
				Tweet.cache.begin(t, Tweet.TYPE_MENTION);

				this.balance_next_upper_change(TOP);
				tweet_list.add(new TweetListEntry(t, main_window));
				tweet_list.resort();

				if(Settings.notify_new_mentions()) {
					NotificationManager.notify(
						"New Mention from @"+t.screen_name,
						t.text,
						Notify.Urgency.NORMAL,
						t.avatar);
				}
			}
		}
	}


	/**
	 * see IPage#onJoin
	 */
	public void on_join(int page_id, va_list arg_list){

	}

	public void load_cached() {
		try{
			this.load_cached_internal(Tweet.TYPE_MENTION);
		} catch(SQLHeavy.Error e){
			critical("Error while loading cached tweets of the home timeline: %s",
			         e.message);
		}
		tweet_list.resort();
		this.vadjustment.set_upper(0);
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
		this.balance_next_upper_change(BOTTOM);
		this.load_older_internal("1.1/statuses/mentions_timeline.json",
		                         Tweet.TYPE_MENTION,
        (count, lowest_id) => {
        	if(lowest_id < this.lowest_id){
        		this.lowest_id = lowest_id;
        		message("Setting lowest_id to new value(%s)", lowest_id.to_string());
        	}

        	this.loading = false;
        });
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