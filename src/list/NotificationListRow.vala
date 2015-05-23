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

[GtkTemplate (ui = "/org/baedert/corebird/ui/notification-list-row.ui")]
class NotificationListRow : Gtk.ListBoxRow {
  [GtkChild]
  private Gtk.Label heading_label;
  [GtkChild]
  private Gtk.Label body_label;

  public NotificationListRow (NotificationItem item) {
    set_values (item);
    item.changed.connect (set_values);
  }

  construct {
    this.activatable = false;
  }

  private void set_values (GLib.Object obj) {
    var item = (NotificationItem) obj;

    heading_label.label = item.heading;
    body_label.label = item.body;
  }

  [GtkCallback]
  private bool activate_link_cb (string uri) {
    var window = (MainWindow) this.get_toplevel ();

    return TweetUtils.activate_link (uri, window);
  }
}
