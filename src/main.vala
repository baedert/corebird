
using Soup;
using Rest;
using Gtk;




class Corebird : Gtk.Application {



}












int main () {


	var proxy = new OAuthProxy(
	            "0rvHLdbzRULZd5dz6X1TUA",						//Consumer Key
	            "oGrvd6654nWLhzLcJywSW3pltUfkhP4BnraPPVNhHtY", 	//Consumer Secret
	            "https://api.twitter.com",						//Url Format
	            false
	            );




	proxy.token = "118055879-Uct8UjTQmtIPNZwEFE9tgMPV7YUdaEWkVbL88D8p";
	proxy.token_secret = "3ncxak11QEUbSKqLylk1lRU4AdmYAoTROk42n0Gmlak";


	//Request token
/*	try{
		proxy.request_token ("oauth/request_token", "oob");
	}catch(Error e){
		stderr.printf("Error while requesting token: "+e.message+"\n");
		return -1;
	}

	stdout.printf("Go to http://twitter.com/oauth/authorize?oauth_token=%s\n", 
	              proxy.get_token());

	stdout.printf("PIN: ");
	string pin = stdin.read_line();

	try{
		proxy.access_token("oauth/access_token", pin);
	}catch(Error e){
		stderr.printf("Couldn't access token: %s\n", e.message);
		return -2;
	}

	stdout.printf("TOKEN: %s\nTOKEN SECRET: %s\n",
	              proxy.token, proxy.token_secret);

*/


/*	ProxyCall call = proxy.new_call();
	call.set_function("1/statuses/update.xml");
	call.set_method("POST");
	call.add_param("status", "TEST!");
	try{
		call.sync();
	}catch(Error e){
		stderr.printf("Error while tweeting: %s\n", e.message);
		return -3;
	}*/

	return 0;
}
