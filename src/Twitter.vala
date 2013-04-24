using Rest;
using Gee;

class Twitter {
	private static string token;
	private static string token_secret;
	private static int max_media_per_upload;
	private static int characters_reserved_per_media;
	private static int short_url_length;
	private static int short_url_length_https;
	private static int photo_size_limit;
	public static OAuthProxy proxy;
	public static Gdk.Pixbuf no_avatar;
	public static Gdk.Pixbuf no_banner;
	public static HashMap<string, Gdk.Pixbuf> avatars;


	/**
	 * Returns the OAuth token
	 */
	public static string get_token(){
		if (Twitter.token == null){
			try{
				SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
					"SELECT `token` FROM `common` LIMIT 1;");
				SQLHeavy.QueryResult result = q.execute();
				Twitter.token = result.fetch_string();
				return Twitter.token;
			}catch(SQLHeavy.Error e){
				stderr.printf("Error while retrieving token: %s\n", e.message);
			}
		}
		return Twitter.token;
	}

	/**
	 * Returns the OAuth token secret
	 */
	public static string get_token_secret(){
		if (Twitter.token_secret == null){
			try{
				SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
				   "SELECT `token_secret` FROM `common` LIMIT 1;");
				SQLHeavy.QueryResult result = q.execute();
				Twitter.token_secret = result.fetch_string();
				return Twitter.token_secret;
			}catch(SQLHeavy.Error e){
				error("Error while retrieving token_secret: %s", e.message);
			}
		}
		return Twitter.token_secret;
	}


	public static void init(){
		//TODO: Obfuscate this somehow
		Twitter.proxy = new OAuthProxy(
        	"0rvHLdbzRULZd5dz6X1TUA",						//Consumer Key
        	"oGrvd6654nWLhzLcJywSW3pltUfkhP4BnraPPVNhHtY", 	//Consumer Secret
        	"https://api.twitter.com/",					//Url Format
        	false
        );
        if (!Settings.is_first_run()){
			proxy.token = Twitter.get_token();
			proxy.token_secret = Twitter.get_token_secret();
		}

		try{
			Twitter.no_avatar     	 = new Gdk.Pixbuf.from_file(
			                               DATADIR+"/no_avatar.png");
			Twitter.no_banner     	 = new Gdk.Pixbuf.from_file(
			                               DATADIR+"/no_banner.png");
		}catch(GLib.Error e){
			error("Error while loading assets: %s", e.message);
		}

		Twitter.avatars = new HashMap<string, Gdk.Pixbuf>();
	}

	/**
	 * Updates the config
	 */
	public static async void update_config(){
		// Check when the last update was
		var now = new GLib.DateTime.now_local();
		try{
			SQLHeavy.Query time_query = new SQLHeavy.Query(Corebird.db,
				"SELECT `update_config`, `characters_reserved_per_media`,
				`max_media_per_upload`, `photo_size_limit`, `short_url_length`,
				`short_url_length_https` FROM `common`;");
			SQLHeavy.QueryResult time_result = time_query.execute();
			int64 last_update = time_result.fetch_int64(0);
			var then = new GLib.DateTime.from_unix_local(last_update);

			var diff = then.difference(now);
			if (diff < GLib.TimeSpan.DAY * 7){
				Twitter.characters_reserved_per_media = time_result.fetch_int(1);
				Twitter.max_media_per_upload          = time_result.fetch_int(2);
				Twitter.photo_size_limit              = time_result.fetch_int(3);
				Twitter.short_url_length              = time_result.fetch_int(4);
				Twitter.short_url_length_https        = time_result.fetch_int(5);
				return;
			}
		}catch(SQLHeavy.Error e){
			warning("Error while querying config: %s", e.message);
			return;
		}



		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/help/configuration.json");
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end(res);
			} catch (GLib.Error e){
				warning("Error while refreshing config: %s", e.message);
			}
			string back = call.get_payload();
			Json.Parser parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			}catch(GLib.Error e){
				warning("Error while parsing Json: %s\nData:%s", e.message, back);
				return;
			}

			var root = parser.get_root().get_object();
			Twitter.characters_reserved_per_media =
				(int)root.get_int_member("characters_reserved_per_media");
			Twitter.max_media_per_upload   = (int)root.get_int_member("max_media_per_upload");
			Twitter.photo_size_limit       = (int)root.get_int_member("photo_size_limit");
			Twitter.short_url_length       = (int)root.get_int_member("short_url_length");
			Twitter.short_url_length_https = (int)root.get_int_member("short_url_length_https");

			//Update the stuff in the database
			try{
				Corebird.db.execute(@"UPDATE `common` SET
				`update_config`='%d',
				`characters_reserved_per_media`='$characters_reserved_per_media',
				`photo_size_limit`='$photo_size_limit',
				`short_url_length`='$short_url_length',
				`short_url_length_https`='$short_url_length_https';".printf(now.to_unix()));
			}catch(SQLHeavy.Error e){
				error("Error while updating the twitter config: %s", e.message);
			}

			message("Updated the twitter configuration");
		});
	}

	public static int get_characters_reserved_by_media(){
		return characters_reserved_per_media;
	}
	public static int get_max_media_per_upload(){
		return max_media_per_upload;
	}
	public static int get_photo_size_limit(){
		return photo_size_limit;
	}
	public static int get_short_url_length(){
		return short_url_length;
	}
	public static int get_short_url_length_https(){
		return short_url_length_https;
	}
}
