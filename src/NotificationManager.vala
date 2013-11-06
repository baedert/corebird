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

using Notify;


class NotificationManager {

  public static void init() {
    Notify.init("Corebird");
  }


  public static void notify (string summary, string body = "",
                             Urgency urgency = Urgency.NORMAL,
                             Gdk.Pixbuf? icon = null, string? image = null) {
    var n = new Notify.Notification (summary, body, null);
    n.set_urgency (urgency);

    if (icon != null)
      n.set_icon_from_pixbuf (icon);

    if (image != null)
      n.set_hint("image-path", new GLib.Variant.string (image));

    try {
      n.show ();
    } catch (GLib.Error e) {
      warning ("Error while showing notificaiton: %s", e.message);
    }
  }


  /**
   * Uninitializes the notification manager
   * Should be called when the application gets closed completely.
   */
  public static void uninit() {
    Notify.uninit();
  }

}
