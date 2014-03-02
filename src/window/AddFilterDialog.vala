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
class AddFilterDialog : Gtk.Dialog {
  private static const int RESPONSE_CANCEL = 0;
  private static const int RESPONSE_SAVE   = 1;

  [GtkChild]
  private Gtk.Entry regex_entry;
  [GtkChild]
  private Gtk.Label regex_status_label;

  private GLib.Regex regex;

  public AddFilterDialog (Gtk.ApplicationWindow parent) {
    this.set_transient_for (parent);
    this.application = parent.get_application ();
  }


  public override void response (int response_id) {
    if (response_id == RESPONSE_CANCEL) {
      this.destroy ();
      return;
    } else if (response_id == RESPONSE_SAVE) {

    }
  }

  [GtkCallback]
  private void regex_entry_changed_cb () {
    try {
      regex = new GLib.Regex (regex_entry.text);
    } catch (GLib.RegexError e) {
      regex_status_label.label = e.message;
    }
  }
}
