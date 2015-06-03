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
  [GtkChild]
  private Gtk.Button save_button;
  [GtkChild]
  private Gtk.Button delete_button;
  private string? old_key = null;

  public signal void snippet_updated (string? old_key, string? key, string? value);

  public ModifySnippetDialog (string? key = null, string? value = null) {
    GLib.Object (use_header_bar: Gtk.Settings.get_default ().gtk_dialogs_use_header ? 1 : 0);

    if (key != null) {
      assert (value != null);

      this.old_key = key;
      this.key_entry.text = key;
      this.value_entry.text = value;
      this.delete_button.show ();
      this.title = _("Modify Snippet");
    }

    key_entry.buffer.inserted_text.connect (validate_input);
    key_entry.buffer.deleted_text.connect (validate_input);
    value_entry.buffer.inserted_text.connect (validate_input);
    value_entry.buffer.deleted_text.connect (validate_input);
  }

  private void validate_input () {
    string key = key_entry.text.strip ();
    string value = value_entry.text.strip ();

    key_entry.get_style_context ().remove_class ("error");
    value_entry.get_style_context ().remove_class ("error");
    error_label.label = "";
    save_button.sensitive = true;

    if (key == "") {
      error_label.label = _("Snippet can't be empty");
      key_entry.get_style_context ().add_class ("error");
      save_button.sensitive = false;
      return;
    }

    if (value == "") {
      error_label.label = _("Replacement can't be empty");
      value_entry.get_style_context ().add_class ("error");
      save_button.sensitive = false;
      return;
    }

    if (key.contains (" ")  ||
        key.contains ("\t")) {
      error_label.label = _("Snippet may not contain whitespace");
      key_entry.get_style_context ().add_class ("error");
      save_button.sensitive = false;
      return;
    }

    if (Corebird.snippet_manager.get_snippet (key) != null &&
        this.old_key != key) {
      error_label.label = _("Snippet already exists");
      save_button.sensitive = false;
      return;
    }

  }


  private void save_snippet () {
    string new_value = this.value_entry.text;
    string new_key   = this.key_entry.text;

    if (this.old_key != null) {
      Corebird.snippet_manager.set_snippet (old_key, new_key, new_value);
    } else {
      Corebird.snippet_manager.insert_snippet (new_key, new_value);
    }

    this.snippet_updated (old_key, new_key, new_value);
  }

  [GtkCallback]
  private void delete_button_clicked_cb () {
    assert (this.old_key != null);
    Corebird.snippet_manager.remove_snippet (this.old_key);

    this.snippet_updated (this.old_key, null, null);
    this.destroy ();
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
