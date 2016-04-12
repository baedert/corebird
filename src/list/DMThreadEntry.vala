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

[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-thread-entry.ui")]
class DMThreadEntry : Gtk.ListBoxRow {
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private Gtk.Label last_message_label;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Label unread_count_label;
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
  public string last_message {
    set {
      last_message_label.label = value;
    }
  }
  public Cairo.Surface? avatar {
    set { avatar_image.surface = value;}
  }

  private int _unread_count = 0;
  public int unread_count {
    get {
      return this._unread_count;
    }
    set {
      this._unread_count = value;
      this.update_unread_count ();
    }
  }

  public DMThreadEntry (int64 user_id) {
    this.user_id = user_id;
    update_unread_count ();
  }

  private void update_unread_count () {
    if (unread_count == 0)
      unread_count_label.hide ();
    else {
      unread_count_label.show ();
      unread_count_label.label = ngettext ("(%d unread)",
                                           "(%d unread)",
                                           unread_count).printf(unread_count);
    }
  }
}

