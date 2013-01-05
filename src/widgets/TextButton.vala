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

	public override bool draw(Cairo.Context c){
		base.draw(c);
		// var context = get_style_context();
		// var layout = this.create_pango_layout(this.label);
		// Allocation all;
		// this.get_allocation(out all);

		// Pango.Rectangle ink_rect;
		// layout.get_extents(out ink_rect, null);

		// int x = 0;
		// int y = 0;

		// Gtk.Border border = context.get_border(context.get_state());
		// x += border.left;

		// context.render_layout(c, x,
		                      /*(all.height/2.0) - (ink_rect.height/2.0 / Pango.SCALE)*/
		                      // y, layout);
		// base.draw(c);
		return false;
	}


	// public override void realize(){
	// 	this.set_realized(true);
	// 	Gdk.WindowAttr attr = {};
	// 	Allocation allocation;
	// 	this.get_allocation(out allocation);
	// 	attr.x           = allocation.x;
	// 	attr.y           = allocation.y;
	// 	attr.width       = allocation.width;
	// 	attr.height      = allocation.height;
	// 	attr.window_type = Gdk.WindowType.CHILD;
	// 	attr.wclass      = Gdk.WindowWindowClass.INPUT_ONLY;

	// 	Gdk.Window parent_window = this.get_parent().get_window();

	// 	Gdk.Window win = new Gdk.Window(null, attr,
	// 		Gdk.WindowAttributesType.CURSOR);
	// 	win.set_events(Gdk.EventMask.ALL_EVENTS_MASK);
	// 	// this.set_has_window(true);
	// 	this.set_window(parent_window);

	// 	this.enter_notify_event.connect( () => {
	// 		message("hihi");
	// 		return false;
	// 	});
	// 	base.realize();
	// }
}