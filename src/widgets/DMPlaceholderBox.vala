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

class DMPlaceholderBox : Gtk.Box {
  private AvatarWidget avatar_image;
  private Gtk.Label name_label;
  private Gtk.Label screen_name_label;

  public int64 user_id;

  public new string name {
    set {
      name_label.label = value;
    }
  }

  public string screen_name {
    set {
      screen_name_label.label = "@" + value;
    }
  }

  public string avatar_url;

  public void load_avatar () {
    Twitter.get ().get_avatar.begin (user_id, avatar_url, avatar_image);
  }

  construct {
    this.set_opacity (0.8);
    this.set_margin_top (60);
    this.set_orientation (Gtk.Orientation.VERTICAL);
    this.set_spacing (4);
    this.avatar_image = new AvatarWidget ();
    avatar_image.size = 48;
    avatar_image.set_halign (Gtk.Align.CENTER);
    this.add (avatar_image);

    this.name_label = new Gtk.Label ("");
    var attrs = new Pango.AttrList ();
    attrs.insert (Pango.attr_weight_new (Pango.Weight.BOLD));
    name_label.set_attributes (attrs);
    this.add (name_label);

    this.screen_name_label = new Gtk.Label ("");
    screen_name_label.get_style_context ().add_class ("dim-label");
    this.add (screen_name_label);
  }
}
