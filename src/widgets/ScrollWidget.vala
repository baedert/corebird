using Gtk;



class ScrollWidget : ScrolledWindow {
	private double upper_cache;
	private bool do_balance_next_upper_change = false;

	public ScrollWidget(){
		GLib.Object(hadjustment: null, vadjustment: null);
		vadjustment.notify["upper"].connect(()=>{
			double upper = vadjustment.upper;
			if (upper != upper_cache && do_balance_next_upper_change){
				this.vadjustment.value += (upper - upper_cache);
				do_balance_next_upper_change = false;
			}
			this.upper_cache = upper;
		});
		this.kinetic_scrolling = true;
	}

	public void balance_next_upper_change(){
		this.do_balance_next_upper_change = true;
	}

}