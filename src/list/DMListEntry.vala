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

class DMListEntry : Gtk.ListBoxRow, Cb.TwitterItem {
  private AvatarWidget avatar_image;
  private Gtk.Label text_label;
  private Gtk.Label screen_name_label;
  private Gtk.Button name_button;
  private Gtk.Label time_delta_label;

  public string text {
    set { text_label.label = value; }
  }
  public string screen_name {
    set { screen_name_label.label = "@" + value; }
  }
  public new string name {
    set { ((Gtk.Label)name_button.get_child ()).set_label (value.replace ("&", "&amp;")); }
  }

  public Gdk.Texture avatar {
    set { avatar_image.texture = value; }
  }

  public bool seen {
    get { return true; }
    set {}
  }

  private GLib.TimeSpan last_timediff;
  public int64 timestamp;
  public int64 id;
  public int64 user_id;
  public unowned MainWindow main_window;

  public DMListEntry () {
    this.set_activatable (false);
    this.get_style_context ().add_class ("dm");

    var grid = new Gtk.Grid ();

    this.avatar_image = new AvatarWidget ();
    avatar_image.size = 48;
    avatar_image.set_valign (Gtk.Align.START);
    grid.attach (avatar_image, 0, 0, 1, 2);

    this.name_button = new Gtk.Button ();
    var name_label = new Gtk.Label (null);
    name_label.set_use_markup (true);
    name_label.set_ellipsize (Pango.EllipsizeMode.END);
    name_label.xalign = 0;
    name_button.set_valign (Gtk.Align.BASELINE);
    name_button.get_style_context ().add_class ("user-name");
    name_button.add (name_label);
    grid.attach (name_button, 1, 0, 1, 1);

    this.screen_name_label = new Gtk.Label (null);
    screen_name_label.set_valign (Gtk.Align.BASELINE);
    screen_name_label.get_style_context ().add_class ("dim-label");
    grid.attach (screen_name_label, 2, 0, 1, 1);

    this.time_delta_label = new Gtk.Label (null);
    time_delta_label.set_halign (Gtk.Align.END);
    time_delta_label.set_valign (Gtk.Align.BASELINE);
    time_delta_label.set_hexpand (true);
    time_delta_label.get_style_context ().add_class ("dim-label");
    time_delta_label.get_style_context ().add_class ("time-delta");
    grid.attach (time_delta_label, 3, 0, 1, 1);

    this.text_label = new Gtk.Label (null);
    text_label.get_style_context ().add_class ("text");
    text_label.set_hexpand (true);
    text_label.set_vexpand (true);
    text_label.set_xalign (0.0f);
    text_label.set_line_wrap (true);
    text_label.set_line_wrap_mode (Pango.WrapMode.WORD_CHAR);
    text_label.set_use_markup (true);
    text_label.set_selectable (true);
    text_label.set_valign (Gtk.Align.START);
    grid.attach (text_label, 1, 1, 3, 1);

    name_button.clicked.connect (() => {
      var bundle = new Cb.Bundle ();
      bundle.put_int64 (ProfilePage.KEY_USER_ID, user_id);
      bundle.put_string (ProfilePage.KEY_SCREEN_NAME, screen_name_label.label.substring (1));
      main_window.main_widget.switch_page (Page.PROFILE, bundle);
    });

    this.add (grid);
  }

  public void load_avatar (string avatar_url) {
    string url = avatar_url;
    if (this.get_scale_factor () == 2)
      url = url.replace ("_normal", "_bigger");

    Twitter.get ().get_avatar.begin (user_id, url, avatar_image, 48 * this.get_scale_factor ());
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

  public int64 get_sort_factor () {
    return timestamp;
  }

  public int64 get_timestamp () {
    return timestamp;
  }

  public GLib.TimeSpan get_last_set_timediff () {
    return this.last_timediff;
  }

  public void set_last_set_timediff (GLib.TimeSpan span) {
    this.last_timediff = span;
  }
}


