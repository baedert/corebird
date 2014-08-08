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

[GtkTemplate (ui = "/org/baedert/corebird/ui/user-list-entry.ui")]
class UserListEntry : Gtk.ListBoxRow, ITwitterItem {
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Button settings_button;

  public new string name {
    set { name_label.label = value; }
  }

  public string screen_name {
    set { screen_name_label.label = value; }
    owned get {
      return screen_name_label.label.substring (1);
    }
  }

  public string avatar {
    set { real_set_avatar (value); }
  }

  public Gdk.Pixbuf avatar_pixbuf {
    set { avatar_image.pixbuf = value; }
  }

  public bool seen {
    get { return true; }
    set {}
  }

  public int64 sort_factor {
    get{ return int64.MAX-1; }
  }

  public bool show_settings_button {
    set {
      settings_button.visible = value;
    }
  }

  public int64 user_id { get; set; }

  public signal void settings_clicked ();

  private unowned Account account;

  public UserListEntry.from_account (Account acc) {
    this.screen_name = "@" + acc.screen_name;
    this.name = acc.name;
    this.avatar_pixbuf = acc.avatar;
    this.account = acc;
    acc.info_changed.connect ((screen_name, name, avatar) => {
      this.screen_name = screen_name;
      this.name = name;
      this.avatar_pixbuf = avatar;
    });
  }

  private void real_set_avatar (string avatar_url) {
    avatar_image.pixbuf = Twitter.get ().get_avatar (avatar_url, (a) => {
      avatar_image.pixbuf = a;
    });
  }

  public int update_time_delta (GLib.DateTime? now = null) {return 0;}

  [GtkCallback]
  private void settings_button_clicked_cb () {
    settings_clicked ();
    var active_window = ((Gtk.Application)GLib.Application.get_default ()).active_window;
    var dialog = new AccountDialog (this.account);
    dialog.set_transient_for (active_window);
    dialog.modal = true;
    dialog.show_all ();
  }
}
