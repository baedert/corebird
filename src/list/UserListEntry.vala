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
class UserListEntry : Gtk.ListBoxRow, Cb.TwitterItem {
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Button settings_button;
  [GtkChild]
  private Gtk.Button new_window_button;
  [GtkChild]
  private Gtk.Button profile_button;

  public new string name {
    set { name_label.label = value; }
  }

  public string screen_name {
    owned get {
      return screen_name_label.label.substring (1);
    }
  }
  public void set_screen_name (string sn) {
    screen_name_label.label = sn;
  }

  public string avatar_url {
    set { real_set_avatar (value); }
  }

  public Cairo.Surface avatar_surface {
    set { avatar_image.surface = value; }
  }

  public bool verified {
    set {
      this.avatar_image.verified = value;
    }
  }

  public bool seen {
    get { return true; }
    set {}
  }

  public bool show_settings {
    set {
      settings_button.visible = value;
      new_window_button.visible = value;
      profile_button.visible = value;
    }
  }

  public int64 user_id { get; set; }
  private GLib.TimeSpan last_timediff;

  public signal void action_clicked ();


  private unowned Account account;

  public UserListEntry.from_account (Account acc) {
    this.screen_name_label.label = "@" + acc.screen_name;
    this.name = acc.name;
    this.avatar_surface = acc.avatar;
    this.account = acc;
    this.user_id = acc.id;
    acc.info_changed.connect ((screen_name, name, nop, avatar) => {
      this.screen_name_label.label = "@" + acc.screen_name;
      this.name = name;
      this.avatar_surface = avatar;
    });
    acc.notify["avatar"].connect (() => {
      this.avatar_surface = this.account.avatar;
    });
    var cb = (Corebird) GLib.Application.get_default ();
    cb.window_added.connect ((window) => {
      if (window is MainWindow) {
        update_window_button_sensitivity (window, false);
      }
    });

    cb.window_removed.connect ((window) => {
      if (window is MainWindow) {
        update_window_button_sensitivity (window, true);
      }
    });

    cb.account_window_changed.connect ((old_id, new_id) => {
      if (old_id == this.user_id)
        new_window_button.sensitive = true;
      else if (new_id == this.user_id)
        new_window_button.sensitive = false;
    });

    // Set initial sensitivitiy of new_window_button
    new_window_button.sensitive = !(cb.is_window_open_for_user_id (acc.id));
  }

  private void real_set_avatar (string avatar_url) {
    Twitter.get ().get_avatar.begin (user_id, avatar_url, avatar_image, 48 * this.get_scale_factor ());
  }

  public int update_time_delta (GLib.DateTime? now = null) {return 0;}

  public int64 get_sort_factor () {
    return int64.MAX - 1;
  }

  public int64 get_timestamp () {
    return 0;
  }

  public GLib.TimeSpan get_last_set_timediff () {
    return this.last_timediff;
  }

  public void set_last_set_timediff (GLib.TimeSpan span) {
    this.last_timediff = span;
  }

  private void update_window_button_sensitivity (Gtk.Window window, bool new_value) {
    if (((MainWindow)window).account.screen_name == this.account.screen_name) {
      new_window_button.sensitive = new_value;
    }
  }

  [GtkCallback]
  private void settings_button_clicked_cb () {
    action_clicked ();
    var active_window = ((Gtk.Application)GLib.Application.get_default ()).active_window;
    var dialog = new AccountDialog (this.account);
    dialog.set_transient_for (active_window);
    dialog.modal = true;
    dialog.show ();
  }

  [GtkCallback]
  private void new_window_button_clicked_cb () {
    var cb = (Corebird) GLib.Application.get_default ();
    var window = new MainWindow (cb, this.account);
    cb.add_window (window);
    window.show ();
    action_clicked ();
  }

  [GtkCallback]
  private void profile_button_clicked_cb () {
    action_clicked ();
    var active_window = ((Gtk.Application)GLib.Application.get_default ()).active_window;
    if (active_window is MainWindow) {
      var mw = (MainWindow) active_window;
      var bundle = new Cb.Bundle ();
      bundle.put_int64 (ProfilePage.KEY_USER_ID, this.user_id);
      bundle.put_string (ProfilePage.KEY_SCREEN_NAME, this.screen_name);
      mw.main_widget.switch_page (Page.PROFILE, bundle);
    }
  }
}
