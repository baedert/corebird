

class LoaderThread{
	private Json.Array root;
	private MainWindow window;
	private TweetList list;
	private Thread<void*> thread;

	public LoaderThread(Json.Array root, MainWindow window, TweetList list){
		this.root   = root;
		this.window = window;
		this.list   = list;
	}

	public void run(){
		thread = new Thread<void*>("TweetLoaderThrad", thread_func);
	}

	public void* thread_func(){
		GLib.DateTime now = new GLib.DateTime.now_local();
		SQLHeavy.Query cache_query = null;
		try{
			cache_query = new SQLHeavy.Query(Corebird.db,
			"INSERT INTO `cache`(`id`, `text`,`user_id`, `user_name`, `is_retweet`,
			                     `retweeted_by`, `retweeted`, `favorited`, `created_at`, `added_to_stream`,
			                     `avatar_name`, `screen_name`) 
			VALUES (:id, :text, :user_id, :user_name, :is_retweet, :retweeted_by,
			        :retweeted, :favorited, :created_at, :added_to_stream, :avatar_name,
			        :screen_name);");
		}catch(SQLHeavy.Error e){
			warning("Error in cache query: %s", e.message);
		}

		TweetListEntry[] entries = new TweetListEntry[root.get_length()];
		root.foreach_element( (array, index, node) => {
			Json.Object o = node.get_object();
			Tweet t = new Tweet();
			string created_at;
			int64 added_to_stream;
			Benchmark.start("Extracting tweet details");
			t.load_from_json(o, now, 
			out created_at, out added_to_stream);
			Benchmark.stop();
			
			
			
			// Check the tweeter's details and update them if necessary
			try{
				SQLHeavy.Query author_query = new SQLHeavy.Query(Corebird.db,
				"SELECT `id`, `screen_name`, `avatar_url` FROM `people`
				WHERE `id`='%d';".printf(t.user_id));
				SQLHeavy.QueryResult author_result = author_query.execute();
				if (author_result.finished){
					//The author is not in the DB so we insert him
					SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
					"INSERT INTO `people`(id,name,screen_name,avatar_url,avatar_name) VALUES ('%d', 
					'%s', '%s', '%s', '%s');".printf(t.user_id, t.user_name,
					t.screen_name, t.avatar_url, t.avatar_name));
					q.execute();
				}else{
					string old_avatar = author_result.fetch_string(2);
					if (old_avatar != t.avatar_url){
						SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
						"UPDATE `people` SET `avatar`='%s';".printf(t.avatar_url));
						q.execute();
					}
					if (t.user_name != author_result.fetch_string(1)){
						SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
						"UPDATE `people` SET `screen_name`='%s';".printf(t.user_name));						
						q.execute();
					}
				}
			}catch(SQLHeavy.Error e){
				warning("Error while updating author: %s", e.message);
			}
			
			
			// Insert tweet into cache table
			try{
				cache_query.set_string(":id", t.id);
				cache_query.set_string(":text", t.text);
				cache_query.set_int(":user_id", t.user_id);
				cache_query.set_string(":user_name", t.user_name);
				cache_query.set_int(":is_retweet", t.is_retweet ? 1 : 0);
				cache_query.set_string(":retweeted_by", t.retweeted_by);
				cache_query.set_int(":retweeted", t.retweeted ? 1 : 0);
				cache_query.set_int(":favorited", t.favorited ? 1 : 0);
				cache_query.set_string(":created_at", created_at);
				cache_query.set_int64(":added_to_stream", added_to_stream);
				cache_query.set_string(":avatar_name", t.avatar_name);
				cache_query.set_string(":screen_name", t.screen_name);
				cache_query.execute();
			}catch(SQLHeavy.Error e){
				error("Error while caching tweet: %s", e.message);
			}
			
			TweetListEntry entry  = new TweetListEntry(t, window);
			entries[index] = entry;
		});
		GLib.Idle.add( () => {
			for(int i = 0; i < entries.length; i++)
				list.insert_item(entries[i], i);
			list.hide_spinner();
			return false;
		});
		return null;
	}
}