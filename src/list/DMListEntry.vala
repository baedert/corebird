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

using Gtk;

[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-list-entry.ui")]
class DMListEntry : Gtk.ListBoxRow {
  [GtkChild]
  private Gtk.Image avatar_image;
  [GtkChild]
  private Gtk.Label text_label;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private Gtk.Label name_label;

  public string text {
    set { text_label.label = value; }
  }
  public string screen_name {
    set { screen_name_label.label = "@" + value; }
  }
  public new string name {
    set { name_label.label = value; }
  }

  public Gdk.Pixbuf avatar {
    set { avatar_image.pixbuf = value; }
  }

  public string avatar_url;

  public int64 id;

  public DMListEntry () {

  }

  public void load_avatar () {
    Gdk.Pixbuf avatar = TweetUtils.load_avatar (avatar_url);
    if (avatar == null) {
      TweetUtils.download_avatar.begin (avatar_url, (obj, res) => {
        avatar = TweetUtils.download_avatar.end (res);
        TweetUtils.load_avatar (avatar_url, avatar);
        avatar_image.pixbuf = avatar;
      });
    } else
      avatar_image.pixbuf = avatar;

  }
}


