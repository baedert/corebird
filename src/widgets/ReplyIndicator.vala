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

public class ReplyIndicator : Gtk.Widget {
  private static const int HEIGHT = 3;
  private bool replies = false;
  public bool replies_available {
    set {
      this.replies = value;
      this.queue_draw ();
    }
  }

  construct {
    set_has_window (false);
    get_style_context ().add_class ("reply-indicator");
  }

  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }


  public override void get_preferred_height_for_width (int     width,
                                                       out int min_height,
                                                       out int nat_height) {
    min_height = HEIGHT;
    nat_height = HEIGHT;
  }

  public override bool draw (Cairo.Context ct) {
    if (!replies) {
      return false;
    }
    var style_context = this.get_style_context ();
    int width = this.get_allocated_width ();

    style_context.render_background (ct, 0, 0, width, HEIGHT);

    return false;
  }
}
