
using Gtk;


class BadgeRadioToolButton : Gtk.RadioToolButton {
	private int badge_value = 0;

	public BadgeRadioToolButton(RadioToolButton group, string stock_id) {
		GLib.Object(group: group, stock_id: stock_id);
	}

	public override bool draw(Cairo.Context c){
		var context = this.get_style_context();
		base.draw(c);
		if(badge_value == 0)
			return false;

		Allocation all;
		this.get_allocation(out all);

		Pango.Layout layout = this.create_pango_layout(badge_value.to_string());
		Pango.Rectangle size;
		layout.get_extents(null, out size);


		context.add_class("badge");
		Border padding = context.get_padding(get_state_flags());
		int x = all.width - (size.width / Pango.SCALE) - padding.left - padding.right;
		int y = 0;
		int w = (size.width / Pango.SCALE) + padding.left + padding.right;
		int h = (size.height / Pango.SCALE) + padding.top + padding.bottom;

		context.render_background(c, x, y, w, h);
		context.render_frame(c, x, y, w, h);

		context.render_layout(c, all.width  - (size.width / Pango.SCALE) - padding.right,
								 padding.top, layout);


		return false;
	}

	public void set_badge_value(int value){
		this.badge_value = value;
	}
}