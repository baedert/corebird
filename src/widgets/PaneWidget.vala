
using Gtk;


/**
 * Fun stuff: every subclass of this 'Widget' must provide some kind of 
 * ID that identifies its content.
 * Example:
 *   If TweetWidget implements PaneWidget it could easily provide the 
 *   tweet's ID for its id.
 *
 * TODO: I HATE THIS.
**/
interface PaneWidget : GLib.Object{
	public abstract string get_id();
	public abstract void set_visible(bool visible);
	public abstract bool is_visible();
	public abstract Gtk.Widget get_widget();
}