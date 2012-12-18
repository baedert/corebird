using Gtk;




class TestToolButton : ToolButton {
	private Label count_label = new Label("");


	public TestToolButton(){
		count_label.set_use_markup(true);
		count_label.label = "<small>40</small>";
		count_label.get_style_context().add_class("badge");
	}

	// TODO: Use the count_label for drawing.


	public override bool draw(Cairo.Context c){
		var context = this.get_style_context();
		base.draw(c);
		Allocation all;
		this.get_allocation(out all);
	
		Pango.Layout layout = this.create_pango_layout("30");
		Pango.Rectangle size;
		layout.get_extents(null, out size);



		Allocation alloc = {};
		alloc.x = all.x;
		alloc.y = all.y;
		alloc.width = 35;
		alloc.height = 25;
		count_label.set_allocation(alloc);
		//c.move_to();
		count_label.draw(c);


/*		int x = all.width - (size.width / Pango.SCALE);
		int y = 0;
		context.add_class("badge");
		context.render_background(c, x, y, size.width / Pango.SCALE, size.height / Pango.SCALE);
		context.render_frame(c, x, y, size.width / Pango.SCALE, size.height / Pango.SCALE);

		context.render_layout(c, all.width  - (size.width / Pango.SCALE),
								 0, layout);*/


		return false;
	}
}