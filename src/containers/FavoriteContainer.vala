using Gtk;


class FavoriteContainer : TweetContainer, TweetList {
	private MainWindow main_window;
	private RadioToolButton tool_button;
	private int id;


	public FavoriteContainer(int id){
		base();
		this.id = id;
	}


	public void refresh(){
	}

	public void load_cached(){
	}

	public void create_tool_button(RadioToolButton? group){
		tool_button = new RadioToolButton.from_widget(group);
		tool_button.icon_name = "emblem-favorite";
	}

	public RadioToolButton? get_tool_button(){
		return tool_button;
	}

	public void set_main_window(MainWindow main_window){
		this.main_window = main_window;
	}
	public int get_id(){
		return id;
	}
}