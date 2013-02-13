
using Gtk;

class ProfilePage : IPage, ScrollWidget {
	private int id;
	private ProfileWidget profile_widget = new ProfileWidget();

	public ProfilePage(int id){
		this.id = id;
		this.add_with_viewport(profile_widget);
	}





	/**
	 * see IPage#onJoin
	 */
	public void onJoin(int page_id, va_list arg_list) {
		message("ProfilePage#onJoin");
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