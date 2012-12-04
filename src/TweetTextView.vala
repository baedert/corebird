using Gtk;


class TweetTextView : TextView {
	


	public override bool draw(Cairo.Context c){
		StyleContext context = this.get_style_context();
		int length = this.buffer.text.length;
		Allocation a;
		this.get_allocation(out a);
		Pango.Layout layout = this.create_pango_layout("");
		layout.set_markup("<small>%d/160</small>".printf(length), -1);
		Pango.Rectangle layout_size;
		layout.get_extents(null, out layout_size);

		base.draw(c);
		c.set_source_rgb(1.0, 0.0, 0.0);
		context.render_layout(c, a.width - (layout_size.width / Pango.SCALE) - 5,
		                      a.height - (layout_size.height / Pango.SCALE) - 5, layout);
		return false;
	}
}