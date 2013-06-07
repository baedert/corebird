/*  This file is part of corebird.
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;

class WidgetReplacer {
	private static Gee.HashMap<Gtk.Widget, Gtk.Widget> tmp_widgets =
									new Gee.HashMap<Gtk.Widget, Gtk.Widget>();



	public static void replace_tmp(Widget w1, owned Widget w2,
	                               bool take_size = true) {
		tmp_widgets.set(w1, w2);
		replace(w1, w2, take_size, true);
	}

	public static void replace_tmp_back(Widget w, bool take_size = true) {
		Widget w2 = tmp_widgets.get(w);
		replace(w2, w, take_size);
		tmp_widgets.unset(w);
	}


	public static void replace(Widget w1, Widget w2, bool take_size = true,
	                           bool force_visible = false) {
		if(w1.parent == null)
			error("w1 has no parent");
		if(!(w1.parent is Gtk.Box) && !(w1.parent is Gtk.Bin))
			error("Only GtkBox and GtkBin is supported as parent ATM");

		Widget parent = w1.parent;

		if(take_size) {
			Allocation alloc;
			w1.get_allocation(out alloc);
			w2.set_size_request(alloc.width, alloc.height);
			message("Replacing widget of type %s with size %d/%d",
			        w1.get_type().name(), alloc.width, alloc.height);
		}

		if(parent is Gtk.Box){
			Gtk.Box box_parent = (Box) parent;
			bool expand;
			bool fill;
			uint padding;
			PackType pack_type;

			int pos = 0;
			int i = 0;
			box_parent.@foreach((widget) => {
				if(widget == w1){
					pos = i;
				}
				i++;
			});

			box_parent.query_child_packing(w1, out expand, out fill, out padding,
			                           out pack_type);
			box_parent.remove(w1);
			box_parent.pack_start(w2, expand, fill, padding);
			box_parent.set_child_packing(w2, expand, fill, padding, pack_type);
			box_parent.reorder_child(w2, pos);
		}else if(parent is Gtk.Bin) {
			Bin bin_parent = (Bin) parent;
			bin_parent.remove(w1);
			bin_parent.add(w2);
		}

		if(force_visible)
			w2.visible = true;
	}
}