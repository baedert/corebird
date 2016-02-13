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

[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-list-entry.ui")]
class DMListEntry : Gtk.ListBoxRow, ITwitterItem {
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Label text_label;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private TextButton name_button;
  [GtkChild]
  private Gtk.Label time_delta_label;

  public string text {
    set { text_label.label = value; }
  }
  public string screen_name {
    set { screen_name_label.label = "@" + value; }
  }
  public new string name {
    set { name_button.label = value; }
  }

  public Cairo.Surface avatar {
    set { avatar_image.surface = value; }
  }

  public bool seen {
    get { return true; }
    set {}
  }

  public int64 sort_factor {
    get { return timestamp; }
  }

  public int64 timestamp;
  public int64 id;
  public int64 user_id;
  public unowned MainWindow main_window;

  public DMListEntry () {
    name_button.clicked.connect (() => {
      var bundle = new Bundle ();
      bundle.put_int64 ("user_id", user_id);
      bundle.put_string ("screen_name", screen_name_label.label.substring (1));
      main_window.main_widget.switch_page (Page.PROFILE, bundle);
    });
  }

  public void load_avatar (string avatar_url) {
    string url = avatar_url;
    if (this.get_scale_factor () == 2)
      url = url.replace ("_normal", "_bigger");

    avatar_image.surface = Twitter.get ().get_avatar (user_id, url, (a) => {
      avatar_image.surface = a;
    }, 48 * this.get_scale_factor ());
  }

  public int update_time_delta (GLib.DateTime? now = null) {
    GLib.DateTime cur_time;
    if (now == null)
      cur_time = new GLib.DateTime.now_local ();
    else
      cur_time = now;

    GLib.DateTime then = new GLib.DateTime.from_unix_local (timestamp);
    time_delta_label.label = Utils.get_time_delta (then, cur_time);
    return (int)(cur_time.difference (then) / 1000.0 / 1000.0);
  }
}


