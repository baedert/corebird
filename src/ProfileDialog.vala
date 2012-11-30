
using Gtk;


/**
 * A Dialog showing information about the given user.
 */
class ProfileDialog : Gtk.Dialog {
	


	public ProfileDialog(string screen_name = ""){
		if (screen_name == "")
			screen_name = User.screen_name;



	}

}