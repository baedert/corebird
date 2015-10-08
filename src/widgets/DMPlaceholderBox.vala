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

[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-placeholder-box.ui")]
class DMPlaceholderBox : Gtk.Box {
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
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
    avatar_image.surface = Twitter.get ().get_avatar (user_id, avatar_url, (a) => {
      avatar_image.surface = a;
    });
  }

}
