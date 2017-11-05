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
                                out int         minimum,
                                out int         natural,
                                out int         minimum_baseline,
                                out int         natural_baseline) {

    if (orientation == Gtk.Orientation.HORIZONTAL) {
      base.measure (orientation, for_size,
                    out minimum, out natural,
                    out minimum_baseline, out natural_baseline);
    } else {
      int min_child_height;
      int nat_child_height;
      get_child ().measure (Gtk.Orientation.VERTICAL,
                            for_size,
                            out min_child_height,
                            out nat_child_height,
                            null, null);

      if (max_size >= min_child_height) {
        minimum = min_child_height;
        natural = nat_child_height;
      } else {
        minimum = max_size;
        natural = max_size;
      }
    }

    minimum_baseline = -1;
    natural_baseline = -1;
  }

  public override void size_allocate (Gtk.Allocation alloc, int baseline, out Gtk.Allocation out_clip) {
    if (get_child () == null || !get_child ().visible) {
      out_clip = alloc;
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
      int min_height, nat_height;
      get_child ().measure (Gtk.Orientation.VERTICAL, alloc.width, out min_height, out nat_height, null, null);
      child_alloc.height = int.max (child_alloc.height, min_height);

      get_child ().size_allocate (child_alloc, -1, out out_clip);
    }

    out_clip = alloc;
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    Graphene.Rect clip_bounds = {};
    clip_bounds.init (0, 0, this.get_width (), this.get_height ());

    snapshot.push_clip (clip_bounds, "MaxSizeContainer clip");
    base.snapshot (snapshot);
    snapshot.pop ();
  }
}
