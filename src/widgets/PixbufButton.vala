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

class PixbufButton : Gtk.Button {
  private Cairo.ImageSurface bg;
  private bool _round = false;
  public bool round {
    get {
      return _round;
    }
    set {
      if (value) {
        this.get_style_context ().add_class ("pixbuf-button-round");
      } else {
        this.get_style_context ().remove_class ("pixbuf-button-round");
      }
      _round = value;
    }
  }

  construct {
    get_style_context ().add_class ("pixbuf-button");
  }

  public PixbufButton () {}

  public override void snapshot (Gtk.Snapshot snapshot) {
    int widget_width = this.get_width ();
    int widget_height = this.get_height ();

    Graphene.Rect bounds = {};
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    bounds.size.width = widget_width;
    bounds.size.height = widget_height;

    var ct = snapshot.append_cairo (bounds, "pixbuf button");

    var sc = this.get_style_context ();


    if (bg != null) {

      var surface = new Cairo.Surface.similar (ct.get_target (),
                                               Cairo.Content.COLOR_ALPHA,
                                               widget_width, widget_height);
      var ctx = new Cairo.Context (surface);

      ctx.rectangle (0, 0, widget_width, widget_height);

      double scale_x = (double)widget_width / bg.get_width ();
      double scale_y = (double)widget_height / bg.get_height ();
      ctx.save ();
      ctx.scale (scale_x, scale_y);
      ctx.set_source_surface (bg, 0, 0);
      ctx.fill ();
      ctx.restore ();



      if (_round) {
        // make it round
        ctx.set_operator (Cairo.Operator.DEST_IN);
        ctx.translate (widget_width / 2, widget_height / 2);
        ctx.arc (0, 0, widget_width / 2, 0, 2 * Math.PI);
        ctx.fill ();

        // draw outline
        sc.render_frame (ct, 0, 0, widget_width, widget_height);
      }

      ct.rectangle (0, 0, widget_width, widget_height);
      ct.set_source_surface (surface, 0, 0);
      ct.fill ();
    }
  }

  public void set_bg (Cairo.ImageSurface bg) {
    this.bg = bg;
    this.set_size_request (bg.get_width(), bg.get_height());
    this.queue_draw ();
  }

  public void set_pixbuf (Gdk.Pixbuf pixbuf) {
    this.bg = (Cairo.ImageSurface)Gdk.cairo_surface_create_from_pixbuf (pixbuf, 1, null);
    this.queue_draw ();
  }
}
