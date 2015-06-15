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


class AspectImage : Gtk.Widget {
  private Gdk.Pixbuf _pixbuf;
  public Gdk.Pixbuf pixbuf  {
    set {
      _pixbuf = value;
      this.queue_draw ();
      this.queue_resize ();
    }
    get {
      return _pixbuf;
    }
  }
  private double _scale = 1.0;
  public double scale {
    get {
      return this._scale;
    }
    set {
      this._scale = value;
      this.queue_resize ();
    }
  }


  public AspectImage () {}

  construct {
    set_has_window (false);
  }

  public override void get_preferred_height_for_width (int width,
                                                       out int min_height,
                                                       out int nat_height) {
    if (pixbuf == null) {
      min_height = 0;
      nat_height = 1;
      return;
    }

    double scale_x = width  / (double)pixbuf.get_width ();
    if (scale_x > 1)
      scale_x = 1;
    double final_height = scale_x * pixbuf.get_height ();

    min_height = (int)(final_height * _scale);
    nat_height = (int)(final_height * _scale);
  }


  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override bool draw (Cairo.Context ct) {
    if (pixbuf == null)
      return false;


    int width = get_allocated_width ();
    int height = get_allocated_height ();
    double scale_x = width  / (double)pixbuf.get_width ();
    double scale_y = scale_x;
    int y = 0;

    /* Never scale it vertically down, instead move it up */
    if (scale_y > 1) {
      scale_y = 1;
    }

    int view_height = (int)(pixbuf.get_height () * scale_y);
    y = height - view_height;


    ct.rectangle (0, 0, width, view_height);
    ct.scale (scale_x, scale_y);
    Gdk.cairo_set_source_pixbuf (ct, pixbuf, 0, 0);
    ct.fill ();
    return false;
  }
}
