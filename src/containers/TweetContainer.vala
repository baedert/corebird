using Gtk;


/**
 * Abstract base class for all containers.
 * This just defines everything UI-Specific a container should provide.
 */
interface TweetContainer : Widget{

	public abstract void create_tool_button(RadioToolButton? group);
	public abstract int get_id();
	public abstract RadioToolButton? get_tool_button();

}