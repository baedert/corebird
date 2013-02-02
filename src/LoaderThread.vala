

class LoaderThread{
	private Json.Array root;
	private MainWindow? window;
	private Egg.ListBox list;
	private Thread<void*> thread;
	public delegate void EndLoadFunc(int tweet_count, int64 lowest_id);
	private unowned EndLoadFunc? finished;
	public bool balance_upper_change = true;
	private int tweet_type;
	private int64 lowest_id = -1;

	public LoaderThread(Json.Array root, MainWindow? window, Egg.ListBox list,
	                    int tweet_type = -1,
	                    EndLoadFunc? finished = null){
		this.root       = root;
		this.window     = window;
		this.list       = list;
		this.finished   = finished;
		this.tweet_type = tweet_type;
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
			t.load_from_json(o, now);

			if (tweet_type != -1){
				Tweet.cache(t, tweet_type);
			}

			if(t.id < lowest_id)
				lowest_id = t.id;

			TweetListEntry entry  = new TweetListEntry(t, window);
			entries[index] = entry;
		});

		GLib.Idle.add( () => {
			// list.hide_spinner();
			//FIXME: God this sucks.
			// if(balance_upper_change)
			// 	((ScrollWidget)list.parent.parent).balance_next_upper_change();


			message("Results: %d", entries.length);
			for(int i = 0; i < entries.length; i++)
				// list.insert(entries[i], i);
				list.add(entries[i]);

			if (finished != null){
				finished(entries.length, lowest_id);
			}

			return false;
		});

		return null;
	}
}