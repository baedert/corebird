using Gtk;


class TweetTextView : TextView {
	private const uint MAX_TWEET_LENGTH = 140;
	public bool too_long{get;set; default = false;}
	private int length = 0;

	public TweetTextView(){
		this.key_release_event.connect( () => {
			this.length = this.buffer.text.length;
			this.too_long = this.length > MAX_TWEET_LENGTH;
			this.queue_draw();
			return false;
		});
	}


	public override bool draw(Cairo.Context c){
		StyleContext context = this.get_style_context();
		Allocation a;
		this.get_allocation(out a);
		Pango.Layout layout = this.create_pango_layout("");
		if (too_long)
			layout.set_markup("<small><span color='red'>%d/%u</span></small>".
			        printf(length, MAX_TWEET_LENGTH), -1);
		else
			layout.set_markup("<small>%d/%u</small>".printf(length, MAX_TWEET_LENGTH), -1);

		Pango.Rectangle layout_size;
		layout.get_extents(null, out layout_size);

		base.draw(c);
		context.render_layout(c, a.width  - (layout_size.width  / Pango.SCALE) - 5,
		                    	 a.height - (layout_size.height / Pango.SCALE) - 5, layout);
		return false;
	}

	public int get_length(){
		return length;
	}
}