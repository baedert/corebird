using Gtk;


/**
 * Abstract base class for all containers.
 */
abstract class TweetContainer : ScrollWidget{
	protected MainWindow main_window;
	protected TweetList tweet_list;

	public void set_main_window(MainWindow main_window){
		this.main_window = main_window;
	}


	public abstract void load_cached();
	public abstract void refresh();
	public abstract RadioToolButton? get_tool_button();

}