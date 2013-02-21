
using Gtk;

class WidgetReplacer {

	public static void replace(Widget w1, Widget w2) {
		if(w1.parent == null)
			error("w1.parent = null");

		if(!(w1.parent is Gtk.Box))
			error("Only Box parents are supported ATM");

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

		parent.query_child_packing(w1, out expand, out fill, out padding, out pack_type);
		parent.remove(w1);

		w2.set_size_request(alloc.width, alloc.height);
		parent.pack_start(w2, expand, fill, padding);
		w2.visible = true;
		parent.set_child_packing(w2, expand, fill, padding, pack_type);
		parent.reorder_child(w2, pos);

	}
}