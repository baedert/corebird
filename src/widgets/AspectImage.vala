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

/*  public override void get_preferred_height (out int min_height,
                                             out int nat_height) {
    if (pixbuf == null) {
      min_height = 0;
      nat_height = 1;
      return;
    }
    min_height = (int)(pixbuf.get_height () * scale);
    nat_height = (int)(pixbuf.get_height () * scale);
  }*/

/*  public override void get_preferred_width_for_height (int height,
                                                       out int min_width,
                                                       out int nat_width) {
    if (pixbuf == null) {
      min_width = 0;
      nat_width = 1;
      return;
    }
    double ratio = pixbuf.get_height () / (double)pixbuf.get_width ();
    min_width = 1;
    nat_width = (int)(height / ratio);
    if (nat_width == 0)
      nat_width = 1;
    min_width = nat_width;
  }*/


  public override void get_preferred_height_for_width (int width,
                                                       out int min_height,
                                                       out int nat_height) {
    if (pixbuf == null) {
      min_height = 0;
      nat_height = 1;
      return;
    }

    min_height = (int)(pixbuf.get_height () * _scale);
    nat_height = (int)(pixbuf.get_height () * _scale);
  }


  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override bool draw (Cairo.Context ct) {
    if (pixbuf == null) {
      return true;
    }
    int width = get_allocated_width ();
    int height = get_allocated_height ();
    double scale_x = width  / (double)pixbuf.get_width ();
    double scale_y = height / (double)pixbuf.get_height ();
    int x = 0;
    int y = 0;


    if (scale_x < 1) {
      scale_x = 1;
      x = (width - pixbuf.get_width ()) / 2;
    }

    if (scale_y < 1) {
      scale_y = 1;
      y = height - pixbuf.get_height ();
    }

    ct.scale (scale_x, scale_y);
    Gdk.cairo_set_source_pixbuf (ct, pixbuf, x, y);
    ct.rectangle (0, 0, width, pixbuf.get_height ());
    ct.fill ();
    return false;
  }
}
