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

public class TweetListBox : Gtk.ListBox {
  private Gtk.Stack placeholder = null;
  private Gtk.Label no_entries_label;
  private ProgressEntry progress_entry;

  public TweetListBox (bool show_placeholder = true) {
    if (show_placeholder) {
      add_placeholder ();
    }
    progress_entry = new ProgressEntry ();
    this.get_style_context ().add_class ("stream");
    this.set_selection_mode (Gtk.SelectionMode.NONE);
  }


  construct {
    add_placeholder ();
  }


  private void add_placeholder () {
    placeholder = new Gtk.Stack ();
    placeholder.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
    var spinner = new Gtk.Spinner ();
    spinner.set_size_request (60, 60);
    spinner.start ();
    spinner.show_all ();
    placeholder.add_named (spinner, "spinner");
    no_entries_label  = new Gtk.Label (_("No entries found"));
    no_entries_label.get_style_context ().add_class ("dim-label");
    no_entries_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
    placeholder.add_named (no_entries_label, "no-entries");
    placeholder.visible_child_name = "spinner";
    placeholder.show_all ();
    placeholder.set_valign (Gtk.Align.CENTER);
    placeholder.set_halign (Gtk.Align.CENTER);
    this.set_placeholder (placeholder);

  }

  public void set_empty () {
    placeholder.visible_child_name = "no-entries";
  }

  public void set_unempty () {
      placeholder.visible_child_name = "spinner";
  }

  public Gtk.Stack? get_placeholder () {
    return placeholder;
  }

  public void remove_all () {
    this.foreach ((w) => {
      remove (w);
    });
  }

  public void set_placeholder_text (string text) {
    no_entries_label.label = text;
  }

  public void reset_placeholder_text () {
    no_entries_label.label = _("No entries found");
  }

  public void add_progress_entry () {
    if (progress_entry.parent == null) {
      progress_entry.show_all ();
      this.add (progress_entry);
    }
  }
}
