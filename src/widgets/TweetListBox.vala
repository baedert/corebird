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
  private Gtk.Stack? placeholder = null;
  private Gtk.Label no_entries_label;

  private Gtk.Box error_box;
  private Gtk.Label error_label;
  private Gtk.Button retry_button;
  private Cb.TweetRow? _action_entry;
  public Cb.TweetRow? action_entry {
    get {
      return _action_entry;
    }
  }

  public signal void retry_button_clicked ();

  public Cb.DeltaUpdater delta_updater;
  public unowned Account account;
  public Cb.TweetModel model = new Cb.TweetModel ();
  private Gtk.GestureMultiPress press_gesture;

  public TweetListBox () {
  }


  construct {
    this.get_style_context ().add_class ("tweets");
    add_placeholder ();
    this.set_selection_mode (Gtk.SelectionMode.NONE);
    this.press_gesture = new Gtk.GestureMultiPress (this);
    this.press_gesture.set_button (0);
    this.press_gesture.set_propagation_phase (Gtk.PropagationPhase.BUBBLE);
    this.press_gesture.pressed.connect (gesture_pressed_cb);
    this.delta_updater = new Cb.DeltaUpdater (this);
    Settings.get ().bind ("double-click-activation",
                          this, "activate-on-single-click",
                          GLib.SettingsBindFlags.INVERT_BOOLEAN);

    Cb.Utils.bind_model (this, this.model, widget_create_func);
  }

  private Gtk.Widget widget_create_func (GLib.Object obj) {
    assert (obj is Cb.Tweet);

    var row = new Cb.TweetRow ((Cb.Tweet) obj,
                               (MainWindow) get_toplevel ());
                               //this.account);
    //var row = new Cb.TweetRow ((Cb.Tweet) obj,
                                  //(MainWindow) get_toplevel (),
                                  //this.account);
    //row.fade_in ();
    row.show ();
    return row;
  }

  private void gesture_pressed_cb (int    n_press,
                                   double x,
                                   double y) {
    Gdk.EventSequence sequence = this.press_gesture.get_current_sequence ();
    Gdk.Event event = this.press_gesture.get_last_event (sequence);

    if (event.triggers_context_menu ()) {
      Gtk.Widget row = this.get_row_at_y ((int)y);
      if (row is Cb.TweetRow && row.sensitive) {
        var tle = (Cb.TweetRow) row;
        if (tle != this._action_entry && this._action_entry != null &&
            this._action_entry.shows_actions ()) {
          this._action_entry.toggle_mode ();
        }
        tle.toggle_mode ();
        if (tle.shows_actions ())
          set_action_entry (tle);
        else
          set_action_entry (null);

        this.press_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
      }
    }
  }

  private void set_action_entry (Cb.TweetRow? entry) {
    if (this._action_entry != null) {
      this._action_entry.destroy.disconnect (action_entry_destroyed_cb);
      this._action_entry = null;
    }

    if (entry != null) {
      this._action_entry = entry;
      this._action_entry.destroy.connect (action_entry_destroyed_cb);
    }
  }

  private void action_entry_destroyed_cb () {
    this._action_entry = null;
  }

  private void add_placeholder () {
    placeholder = new Gtk.Stack ();
    placeholder.transition_type = Gtk.StackTransitionType.CROSSFADE;
    var loading_label = new Gtk.Label (_("Loading…"));
    loading_label.get_style_context ().add_class ("dim-label");
    placeholder.add_named (loading_label, "spinner");
    no_entries_label  = new Gtk.Label (_("No entries found"));
    no_entries_label.get_style_context ().add_class ("dim-label");
    no_entries_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
    placeholder.add_named (no_entries_label, "no-entries");

    error_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
    error_label = new Gtk.Label ("");
    error_label.get_style_context ().add_class ("dim-label");
    error_label.margin = 12;
    error_label.selectable = true;
    error_label.wrap = true;
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
    placeholder.show ();
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
      if (w is Gtk.ListBoxRow) {
        remove (w);
      }
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
