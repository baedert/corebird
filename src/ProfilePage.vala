
using Gtk;

class ProfilePage : IPage, ScrollWidget {
	public static const int BY_ID   = 1;
	public static const int BY_NAME = 2;


	public int unread_count {
		get{return 0;}
		set{;}
	}
	private int id;
	private ProfileWidget profile_widget;

	public ProfilePage(int id, MainWindow window){
		profile_widget = new ProfileWidget(window);
		this.id = id;
		this.add_with_viewport(profile_widget);
	}





	/**
	 * see IPage#onJoin
	 */
	public void on_join(int page_id, va_list arg_list) {
		int mode = arg_list.arg();
		if(mode == BY_ID){
			int64 user_id = arg_list.arg();
			profile_widget.set_user_id(user_id);
		} else if(mode == BY_NAME) {
			string name = arg_list.arg();
			profile_widget.set_user_id(0, name);
		} else {
			critical("%d is no valid mode for ProfilePage", mode);
		}
	}


	public void create_tool_button(RadioToolButton? group) {}

	public RadioToolButton? get_tool_button(){
		return null;
	}

	public int get_id(){
		return id;
	}
}
