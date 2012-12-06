using Gtk;

/**
 * A button with the given pixbuf as background.
 */
class ImageButton : Button {
	public Gdk.Pixbuf bg {get; set;}


	public ImageButton(){
		this.border_width = 0;
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
}