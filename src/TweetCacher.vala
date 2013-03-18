

class TweetCacher : GLib.Object {
	private static TweetCacher instance;
	private GLib.SList<Tweet> queue = new GLib.SList<Tweet>();
	private bool ready = false;

	private TweetCacher(){}

	/**
	* Returns the one and only instance of TweetCacher
	*
  	* @return The singleton instance of this class.
	**/
	public static new TweetCacher get(){
		if(instance == null)
			instance = new TweetCacher();
		return instance;
	}

	/**
	* Queues the given tweet for caching.
	* Caching will happen whenever someone called start()
	* and the list is not empty.
	* Caching will end if the list is empty of someone
	* called the stop() method.
	*
	* @param t The tweet to queue for later caching.
	**/
	public void enqueue(Tweet t) {
		queue.append(t);
	}

	/**
	* Begin caching.
	**/
	public void start() {
		ready = true;
		do_cache();
	}

	/**
	 * Asynchronously start caching.
	 * Actually, start() is also
	 */
	public async void start_sync() {
		ready = true;
		// Use only one idle callback
		GLib.Idle.add(() => {
			do{}while(cache_tweet());
			return false;
		});

	}

	/**
	* End caching. Note that if there's currently a caching in progress,
	* it won't be cancelled but it will be the last cached Tweet until
	* start() gets called again.
	**/
	public void stop() {
		ready = false;
	}

	/**
	* @return Whether the queue is empty or not
	**/
	public bool queue_empty() {
		return queue.length() == 0;
	}

	/**
	 * Cache the tweets asynchronously(through GLib.Idle). Caching will stop
	 * if the queue is empty or 'ready' becomes false.
	 */
	private void do_cache() {
		GLib.Idle.add(() => {
			return ready && cache_tweet();
		});
	}

	/**
	 * Caches exactly one tweet.
	 *
	 * @return true if there are more tweets in the queue, false otherwise.
	 */
	private bool cache_tweet(){
		Tweet t = queue.nth_data(0);
		if(t == null){
			ready = false;
			return false;
		}

		queue.remove(t);
		Tweet.cache(t, t.type);
		message("(%s)Caching tweet from %s",
		        ready ? "TRUE" : "FALSE", t.user_name);

		return true;
	}

}
