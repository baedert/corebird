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


struct DMThread {
  string screen_name;
  int64 user_id;
  string last_message;
  Gdk.Pixbuf avatar;
}


[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-thread-entry.ui")]
class DMThreadEntry : Gtk.ListBoxRow {
  [GtkChild]
  private Label screen_name_label;
  [GtkChild]
  private Label last_message_label;
  [GtkChild]
  private Image avatar_image;

  public Gdk.Pixbuf avatar {
    set { avatar_image.pixbuf = value;}
  }


  public DMThreadEntry (DMThread thread) {
    this.screen_name_label.label = thread.screen_name;
    this.last_message_label.label = thread.last_message;
  }
}

