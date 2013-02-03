
using Gtk;

class MentionsTimeline : Timeline, ScrollWidget {
	public MainWindow main_window{set;get;}
	protected int64 max_id{get;set;}
	protected Egg.ListBox tweet_list{set;get;}
	private int id;
	private RadioToolButton tool_button;

	public MentionsTimeline(int id){
		this.id = id;
		tweet_list = new Egg.ListBox();
		tweet_list.set_sort_func((tle1, tle2) => {
			if(((TweetListEntry)tle1).timestamp <
			   ((TweetListEntry)tle2).timestamp)
				return 1;
			else
				return -1;
			return 0;
		});
		this.add_with_viewport(tweet_list);

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
		this.load_newest_internal("1.1/statuses/mentions_timeline.json",
	    	                      Tweet.TYPE_MENTION);
	}

	public void load_older() {

	}


	public void create_tool_button(RadioToolButton? group){
		if(group == null)
			tool_button = new RadioToolButton.from_stock(null, Stock.HOME);
		else
			tool_button = new RadioToolButton.with_stock_from_widget(group, Stock.CANCEL);
	}

	public RadioToolButton? get_tool_button(){
		return tool_button;
	}

	public int get_id(){
		return id;
	}
}