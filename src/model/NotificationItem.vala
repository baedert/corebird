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

class NotificationItem : GLib.Object {
  public static int TYPE_RETWEET  = 1;
  public static int TYPE_FAVORITE = 2;
  public static int TYPE_FOLLOW   = 3;

  public signal void changed ();

  public int64 id;
  public int type = -1;
  public string heading;
  public string body;
}



void append_link (StringBuilder sb, string text) {
  sb.append ("<span underline='none'><a href='foo'>")
    .append (text)
    .append ("</a></span>");
}

string _build_heading (Gee.ArrayList<string> screen_names,
                       string                sentinel) {
    var sb = new StringBuilder ();

    if (screen_names.size == 1) {
      append_link (sb, screen_names.get (0));
    } else if (screen_names.size <= 3) {
      append_link (sb, screen_names.get (0));
      if (screen_names.size == 3) {
        sb.append (", ");
        append_link (sb, screen_names.get (1));
      }

      sb.append (" and ");
      append_link (sb, screen_names.get (screen_names.size - 1));

    } else {
      // screen_names.size > 3
      int l = screen_names.size;
      append_link (sb, screen_names.get (l - 1));
      sb.append (", ");
      append_link (sb, screen_names.get (l - 2));
      sb.append (" and ")
        .append ((screen_names.size - 2).to_string ())
        .append (" others");
    }

    sb.append (" ").append (sentinel);

    return sb.str;
}

class MultipleUserNotificationItem : NotificationItem {
  public Gee.ArrayList<string> screen_names = new Gee.ArrayList<string> ();
  private string sentinel;

  public MultipleUserNotificationItem (string sentinel) {
    this.sentinel = sentinel;
  }

  public void build_heading () {
    this.heading = _build_heading (this.screen_names,
                                   sentinel);
    this.changed ();
  }
}
