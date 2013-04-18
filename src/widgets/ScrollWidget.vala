using Gtk;

const int TOP    = 1;
const int BOTTOM = 2;
const int NONE   = 0;

class ScrollWidget : ScrolledWindow {
	private double upper_cache;
	private double value_cache;
	private int balance = NONE;
	private uint last_scroll_dir = 0;

	public ScrollWidget(){
		GLib.Object(hadjustment: null, vadjustment: null);
		vadjustment.notify["upper"].connect(keep_upper_func);
		vadjustment.notify["value"].connect(keep_value_func);

		this.kinetic_scrolling = true;
	}

	private void keep_upper_func() {
		// message("BALANCE UPPER");
		double upper = vadjustment.upper;
		if (balance == TOP){
			double inc = (upper - upper_cache);
			// message("DIFF: %f", inc);

			this.vadjustment.value += inc;
			balance = NONE;
		}
		this.upper_cache = vadjustment.upper;
		this.value_cache = vadjustment.value;
	}

	private void keep_value_func () {
		// message("BALANCE VALUE");
		double upper = vadjustment.upper;
		if (balance == BOTTOM){
			double inc = (upper - upper_cache);
			// message("DIFF: %f", inc);

			this.vadjustment.value -= inc;
			balance = NONE;
		}
		if(value_cache < vadjustment.value)
			last_scroll_dir = 1;
		else if(value_cache > vadjustment.value)
			last_scroll_dir = -1;
		else
			last_scroll_dir = 0;

		this.upper_cache = vadjustment.upper;
		this.value_cache = vadjustment.value;

	}

	public void balance_next_upper_change(int mode){
		// if(mode == TOP)
		// 	message("SETTING MODE TO TOP");
		// else
		// 	message("SETTING MODE TO BOTTOM");
		balance = mode;
	}

	public uint get_last_scroll_dir(){
		return last_scroll_dir;
	}

}