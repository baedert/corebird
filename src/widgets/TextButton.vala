using Gtk;



class TextButton : Button {
	private Gdk.Cursor hand_cursor  = new Gdk.Cursor(Gdk.CursorType.HAND1);
	private Gdk.Cursor arrow_cursor = new Gdk.Cursor(Gdk.CursorType.TOP_LEFT_ARROW);

	public TextButton(string label=""){
		if(label != "")
			this.label= label;
		this.get_style_context().add_class("text-button");


		this.enter_notify_event.connect( () => {
			this.get_window().cursor = hand_cursor;
			return false;
		});
		this.leave_notify_event.connect( () => {
			this.get_window().cursor = arrow_cursor;
			return false;
		});
	}

	public void set_markup(string text) {
		var label = new Label(text);
		label.set_use_markup(true);
		label.set_justify(Justification.CENTER);
		this.add(label);
	}
}