using Gtk;


/**
 * Abstract base class for all containers.
 */
abstract interface TweetContainer : Widget{

	public abstract void set_main_window(MainWindow main_window);
	public abstract void load_cached();
	public abstract void refresh();
	public abstract void create_tool_button();
	public abstract RadioToolButton? get_tool_button();

}