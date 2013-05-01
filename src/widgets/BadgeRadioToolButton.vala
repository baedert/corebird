
using Gtk;


class BadgeRadioToolButton : Gtk.RadioToolButton {
	private static const int BADGE_SIZE = 10;
	public bool show_badge{ get; set; default = false;}

	public BadgeRadioToolButton(RadioToolButton group, string stock_id) {
		GLib.Object(group: group, stock_id: stock_id);
	}

	public override bool draw(Cairo.Context c){
		var context = this.get_style_context();
		base.draw(c);
		if(!show_badge)
			return false;


		int width = get_allocated_width();
		context.add_class("badge");
		context.render_background(c, width - BADGE_SIZE, 0, BADGE_SIZE, BADGE_SIZE);
		context.render_frame(c, width - BADGE_SIZE, 0, BADGE_SIZE, BADGE_SIZE);
		return false;
	}
}