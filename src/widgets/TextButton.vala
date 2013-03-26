using Gtk;



class TextButton : Button {
	//TODO: Really use the hand cursor?
	// private Gdk.Cursor hand_cursor  = new Gdk.Cursor(Gdk.CursorType.HAND1);
	// private Gdk.Cursor arrow_cursor = new Gdk.Cursor(Gdk.CursorType.TOP_LEFT_ARROW);

	public TextButton(string label=""){
		if(label != "")
			this.label= label;
		this.get_style_context().add_class("text-button");


		// this.enter_notify_event.connect( () => {
			// this.get_window().cursor = hand_cursor;
			// return false;
		// });
		// this.leave_notify_event.connect( () => {
			// this.get_window().cursor = arrow_cursor;
			// return false;
		// });
	}


	/**
	 * Adds a GtkLabel to the Button using the given text as markup.
	 * If the button already contains another child, that will either be replaced if it's
	 * no instance of GtkLabel, or - if it's a GtkLabel already - be reused.
	 *
	 * @param text The markup to use(see pango markup)
	 */
	public void set_markup(string text) {
		Label label = null;
		Widget child = get_child();
		if(child != null){
			if(child is Label) {
				label = (Label)child;
				label.set_markup(text);
			}else{
				this.remove(child);
				label = new Label(text);
			}
		}else{
			label = new Label(text);
		}
		label.set_use_markup(true);
		label.set_justify(Justification.CENTER);

		label.visible = true;
		if(label.parent == null)
			this.add(label);
	}
}