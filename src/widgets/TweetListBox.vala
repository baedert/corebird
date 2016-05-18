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

  private Gtk.Box error_box;
  private Gtk.Label error_label;
  private Gtk.Button retry_button;
  private TweetListEntry? _action_entry;
  public TweetListEntry? action_entry {
    get {
      return _action_entry;
    }
  }

  public signal void retry_button_clicked ();

  public unowned DeltaUpdater delta_updater;
  public unowned Account account;
  public TweetModel model = new TweetModel ();

  public TweetListBox (bool show_placeholder = true) {
    if (show_placeholder) {
      add_placeholder ();
    }
  }


  construct {
    add_placeholder ();
    this.get_style_context ().add_class ("stream");
    this.set_selection_mode (Gtk.SelectionMode.NONE);
    this.button_press_event.connect (button_press_cb);
    Settings.get ().bind ("double-click-activation",
                          this, "activate-on-single-click",
                          GLib.SettingsBindFlags.INVERT_BOOLEAN);
    this.bind_model (this.model, (obj) => {
      assert (obj is Tweet);

      var row = new TweetListEntry ((Tweet) obj,
                                    (MainWindow) get_toplevel (),
                                    this.account);
      delta_updater.add (row);
      row.fade_in ();
      return row;
    });
  }

  private bool button_press_cb (Gdk.EventButton evt) {
    if (evt.triggers_context_menu ()) {
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
      Gtk.Widget row = this.get_row_at_y ((int)relative_y);
      if (row is TweetListEntry && row.sensitive) {
        var tle = (TweetListEntry) row;
        if (tle != this._action_entry && this._action_entry != null &&
            this._action_entry.shows_actions) {
          this._action_entry.toggle_mode ();
        }
        tle.toggle_mode ();
        if (tle.shows_actions)
          this._action_entry = tle;
        else
          this._action_entry = null;
        return true;
      }
    }
    return false;
  }


  private void add_placeholder () {
    placeholder = new Gtk.Stack ();
    placeholder.transition_type = Gtk.StackTransitionType.CROSSFADE;
    var loading_label = new Gtk.Label (_("Loading..."));
    loading_label.get_style_context ().add_class ("dim-label");
    placeholder.add_named (loading_label, "spinner");
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

  public Gtk.Widget? get_first_visible_row () {
    int i = 0;
    Gtk.Widget? row = this.get_row_at_index (0);
    while (row != null && !row.visible) {
      i ++;
      row = this.get_row_at_index (i);
    }

    return row;
  }
}
