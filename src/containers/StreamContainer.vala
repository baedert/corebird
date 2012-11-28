using Gtk;

class StreamContainer : TweetList{
	

	public StreamContainer(){
	}	




	public async void load_cached_tweets() throws SQLHeavy.Error{
		GLib.DateTime now = new GLib.DateTime.now_local();

		SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
			"SELECT `id`, `text`, `user_id`, `user_name`, `is_retweet`,
					`retweeted_by`, `retweeted`, `favorited`, `created_at`,
					`added_to_stream`, `avatar_name` FROM `cache`
			ORDER BY `added_to_stream` DESC LIMIT 30");
		SQLHeavy.QueryResult result = query.execute();
		while(!result.finished){
			Tweet t        = new Tweet();
			t.id           = result.fetch_string(0);
			t.text         = result.fetch_string(1);
			t.user_id      = result.fetch_int(2);
			t.user_name    = result.fetch_string(3);
			t.is_retweet   = (bool)result.fetch_int(4);
			t.retweeted_by = result.fetch_string(5);
			t.retweeted    = (bool)result.fetch_int(6);
			t.favorited    = (bool)result.fetch_int(7);

			GLib.DateTime created = Utils.parse_date(result.fetch_string(8));
			t.time_delta = Utils.get_time_delta(created, now);
			t.avatar_name  = result.fetch_string(10); 
			t.load_avatar();

			// Append the tweet to the TweetList
			TweetListEntry list_entry = new TweetListEntry(t);
			list_entry.tweet = t;
			this.add_tweet(list_entry);

			result.next();
		}
	}

	public async void load_new_tweets() throws SQLHeavy.Error {
		GLib.DateTime now = new GLib.DateTime.now_local();


		SQLHeavy.Query id_query = new SQLHeavy.Query(Corebird.db,
			"SELECT `id`, `added_to_stream` FROM `cache` ORDER BY `added_to_stream` DESC LIMIT 1;");
		SQLHeavy.QueryResult id_result = id_query.execute();
		int64 greatest_id = id_result.fetch_int64(0);
		message("greatest_id: %s", greatest_id.to_string());


		var call = Twitter.proxy.new_call();
		call.set_function("1.1/statuses/home_timeline.json");
		call.set_method("GET");
		call.add_param("count", "4");
		call.add_param("include_entities", "false");
		if(greatest_id > 0)
			call.add_param("since_id", greatest_id.to_string());

		call.invoke_async.begin(null, () => {
			string back = call.get_payload();
			stdout.printf(back+"\n");
			var parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			}catch(GLib.Error e){
				warning("Problem with json data from twitter: %s", e.message);
				return;
			}
			if (parser.get_root().get_node_type() != Json.NodeType.ARRAY){
				warning("Root node is no Array.");
				warning("Back: %s", back);
				return;
			}


			var root = parser.get_root().get_array();

			SQLHeavy.Query cache_query = null;
			try{
				cache_query = new SQLHeavy.Query(Corebird.db,
				"INSERT INTO `cache`(`id`, `text`,`user_id`, `user_name`, `time`, `is_retweet`,
				                     `retweeted_by`, `retweeted`, `favorited`, `created_at`, `added_to_stream`,
				                     `avatar_name`) 
				VALUES (:id, :text, :user_id, :user_name, :time, :is_retweet, :retweeted_by,
				        :retweeted, :favorited, :created_at, :added_to_stream, :avatar_name);");
			}catch(SQLHeavy.Error e){
				warning("Error in cache query: %s", e.message);
			}

			
			root.foreach_element( (array, index, node) => {
				Json.Object o = node.get_object();
				Json.Object user = o.get_object_member("user");
				Tweet t = new Tweet();
				t.text = o.get_string_member("text");
				t.favorited = o.get_boolean_member("favorited");
				t.retweeted = o.get_boolean_member("retweeted");
				t.id = o.get_string_member("id_str");
				t.user_name = user.get_string_member("name");
				t.user_id = (int)user.get_int_member("id");
				string created_at = o.get_string_member("created_at");
				string display_name = user.get_string_member("screen_name");
				int64 added_to_stream = Utils.parse_date(created_at).to_unix();

				t.avatar_url = user.get_string_member("profile_image_url");
				t.avatar_name = t.avatar_url.substring(t.avatar_url.last_index_of("/") + 1);
				stdout.printf(" URL: %s\nNAME:%s\n", t.avatar_url, t.avatar_name);
				// stdout.printf(t.avatar_name+"\n");

				
				if (o.has_member("retweeted_status")){
					Json.Object rt = o.get_object_member("retweeted_status");
					t.is_retweet = true;
					t.retweeted_by = user.get_string_member("name");
					t.text = rt.get_string_member("text");
					t.id = rt.get_string_member("id_str");
					Json.Object rt_user = rt.get_object_member("user");
					t.user_name = rt_user.get_string_member ("name");
					t.avatar_url = rt_user.get_string_member("profile_image_url");
					t.avatar_name = t.avatar_url.substring(t.avatar_url.last_index_of("/") + 1);
					t.user_id = (int)rt_user.get_int_member("id");
					created_at = rt.get_string_member("created_at");
					display_name = rt_user.get_string_member("screen_name");
				}
				GLib.DateTime dt = Utils.parse_date(created_at);
				t.time_delta = Utils.get_time_delta(dt, now);

				stdout.printf("%u: %s\n", index, t.user_name);


				t.load_avatar();
				if(!t.has_avatar()){
					// message("Downloading avatar for %s", t.user_name);
					File av = File.new_for_uri(t.avatar_url);
					stdout.printf("assets/avatars/%s".printf(t.avatar_name));
					File dest = File.new_for_path("assets/avatars/%s".printf(t.avatar_name));
					try{
						av.copy(dest, FileCopyFlags.OVERWRITE); 
					}catch(GLib.Error e){
						warning("Problem while downloading avatar: %s", e.message);
					}
					t.load_avatar();
				}

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
							display_name, t.avatar_url, t.avatar_name));
						q.execute_async.begin();
					}else{
						string old_avatar = author_result.fetch_string(2);
						if (old_avatar != t.avatar_url){
							SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
							    "UPDATE `people` SET `avatar`='%s';".printf(t.avatar_url));
							q.execute_async.begin();
						}
						if (t.user_name != author_result.fetch_string(1)){
							SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
								"UPDATE `people` SET `screen_name`='%s';".printf(t.user_name));						
							q.execute_async.begin();
						}
					}
				}catch(SQLHeavy.Error e){
					warning("Error while updating author: %s", e.message);
				}
	

				// Insert tweet into cache table
				try{
					TimeVal time = {};
					time.get_current_time();
					cache_query.set_string(":id", t.id);
					cache_query.set_string(":text", t.text);
					cache_query.set_int(":user_id", t.user_id);
					cache_query.set_string(":user_name", t.user_name);
					cache_query.set_int64(":time", (int64)time.tv_usec);
					cache_query.set_int(":is_retweet", t.is_retweet ? 1 : 0);
					cache_query.set_string(":retweeted_by", t.retweeted_by);
					cache_query.set_int(":retweeted", t.retweeted ? 1 : 0);
					cache_query.set_int(":favorited", t.favorited ? 1 : 0);
					cache_query.set_string(":created_at", created_at);
					cache_query.set_int64(":added_to_stream", added_to_stream);
					cache_query.set_string(":avatar_name", t.avatar_name);
					cache_query.execute_async.begin();
				}catch(SQLHeavy.Error e){
					error("Error while caching tweet: %s", e.message);
				}

				TweetListEntry entry  = new TweetListEntry(t);
				this.insert_tweet(entry, index);
				index--;
			});
		});

	}
}