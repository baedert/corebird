using Gtk;


class FavoriteContainer : TweetContainer, TweetList {
	private MainWindow main_window;
	private RadioToolButton tool_button;

	public void refresh(){
	}

	public void load_cached(){
	}

	public void create_tool_button(){
		tool_button = new RadioToolButton(null);
		tool_button.icon_name = "emblem-favorite";
	}

	public RadioToolButton? get_tool_button(){
		return tool_button;
	}

	public void set_main_window(MainWindow main_window){
		this.main_window = main_window;
	}
	
}