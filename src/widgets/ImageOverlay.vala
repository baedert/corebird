using Gtk;


class ImageOverlay : Gtk.Image {
	public Gdk.Pixbuf overlay_image {get; set; default = null;}

	public ImageOverlay() {
		this.get_style_context().add_class("image-overlay");
	}



	public override bool draw(Cairo.Context c) {
		Gtk.StyleContext style_context = this.get_style_context();
		Gtk.Border padding = style_context.get_padding(get_state_flags());
		c.translate(0, padding.top);
		base.draw(c);
		if(overlay_image != null)
			style_context.render_icon(c, overlay_image,
			                          get_allocated_width() - 16,
			                          0);

		return false;
	}

	public override void get_preferred_width(out int minimum, out int natural) {
		int m, n;
		base.get_preferred_width(out m, out n);
		Gtk.Border padding = get_style_context().get_padding(get_state_flags());
		minimum = m + padding.left + padding.right;
		natural = n + padding.left + padding.right;
	}

	public override void get_preferred_height(out int minimum, out int natural) {
		int m, n;
		base.get_preferred_height(out m, out n);
		Gtk.Border padding = get_style_context().get_padding(get_state_flags());
		minimum = m + padding.top + padding.bottom;
		natural = n + padding.top + padding.bottom;
	}

}