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

namespace NotificationManager {
  public void notify (Account acc,
                      string  summary,
                      string  body = "",
                      string? icon = null) {

    var n = new GLib.Notification (summary);
    n.set_body (body);
    if (icon != null) {
      try {
        var gicon = GLib.Icon.new_for_string (icon);
        n.set_icon (gicon);
      } catch (GLib.Error e) {
        warning (e.message);
      }
    }
    /* Default action: just bring the appropriate window
       to front */
    n.set_default_action_and_target_value ("app.show-window", acc.id);
    GLib.Application.get_default ().send_notification (null, n);
  }

  public void withdraw (string notification_id) {
    GLib.Application.get_default ().withdraw_notification (notification_id);
  }
}
