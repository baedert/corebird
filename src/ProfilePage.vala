
using Gtk;

class ProfilePage : IPage, Gtk.Box {
	private int id;
	private ProfileWidget profile_widget = new ProfileWidget();

	public ProfilePage(int id){
		this.id = id;
		this.pack_start(profile_widget, true, true);
	}





	/**
	 * see IPage#onJoin
	 */
	public void onJoin(int page_id, va_list arg_list) {
		int64 user_id = arg_list.arg();
		profile_widget.set_user_id(user_id);
	}


	public void create_tool_button(RadioToolButton? group) {}

	public RadioToolButton? get_tool_button(){
		return null;
	}

	public int get_id(){
		return id;
	}
}