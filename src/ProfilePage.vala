
using Gtk;

class ProfilePage : IPage, Gtk.Box {
	private int id;


	public ProfilePage(int id){
		this.id = id;

	}





	/**
	 * see IPage#onJoin
	 */
	public void onJoin(int page_id, ...) {

	}


	public void create_tool_button(RadioToolButton? group) {}

	public RadioToolButton? get_tool_button(){
		return null;
	}

	public int get_id(){
		return id;
	}
}