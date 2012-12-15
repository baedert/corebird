using Gtk;




class ArrowButton : Button {
	private double angle;
	private double size;

	public ArrowButton(double angle = Math.PI/2.0, double size = 15){
		this.angle = angle;
		this.size  = size;
		get_style_context().add_class("arrow-button");
	}


	public override bool draw(Cairo.Context c){
		var context = this.get_style_context();
		base.draw(c);
		Allocation all;
		this.get_allocation(out all);
		context.render_arrow(c, angle, all.width-size, (all.height/2.0)-(size/2.0), size);
		return false;
	}
}