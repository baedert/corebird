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

  public override void measure (Gtk.Orientation orientation,
                                int             for_size,
                                out int         min,
                                out int         nat,
                                out int         min_baseline = null,
                                out int         nat_baseline = null) {
    int min_child, nat_child;
    get_child ().measure (orientation, for_size, out min_child, out nat_child, null, null);

    if (orientation == Gtk.Orientation.HORIZONTAL) {
      min = min_child;
      nat = nat_child;
    } else {
      if (max_size >= min_child) {
        min = min_child;
        nat = nat_child;
      } else {
        min = max_size;
        nat = max_size;
      }
    }

    min_baseline = -1;
    nat_baseline = -1;
  }

  public override void size_allocate (Gtk.Allocation alloc) {
    if (get_child () == null || !get_child ().visible) {
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

    if (get_child () != null && get_child ().visible) {
      int min_height;
      get_child ().measure (Gtk.Orientation.VERTICAL, alloc.width, out min_height, null,
                             null, null);
      child_alloc.height = int.max (child_alloc.height, min_height);

      get_child ().size_allocate (child_alloc);
    }
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    Graphene.Rect clip_bounds = {};
    clip_bounds.init (0, 0, this.get_allocated_width (), this.get_allocated_height ());

    snapshot.push_clip (clip_bounds, "MaxSizeContainer clip");
    base.snapshot (snapshot);
    snapshot.pop ();
  }
}
