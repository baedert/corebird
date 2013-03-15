

interface IPage : Gtk.Widget {
	public abstract void onJoin(int page_id, va_list arg_list);
	public abstract void create_tool_button(Gtk.RadioToolButton? group);
	public abstract int get_id();
	public abstract Gtk.RadioToolButton? get_tool_button();
	public abstract int unread_count{get;}
}