using Rest;
using Gee;

class Twitter{
	private static string token;
	private static string token_secret;
	public static OAuthProxy proxy;
	public static Gdk.Pixbuf retweeted_img;
	public static Gdk.Pixbuf favorited_img;
	public static Gdk.Pixbuf retweeted_favorited_img;
	public static Gdk.Pixbuf no_avatar;
	public static HashMap<int, Gdk.Pixbuf> avatars;


	/**
	 * Returns the OAuth token
	 */
	public static string get_token(){
		if (Twitter.token == null){
			try{
				SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db, "SELECT `token` FROM `common` LIMIT 1;");
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
				SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db, "SELECT `token_secret` FROM `common` LIMIT 1;");
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
		proxy.token = Twitter.get_token();
		proxy.token_secret = Twitter.get_token_secret();

		try{
			Twitter.retweeted_img = new Gdk.Pixbuf.from_file("assets/retweeted.png");
			Twitter.favorited_img = new Gdk.Pixbuf.from_file("assets/favorited.png");
			Twitter.retweeted_favorited_img = 
					new Gdk.Pixbuf.from_file("assets/retweeted_favorited.png");
			Twitter.no_avatar = new Gdk.Pixbuf.from_file("assets/no_avatar.png");
		}catch(GLib.Error e){
			error("Error while loading assets: %s", e.message);
		}

		Twitter.avatars = new HashMap<int, Gdk.Pixbuf>();
	}
}