using Gtk;



class TextButton : Button {
	private Gdk.Cursor hand_cursor = new Gdk.Cursor(Gdk.CursorType.HAND1);
	private Gdk.Cursor last_cursor;
	
	public TextButton(string label){
		this.label= label;	
		this.get_style_context().add_class("text-button");


		this.enter_notify_event.connect( () => {
			this.last_cursor = this.get_window().cursor;
			this.get_window().cursor = hand_cursor;
			return false;
		});
		this.leave_notify_event.connect( () => {
			this.get_window().cursor = last_cursor;
			return false;
		});
	}
}