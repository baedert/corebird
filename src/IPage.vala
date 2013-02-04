

interface IPage {
	public abstract void onJoin(int page_id, ...);
	public abstract void create_tool_button(Gtk.RadioToolButton? group);
	public abstract int get_id();
	public abstract Gtk.RadioToolButton? get_tool_button();
}