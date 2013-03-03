



class UserStream : Object{
	private static UserStream instance;
	public static new UserStream get(){
		if(instance == null)
			instance = new UserStream();

		return instance;
	}


	private Rest.OAuthProxy proxy;
	private StringBuilder data = new StringBuilder();



	public UserStream() {
		proxy = new Rest.OAuthProxy(
        	"0rvHLdbzRULZd5dz6X1TUA",						//Consumer Key
        	"oGrvd6654nWLhzLcJywSW3pltUfkhP4BnraPPVNhHtY", 	//Consumer Secret
        	"https://userstream.twitter.com/",				//Url Format
        	false
        );

        proxy.token = Twitter.get_token();
		proxy.token_secret = Twitter.get_token_secret();
	}





	public void start() {
		var call = proxy.new_call();
		call.set_function("1.1/user.json");
		call.set_method("GET");
		call.continuous(parse_data_cb, this);
	}



	private void parse_data_cb(Rest.ProxyCall call, string buf, size_t length,
	                           Error? error) {
		string real = buf.substring(0, (int)length);

		data.append(real);

		if(real.has_suffix("\r\n")) {
			if(real == "\r\n") {
				data.erase();
				return;
			}

			var parser = new Json.Parser();
			parser.load_from_data(data.str);

			var root = parser.get_root().get_object();

			data.erase();
		}
	}

}



