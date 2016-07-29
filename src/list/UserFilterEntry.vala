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

[GtkTemplate (ui = "/org/baedert/corebird/ui/user-filter-entry.ui")]
class UserFilterEntry : Gtk.ListBoxRow, ITwitterItem {
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Stack stack;
  [GtkChild]
  private Gtk.Box delete_box;
  [GtkChild]
  private Gtk.Grid grid;
  [GtkChild]
  private Gtk.Revealer revealer;

  public new string name {
    set { name_label.label = value; }
  }

  public string screen_name {
    set { screen_name_label.label = "@" + value; }
  }

  public string avatar_url {
    set { real_set_avatar (value); }
  }

  public bool seen {
    get { return true; }
    set {}
  }

  public int64 sort_factor {
    get{ return 2; }
  }

  public int64 user_id;

  public signal void deleted (int64 id);

  public bool muted = false;
  public bool blocked = false;

  private void real_set_avatar (string avatar_url) {
    avatar_image.surface = Twitter.get ().get_avatar (user_id, avatar_url, (a) => {
      avatar_image.surface = a;
    }, 48 * this.get_scale_factor ());
  }

  public int update_time_delta (GLib.DateTime? now = null) {return 0;}

  [GtkCallback]
  private void menu_button_clicked_cb () {
    stack.visible_child = delete_box;
  }

  [GtkCallback]
  private void cancel_button_clicked_cb () {
    stack.visible_child = grid;
  }

  [GtkCallback]
  private void delete_button_clicked_cb () {
    revealer.reveal_child = false;
    revealer.notify["child-revealed"].connect (() => {
      deleted (user_id);
    });
  }
}
