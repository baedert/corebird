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

class MaxSizeContainer : Gtk.Bin {
  private Gdk.Window? event_window = null;
  private int _max_size = 0;
  public int max_size {
    get {
      return this._max_size;
    }
    set {
      this._max_size = value;
      this.queue_resize ();
    }
  }

  public override void add (Gtk.Widget widget) {
    base.add (widget);
    if (this.event_window != null)
      widget.set_parent_window (this.event_window);
  }

  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void get_preferred_height_for_width (int width,
                                                       out int min_height,
                                                       out int nat_height) {
    int child_height;
    get_child ().get_preferred_height_for_width (width, out child_height, null);


    if (max_size >= child_height) {
      base.get_preferred_height_for_width (width, out min_height, out nat_height);
    } else {
      nat_height = max_size;
      min_height = max_size;
    }
  }

  public override void size_allocate (Gtk.Allocation alloc) {
    if (get_child () == null || !get_child ().visible) {
      if (this.event_window != null)
        event_window.move_resize (alloc.x, alloc.y, alloc.width, alloc.height);

      this.set_allocation (alloc);
      return;
    }

    Gtk.Allocation child_alloc = {};
    child_alloc.x = alloc.x;
    child_alloc.width = alloc.width;

    if (max_size >= alloc.height) {
      // We don't cut away anything
      child_alloc.y = alloc.y;
      child_alloc.height = alloc.height;
    } else {
      child_alloc.y = alloc.y;// - (max_size - alloc.height);
      child_alloc.height = max_size;
    }

    if (this.event_window != null)
      this.event_window.move_resize (child_alloc.x, child_alloc.y,
                                     child_alloc.width, child_alloc.height);

    this.set_allocation (child_alloc);
    if (get_child () != null && get_child ().visible) {
      int min_height, nat_height;
      get_child ().get_preferred_height (out min_height, out nat_height);
      child_alloc.height = int.max(child_alloc.height, min_height);

      get_child ().size_allocate (child_alloc);
      if (this.get_realized ())
        get_child ().show ();
    }
  }

  public override void realize () {
    base.realize ();
    Gtk.Allocation alloc;
    this.get_allocation (out alloc);

    Gdk.WindowAttr attr = {};
    attr.x = alloc.x;
    attr.y = alloc.y;
    attr.width = alloc.width;
    attr.height = alloc.height;
    attr.window_type = Gdk.WindowType.CHILD;
    attr.visual = this.get_visual ();
    attr.wclass = Gdk.WindowWindowClass.INPUT_OUTPUT;
    attr.event_mask = this.get_events ();

    Gdk.WindowAttributesType attr_mask = Gdk.WindowAttributesType.X |
                                         Gdk.WindowAttributesType.Y;
    Gdk.Window window = this.get_parent_window ();
    this.set_window (window);
    window.ref ();

    this.event_window = new Gdk.Window (window, attr, attr_mask);
    this.register_window (this.event_window);

    if (this.get_child () != null)
      this.get_child ().set_parent_window (this.event_window);
  }

  public override void unrealize () {
    if (this.event_window != null) {
      this.unregister_window (this.event_window);
      this.event_window.destroy ();
      this.event_window = null;
    }

    base.unrealize ();
  }

  public override void map () {
    base.map ();
    if (this.event_window != null)
      this.event_window.show ();
  }

  public override void unmap () {
    if (this.event_window != null)
      this.event_window.hide ();

    base.unmap ();
  }
}
