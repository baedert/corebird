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
class AvatarWidget : Gtk.Image {
  private bool _round = true;
  public bool make_round {
    get {
      return _round;
    }
    set {
      this._round = value;
      this.queue_draw ();
    }
  }

  construct {
    Settings.get ().bind ("round-avatars", this, "make_round",
                          GLib.SettingsBindFlags.DEFAULT);
  }


  public override bool draw (Cairo.Context ctx) {
    if (this.pixbuf == null) {
      return false;
    }

    int width = this.get_allocated_width ();
    int height = this.get_allocated_height ();
    if (width != height) {
      warning ("Avatar with mapped with width %d and height %d", width, height);
    }

    var surface = new Cairo.Surface.similar (ctx.get_target (),
                                             Cairo.Content.COLOR_ALPHA,
                                             width, height);
    var ct = new Cairo.Context (surface);

    ct.rectangle (0, 0, width, height);
    Gdk.cairo_set_source_pixbuf (ct, this.pixbuf, 0, 0);
    ct.fill();

    if (_round) {
      // make it round
      ct.set_operator (Cairo.Operator.DEST_IN);
      ct.translate (width / 2, height / 2);
      ct.arc (0, 0, width / 2, 0, 2 * Math.PI);
      ct.fill ();

      // draw outline
      ct.set_operator (Cairo.Operator.OVER);
      ct.arc (0, 0, (width /2) - 1, 0, 2 * Math.PI);
      ct.set_line_width (1.0);
      ct.set_source_rgba (0.4, 0.4, 0.4, 1);
      ct.stroke ();
    }

    ctx.rectangle (0, 0, width, height);
    ctx.set_source_surface (surface, 0, 0);
    ctx.fill ();


    return false;
  }

}


