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

[GtkTemplate (ui = "/org/baedert/corebird/ui/modify-snippet-dialog.ui")]
class ModifySnippetDialog : Gtk.Dialog {
  [GtkChild]
  private Gtk.Entry key_entry;
  [GtkChild]
  private Gtk.Entry value_entry;
  [GtkChild]
  private Gtk.Label error_label;

  public ModifySnippetDialog (string? key = null, string? value = null) {
    GLib.Object (use_header_bar: Gtk.Settings.get_default ().gtk_dialogs_use_header ? 1 : 0);

    if (key != null) {
      assert (value != null);

      key_entry.text = key;
      value_entry.text = value;
    }
  }


  private void save_snippet () {

  }



  public override void response (int response_id) {
    if (response_id == Gtk.ResponseType.CANCEL) {
      this.destroy ();
    } else if (response_id == Gtk.ResponseType.OK) {
      save_snippet ();
      this.destroy ();
    }
  }
}
