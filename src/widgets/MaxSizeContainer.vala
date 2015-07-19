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
    if (get_child () == null || !get_child ().visible)
      return;


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


    base.size_allocate (child_alloc);
    if (get_child () != null && get_child ().visible) {
      get_child ().size_allocate (child_alloc);
      if (this.get_realized ())
        get_child ().show ();
    }

    if (this.get_realized ()) {
      if (get_child () != null)
        get_child ().set_child_visible (true);
    }
  }
}
