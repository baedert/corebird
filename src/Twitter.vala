using Rest;
using Gee;

class Twitter{
	private static string token;
	private static string token_secret;
	private static int max_media_per_upload;
	private static int characters_reserved_per_media;
	private static int short_url_length;
	private static int short_url_length_https;
	private static int photo_size_limit;
	public static OAuthProxy proxy;
	public static Gdk.Pixbuf retweeted_img;
	public static Gdk.Pixbuf favorited_img;
	public static Gdk.Pixbuf retweeted_favorited_img;
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
		Twitter.proxy = new OAuthProxy(
        	"0rvHLdbzRULZd5dz6X1TUA",						//Consumer Key
        	"oGrvd6654nWLhzLcJywSW3pltUfkhP4BnraPPVNhHtY", 	//Consumer Secret
        	"https://api.twitter.com",						//Url Format
        	false
        );
        if (!Settings.is_first_run()){
			proxy.token = Twitter.get_token();
			proxy.token_secret = Twitter.get_token_secret();
		}

		try{
			Twitter.retweeted_img = new Gdk.Pixbuf.from_file("assets/retweeted.png");
			Twitter.favorited_img = new Gdk.Pixbuf.from_file("assets/favorited.png");
			Twitter.retweeted_favorited_img = 
					new Gdk.Pixbuf.from_file("assets/retweeted_favorited.png");
			Twitter.no_avatar = new Gdk.Pixbuf.from_file("assets/no_avatar.png");
			Twitter.no_banner = new Gdk.Pixbuf.from_file("assets/no_banner.png");
		}catch(GLib.Error e){
			error("Error while loading assets: %s", e.message);
		}

		Twitter.avatars = new HashMap<string, Gdk.Pixbuf>();
	}

	/**
	 * Updates the config
	 * TODO: Do this only once a day.
	 */
	public static async void update_config(){
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