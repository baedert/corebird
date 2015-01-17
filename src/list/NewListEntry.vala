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







[GtkTemplate (ui = "/org/baedert/corebird/ui/new-list-entry.ui")]
class NewListEntry : Gtk.ListBoxRow {
  [GtkChild]
  private Gtk.Entry list_name_entry;
  [GtkChild]
  private Gtk.Revealer revealer;
  public signal void create_activated (string list_name);



  public void reveal () {
    revealer.reveal_child = true;
    this.activatable = false;
    list_name_entry.grab_focus ();
  }

  public void unreveal () {
    revealer.reveal_child = false;
    this.activatable = true;
    list_name_entry.text = "";
  }

  [GtkCallback]
  private void create_list_button_clicked_cb () {
    create_activated (list_name_entry.text);
  }
}
