using Gtk;

/**
 * A button with the given pixbuf as background.
 */
class ImageButton : Button {
	private Gdk.Pixbuf bg;


	public ImageButton(){
		this.border_width = 0;
		get_style_context().add_class("image-button");
	}

	public override bool draw(Cairo.Context c){
		if(bg!= null){
			StyleContext context = this.get_style_context();
			context.render_icon(c, bg, 0, 0);
		}
	
		// The css-styled background should be transparent.		
		base.draw(c);
		return false;
	}

	public void set_bg(Gdk.Pixbuf bg){
		this.bg = bg;
		this.set_size_request(bg.get_width(), bg.get_height());
		this.queue_draw();
	}
}