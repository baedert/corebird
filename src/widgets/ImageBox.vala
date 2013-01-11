using Gtk;

/**
 * A normal box, but with an image as background.
 * The image will always be drawn at the upper left corner
 * and it won't be stretched.(TODO: Change this)
 */
class ImageBox : Gtk.Box  {
	public Gdk.Pixbuf pixbuf;

	public ImageBox(Orientation orientation, int spacing){
		GLib.Object(orientation: orientation, spacing: spacing);
	}

	public override bool draw(Cairo.Context c){
		if(pixbuf != null){
			StyleContext context = this.get_style_context();
			context.render_icon(c, pixbuf, 0, 0);
		}
		
		//Boxes do not draw any background! YAY
		base.draw(c);
		return false;
	}

	public void set_pixbuf(Gdk.Pixbuf p) {
		this.pixbuf = p;
		this.queue_draw();
	}
	//TODO: Actually stretch/shrink the background image.
	//TODO: Implement second overlay image.(?)
}