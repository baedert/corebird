/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
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

public class WidgetReplacer {
  private static Gee.HashMap<Gtk.Widget, Gtk.Widget> tmp_widgets =
                  new Gee.HashMap<Gtk.Widget, Gtk.Widget>();



  public static void replace_tmp(Widget w1, owned Widget w2,
                                 bool take_size = true) {
    tmp_widgets.set(w1, w2);
    replace(w1, w2, take_size, true);
  }

  public static void replace_tmp_back(Widget w, bool take_size = true,
                                      bool force_visible = false) {
    Widget w2 = tmp_widgets.get(w);
    replace(w2, w, take_size, force_visible);
    tmp_widgets.unset(w);
  }


  public static void replace(Widget w1, Widget w2, bool take_size = true,
                             bool force_visible = false) {
    if(w1.parent == null)
      error("w1 has no parent");
    if(!(w1.parent is Gtk.Box) && !(w1.parent is Gtk.Bin) && !(w1.parent is Gtk.Grid))
      error("Only GtkBox, GtkGrid and GtkBin is supported as parent ATM");

    Widget parent = w1.parent;

    if (take_size) {
      Allocation alloc;
      w1.get_allocation(out alloc);
      w2.set_size_request(alloc.width, alloc.height);
    }
      w2.valign        = w1.valign;
      w2.halign        = w1.halign;
      w2.hexpand       = w1.hexpand;
      w2.vexpand       = w1.vexpand;
      w2.margin_top    = w1.margin_top;
      w2.margin_left   = w1.margin_left;
      w2.margin_right  = w1.margin_right;
      w2.margin_bottom = w1.margin_bottom;

    if (parent is Gtk.Box) {
      Gtk.Box box_parent = (Box) parent;
      bool expand, fill;
      Gtk.PackType pack_type;
      int padding, position;
      box_parent.child_get (w1, "expand", out expand,
                                "fill", out fill,
                                "pack_type", out pack_type,
                                "padding", out padding,
                                "position", out position);
      box_parent.remove (w1);
      box_parent.add (w2);
      box_parent.reorder_child (w2, position);
      box_parent.set_child_packing (w2, expand, fill, padding, pack_type);


    } else if (parent is Gtk.Bin) {
      Bin bin_parent = (Bin) parent;
      bin_parent.remove(w1);
      bin_parent.add(w2);
    } else if (parent is Gtk.Grid) {
      int x, y, width, height;
      Container c = (Container)parent;
      c.child_get (w1, "left-attach", out x);
      c.child_get (w1, "top-attach", out y);
      c.child_get (w1, "width", out width);
      c.child_get (w1, "height", out height);
      c.remove (w1);
      ((Gtk.Grid)c).attach (w2, x, y, width, height);
    }

    if(force_visible)
      w2.visible = true;
  }
}
