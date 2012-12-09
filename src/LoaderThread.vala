

class LoaderThread{
	private Json.Array root;
	private MainWindow window;
	private TweetList list;
	private Thread<void*> thread;
	public delegate void TweetReceivedFunc(Tweet t, string created_at, int64 added_to_stream);
	public delegate void EndLoadFunc(int tweet_count);
	private unowned TweetReceivedFunc? received_tweet;
	private unowned EndLoadFunc? finished;
	public bool balance_upper_change = true;

	public LoaderThread(Json.Array root, MainWindow window, TweetList list,
	                    TweetReceivedFunc? received_tweet = null,
	                    EndLoadFunc? finished = null){
		this.root           = root;
		this.window         = window;
		this.list           = list;
		this.received_tweet = received_tweet;
		this.finished       = finished;
	}

	public void run(){
		thread = new Thread<void*>("TweetLoaderThread", thread_func);
	}

	public void* thread_func(){
		GLib.DateTime now = new GLib.DateTime.now_local();

		TweetListEntry[] entries = new TweetListEntry[root.get_length()];
		root.foreach_element( (array, index, node) => {
			Json.Object o = node.get_object();
			Tweet t = new Tweet();
			string created_at;
			int64 added_to_stream;
			t.load_from_json(o, now, 
				out created_at, out added_to_stream);
			
			if (received_tweet != null)
				received_tweet(t, created_at, added_to_stream);

			TweetListEntry entry  = new TweetListEntry(t, window);
			entries[index] = entry;
		});
		GLib.Idle.add( () => {
			list.hide_spinner();
			//FIXME: God this sucks.
			if(balance_upper_change)
				((ScrollWidget)list.parent.parent).balance_next_upper_change();
				
			for(int i = 0; i < entries.length; i++)
				list.insert_item(entries[i], i);
			
			if (finished != null){
				finished(entries.length);
			}

			return false;
		});
		return null;
	}
}