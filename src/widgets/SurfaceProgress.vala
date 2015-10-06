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

class SurfaceProgress : Gtk.Widget {
  private Cairo.ImageSurface? _surface = null;
  public Cairo.ImageSurface? surface {
    get {
      return this._surface;
    }
    set {
      this._surface = value;
      this.queue_resize ();
    }
  }
  private double _progress = 0.0;
  public double progress {
    get {
      return this._progress;
    }
    set {
      if (value > 1.0)
        this._progress = 1.0;
      else if (value < 0.0)
        this._progress = 0.0;
      else
        this._progress = value;

      this.queue_draw ();
    }
  }


  construct {
    this.set_has_window (false);
  }

  public override bool draw (Cairo.Context ct) {
    if (this.surface == null)
      return Gdk.EVENT_PROPAGATE;

    int width = this.get_allocated_width ();
    int height = this.get_allocated_height ();

    var tmp_surface = new Cairo.Surface.similar (ct.get_target (),
                                                 Cairo.Content.COLOR_ALPHA,
                                                 width, height);

    var ctx = new Cairo.Context (tmp_surface);

    /* Draw the surface slightly translucent on the widget's surface */
    ct.rectangle (0, 0, width, height);
    ct.set_source_surface (this._surface, 0, 0);
    ct.paint_with_alpha (0.5);


    /* Draw this._surface on tmp surface */
    ctx.rectangle (0, 0, width, height);
    ctx.set_source_surface (this._surface, 0, 0);
    ctx.fill();



    int arc_size = width > height ? width : height;
    arc_size *= 2;

    double cx = width  / 2.0;
    double cy = height / 2.0;
    double radius = (arc_size / 2.0) - 0.5;

    ctx.set_operator (Cairo.Operator.DEST_IN);

    ctx.set_source_rgba (1.0, 0.0, 0.0,1.0);
    ctx.move_to (width / 2.0, height / 2.0);
    ctx.arc (cx, cy, radius, 0, 0);

    ctx.arc (cx, cy,
             radius,
             0,                             /* Angle from */
             2 * Math.PI * this._progress); /* Angle to */
    ctx.move_to (cx, cy);
    //ctx.stroke ();
    ctx.fill ();

    ct.rectangle (0, 0, width, height);
    ct.set_source_surface (tmp_surface, 0, 0);
    ct.fill ();

    return Gdk.EVENT_PROPAGATE;
  }

  public override void get_preferred_width (out int min,
                                            out int nat) {
    if (this.surface == null) {
      min = 0;
      nat = 0;
      return;
    }

    min = nat = this.surface.get_width ();
  }

  public override void get_preferred_height (out int min,
                                             out int nat) {
    if (this.surface == null) {
      min = 0;
      nat = 0;
      return;
    }

    min = nat = this.surface.get_height ();
  }
}
