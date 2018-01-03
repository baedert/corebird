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
  private Gdk.Texture bg;
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
    if (this.bg == null) {
      return;
    }

    int widget_width = this.get_width ();
    int widget_height = this.get_height ();

    Graphene.Rect bounds = {};
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    bounds.size.width = widget_width;
    bounds.size.height = widget_height;

    if (_round) {
      Gsk.RoundedRect round_clip = {};
      round_clip.init_from_rect (bounds, widget_width); // radius = width => round.
      snapshot.push_rounded_clip (round_clip, "Avatar clip");
    }

    snapshot.append_texture (this.bg, bounds, "Avatar Image");

    if (_round) {
      snapshot.pop ();
    }
  }

  public void set_bg (Gdk.Texture texture) {
    this.bg = texture;
    this.queue_draw ();
  }
}
