
using Soup;
using Rest;
using Gtk;




class Corebird : Gtk.Application {

	public Corebird() throws GLib.Error{

		GLib.Object(application_id: "org.baedert.corebird",
		            flags: ApplicationFlags.FLAGS_NONE);
		this.register_session = true;
		this.register();




		if (Settings.is_first_run())
		    this.add_window(new FirstRunWindow());
		else
			this.add_window(new MainWindow());
	}
}












int main (string[] args){
	Gtk.init(ref args);

	try{
		Settings.init();
		var corebird = new Corebird();
		corebird.run(args);
	} catch(GLib.Error e){
		stderr.printf(e.message+"\n");
		return -1;
	}

	/*

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
