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

public class NotificationManager : GLib.Object {
  private unowned Account account;

  public NotificationManager (Account account) {
    this.account = account;
  }

  public void withdraw (string id) {
    GLib.Application.get_default ().withdraw_notification (id);
  }

  public string send (string summary, string body, string? id_suffix = null) {
    var n = new GLib.Notification (summary);
    n.set_body (body);

    string id = "%s-%s".printf (account.id.to_string (), id_suffix ?? "");

    /* Default action: Bring the account window to the front */
    n.set_default_action_and_target_value ("app.show-window", account.id);

    GLib.Application.get_default ().send_notification (id, n);

    return id;
  }

  public string send_dm (int64   sender_id,
                         string? existing_id,
                         string  summary,
                         string  text) {
    if (existing_id != null) {
      this.withdraw (existing_id);
    }

    string new_id = "new-dm-%s".printf (sender_id.to_string ());

    var n = new GLib.Notification (summary);
    var value = new GLib.Variant.tuple ({new GLib.Variant.int64 (account.id),
                                         new GLib.Variant.int64 (sender_id)});
    n.set_default_action_and_target_value ("app.show-dm-thread", value);
    n.set_body (text);

    GLib.Application.get_default ().send_notification (new_id, n);

    return new_id;
  }
}
