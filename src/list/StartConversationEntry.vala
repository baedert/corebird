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


using Gtk;


[GtkTemplate (ui = "/org/baedert/corebird/ui/start-conversation-entry.ui")]
class StartConversationEntry : Gtk.ListBoxRow {
  private static const int MAX_RESULTS = 7;
  [GtkChild]
  private Gtk.Revealer revealer;
  [GtkChild]
  private ReplyEntry name_entry;
  [GtkChild]
  private Gtk.Stack go_stack;
  [GtkChild]
  private Gtk.Spinner go_spinner;

  private UserCompletion user_completion;
  private Gtk.Window completion_window = new Gtk.Window (WindowType.POPUP);
  private ListBox completion_list = new ListBox ();
  private int current_match = -1;
  public signal void start (int64 user_id);
  private unowned Account account;

  public StartConversationEntry (Account account) {
    this.account = account;
    completion_window.set_type_hint (Gdk.WindowTypeHint.COMBO);
    completion_window.set_attached_to (name_entry);
    completion_window.set_screen (name_entry.get_screen ());

    var popup_frame = new Gtk.Frame (null);
    var scroller = new Gtk.ScrolledWindow (null, null);
    popup_frame.add (scroller);
    scroller.add (completion_list);
    completion_window.add (popup_frame);

    user_completion = new UserCompletion (account, MAX_RESULTS);
//    user_completion.connect_to (name_entry.buffer, "text");
/*    user_completion.start_completion.connect (() => {
      completion_window.show_all ();
      position_popup_window ();
      completion_list.foreach ((w) => { completion_list.remove (w); });
    });
    user_completion.populate_completion.connect ((name, screen_name) => {
      var l = new CompletionListEntry (name, screen_name);
      l.show_all ();
      completion_list.add (l);
    });*/

    name_entry.key_press_event.connect (name_entry_key_pressed);
    activate.connect (() => {
      go_stack.visible_child_name = "spinner";
      go_spinner.start ();
    });
  }

  private void position_popup_window () {
    int x, y;
    Gtk.Allocation alloc;
    name_entry.get_allocation (out alloc);
    name_entry.get_window ().get_origin (out x, out y);
    x += alloc.x;
    y += alloc.y + alloc.height;

    completion_window.move (x, y);
    completion_window.resize (alloc.width, 50);
  }

  private bool name_entry_key_pressed (Gdk.EventKey evt) {
    uint num_results = completion_list.get_children ().length ();
    if (evt.keyval == Gdk.Key.Down) {
      current_match = (current_match + 1) % (int)num_results;
      var row = completion_list.get_row_at_index (current_match);
      completion_list.select_row (row);
      return true;
    } else if (evt.keyval == Gdk.Key.Up) {
      current_match --;
      if (current_match < 0) current_match = (int)num_results - 1;
      var row = completion_list.get_row_at_index (current_match);
      completion_list.select_row (row);
      return true;
    } else if (evt.keyval == Gdk.Key.Return) {

    }
    return false;
  }

  construct {
    name_entry.cancelled.connect (() => {
      unreveal ();
      this.grab_focus ();
    });
  }

  public void reveal () {
    revealer.reveal_child = true;
    name_entry.grab_focus ();
  }

  public void unreveal () {
    revealer.reveal_child = false;
    completion_window.hide ();
  }

  [GtkCallback]
  private void go_button_clicked_cb () {
//    if (name_entry.text.length > 0)
//      activated ();
    string screen_name = name_entry.text;
    if (screen_name.has_prefix ("@"))
      screen_name = screen_name.substring (1);

    name_entry.sensitive = false;
    var call = account.proxy.new_call ();
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res):
      } catch (GLib.Error e) {
        critical (e.message);
      }
      name_entry.sensitive = true;
      reply_stack.visible_child_name = "button";
    });
  }
}


class CompletionListEntry : Gtk.ListBoxRow {
  private Label name_label = new Label ("");
  private Label screen_name_label = new Label ("");

  public CompletionListEntry (string name, string screen_name) {
    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    name_label.label = name;
    screen_name_label.label = "@" + screen_name;
    name_label.set_valign (Gtk.Align.BASELINE);
    screen_name_label.set_valign (Gtk.Align.BASELINE);
    screen_name_label.get_style_context ().add_class ("dim-label");
    box.pack_start (name_label, false, false);
    box.pack_start (screen_name_label, false, false);
    add (box);
  }
}
