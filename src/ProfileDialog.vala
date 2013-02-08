
using Gtk;


/**
 * A Dialog showing information about the given user.
 */
class ProfileDialog : Gtk.Window {
	private ProfileWidget profile_widget;

	public ProfileDialog(int64 user_id = 0){
		if (user_id <= 0)
			user_id = User.get_id();
		message(@"ID: $user_id");

		profile_widget = new ProfileWidget();
		profile_widget.set_user_id(user_id);

		this.resize(320, 480);
		this.add(profile_widget);
	}
}