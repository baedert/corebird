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
[GtkTemplate (ui = "/org/baedert/corebird/ui/add-filter-dialog.ui")]
class AddFilterDialog : Gtk.ApplicationWindow {
  [GtkChild]
  private Gtk.Button save_button;

  public AddFilterDialog (Gtk.ApplicationWindow parent) {
    this.set_show_menubar (false);
    this.set_transient_for (parent);
    this.application = parent.get_application ();
  }


  [GtkCallback]
  private void cancel_button_clicked_cb () {
    this.destroy ();
  }


  [GtkCallback]
  private void save_button_clicked_cb () {
    this.destroy ();
  }

  [GtkCallback]
  private void content_entry_changed_cb () {

  }
}
