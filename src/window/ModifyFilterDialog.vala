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
[GtkTemplate (ui = "/org/baedert/corebird/ui/modify-filter-dialog.ui")]
class ModifyFilterDialog : Gtk.Dialog {
  private static const int RESPONSE_CANCEL = 0;
  private static const int RESPONSE_SAVE   = 1;

  [GtkChild]
  private Gtk.Entry regex_entry;
  [GtkChild]
  private Gtk.Label regex_status_label;
  [GtkChild]
  private Gtk.TextView regex_test_text;
  [GtkChild]
  private Gtk.Button save_button;
  [GtkChild]
  private Gtk.CheckButton sensitive_checkbutton;

  private GLib.Regex regex;
  private unowned Account account;
  private unowned Filter filter;

  /** created will be true if the filter has just been created by the user(i.e. not modified) */
  public signal void filter_added (Filter filter, bool created);

  public ModifyFilterDialog (Gtk.ApplicationWindow parent, Account account,
                             Filter? filter = null) {
    this.set_transient_for (parent);
    this.application = parent.get_application ();
    this.account = account;
    if (filter != null) {
      regex_entry.text = filter.content;
      sensitive_checkbutton.active = filter.sensitive;
    }
    this.filter = filter;
  }

  construct {
    regex_test_text.buffer.changed.connect (regex_entry_changed_cb);
    sensitive_checkbutton.toggled.connect (regex_entry_changed_cb);
  }


  public override void response (int response_id) {
    if (response_id == RESPONSE_CANCEL) {
      this.destroy ();
    } else if (response_id == RESPONSE_SAVE) {
      save_filter ();
      this.destroy ();
    }
  }

  [GtkCallback]
  private void regex_entry_changed_cb () {
    try {
      if(!sensitive_checkbutton.active)
        this.regex = new GLib.Regex (regex_entry.text, GLib.RegexCompileFlags.CASELESS);
      else
        regex = new GLib.Regex (regex_entry.text);
    } catch (GLib.RegexError e) {
      regex_status_label.label = e.message;
      save_button.sensitive = false;
      return;
    }
    bool matches = regex.match (regex_test_text.buffer.text);
    if (matches) {
      regex_status_label.label = _("Matches");
    } else {
      regex_status_label.label = _("Doesn't match");
    }
    save_button.sensitive = (regex_entry.text.length != 0);
  }

  private void save_filter () {
    string content = regex_entry.text;
    if (this.filter == null) {
      int id = (int)account.db.insert ("filters")
                               .val ("content", content)
                               .val ("sensitive", sensitive_checkbutton.active.to_string())
                               .run();
      Filter f = new Filter (content, sensitive_checkbutton.active);
      f.id = id;
      account.add_filter (f);
      filter_added (f, true);
    } else {
      /* We update the existing filter */
      account.db.update ("filters").val ("content", content)
                                   .val ("sensitive", sensitive_checkbutton.active.to_string())
                                   .where_eq ("id", filter.id.to_string ())
                                   .run ();
      foreach (var f in account.filters) {
        if (f.id == this.filter.id) {
          f.reset (content);
          filter_added (f, false);
          break;
        }
      }
    }
  }
}
