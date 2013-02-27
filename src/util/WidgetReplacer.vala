
using Gtk;

// TODO: TweetMarker integration

class WidgetReplacer {
	private static Gee.HashMap<Gtk.Widget, Gtk.Widget> tmp_widgets =
									new Gee.HashMap<Gtk.Widget, Gtk.Widget>();



	public static void replace_tmp(Widget w1, owned Widget w2) {
		tmp_widgets.set(w1, w2);
		replace(w1, w2);
	}

	public static void replace_tmp_back(Widget w, bool take_size = true) {
		Widget w2 = tmp_widgets.get(w);
		replace(w2, w, take_size);
		tmp_widgets.unset(w);
	}


	public static void replace(Widget w1, Widget w2, bool take_size = true) {
		if(w1.parent == null)
			error("w1 has no parent");
		if(!(w1.parent is Gtk.Box))
			error("Only Gtk.Box is supported as parent ATM");

		Box parent = (Box) w1.parent;

		bool expand;
		bool fill;
		uint padding;
		PackType pack_type;

		int pos = 0;
		int i = 0;
		parent.@foreach((widget) => {
			if(widget == w1){
				pos = i;
			}
			i++;
		});

		Allocation alloc;
		w1.get_allocation(out alloc);
		message("Replacing widget of type %s with size %d/%d",
		        w1.get_type().name(), alloc.width, alloc.height);

		parent.query_child_packing(w1, out expand, out fill, out padding, out pack_type);
		parent.remove(w1);

		if(take_size)
			w2.set_size_request(alloc.width, alloc.height);
		parent.pack_start(w2, expand, fill, padding);
		w2.visible = true;
		parent.set_child_packing(w2, expand, fill, padding, pack_type);
		parent.reorder_child(w2, pos);

	}
}