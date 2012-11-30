using Gtk;

/**
 * A normal box, but with an image as background.
 * The image will always be drawn at the upper right corner and it won't be stretched.
 */
class ImageBox : Gtk.Box  {
	public Gdk.Pixbuf pixbuf;

	public ImageBox(Orientation orientation, int spacing){
		GLib.Object(orientation: orientation, spacing: spacing);
		//Default size of mobile-banner
		set_size_request(160, 320);
	}

	public override bool draw(Cairo.Context c){
		if(pixbuf != null){
			StyleContext context = this.get_style_context();
			context.render_icon(c, pixbuf, 0, 0);
		}
		base.draw(c);
		return false;
	}

	public void set_pixbuf(Gdk.Pixbuf p){
		this.pixbuf = p;
		this.queue_draw();
		set_size_request(80, p.get_height());
	}
	//TODO: Actually stretch/shrink the background image.
	//TODO: Implement second overlay image.(?)
}