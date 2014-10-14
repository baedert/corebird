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
  private Gtk.Stack placeholder;
  private Gtk.Label no_entries_label;
  private ProgressEntry progress_entry;

  private Gtk.Box error_box;
  private Gtk.Label error_label;
  private Gtk.Button retry_button;

  public signal void retry_button_clicked ();

  public TweetListBox (bool show_placeholder = true) {
    if (show_placeholder) {
      add_placeholder ();
    }
  }


  construct {
    add_placeholder ();
    progress_entry = new ProgressEntry ();
    this.get_style_context ().add_class ("stream");
    this.set_selection_mode (Gtk.SelectionMode.NONE);
    this.button_press_event.connect (button_press_cb);
  }

  private bool button_press_cb (Gdk.EventButton evt) {
    if (evt.button == 3) {
      /* From gtklistbox.c */
      Gdk.Window? event_window = evt.window;
      Gdk.Window window = this.get_window ();
      double relative_y = evt.y;
      double parent_y;

      while ((event_window != null) && (event_window != window)) {
        event_window.coords_to_parent (0, relative_y, null, out parent_y);
        relative_y = parent_y;
        event_window = event_window.get_effective_parent ();
      }
      var row = (TweetListEntry) get_row_at_y ((int)relative_y);
      row.toggle_mode ();
      return true;
    }
    return false;
  }


  private void add_placeholder () {
    placeholder = new Gtk.Stack ();
    placeholder.transition_type = Gtk.StackTransitionType.CROSSFADE;
    var spinner = new Gtk.Spinner ();
    spinner.set_size_request (60, 60);
    spinner.start ();
    spinner.show_all ();
    placeholder.add_named (spinner, "spinner");
    no_entries_label  = new Gtk.Label (_("No entries found"));
    no_entries_label.get_style_context ().add_class ("dim-label");
    no_entries_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
    placeholder.add_named (no_entries_label, "no-entries");

    error_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
    error_label = new Gtk.Label ("");
    error_label.get_style_context ().add_class ("dim-label");
    retry_button = new Gtk.Button.with_label (_("Retry"));
    retry_button.set_halign (Gtk.Align.CENTER);
    retry_button.clicked.connect (() => {
      placeholder.visible_child_name = "spinner";
      retry_button_clicked ();
    });
    error_box.add (error_label);
    error_box.add (retry_button);
    placeholder.add_named (error_box, "error");

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

  public void set_error (string err_msg) {
    error_label.label = err_msg;
    placeholder.visible_child_name = "error";
  }

  public Gtk.Stack? get_placeholder () {
    return placeholder;
  }

  public void set_placeholder_text (string text) {
    no_entries_label.label = text;
  }

  public void reset_placeholder_text () {
    no_entries_label.label = _("No entries found");
  }

  public void remove_all () {
    this.foreach ((w) => {
      remove (w);
    });
  }

  public void add_progress_entry () {
    if (progress_entry.parent == null) {
      progress_entry.show_all ();
      this.add (progress_entry);
    }
  }

  public void remove_progress_entry () {
    if (progress_entry.parent != null) {
      this.remove (progress_entry);
    }
  }
}
