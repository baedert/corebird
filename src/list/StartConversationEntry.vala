





using Gtk;


[GtkTemplate (ui = "/org/baedert/corebird/ui/start-conversation-entry.ui")]
class StartConversationEntry : Gtk.ListBoxRow {
  private static const int MAX_RESULTS = 7;
  [GtkChild]
  private Gtk.Revealer revealer;
  [GtkChild]
  private ReplyEntry name_entry;
  private UserCompletion user_completion;
  private Gtk.Window completion_window = new Gtk.Window (WindowType.POPUP);
  private ListBox completion_list = new ListBox ();
  public signal void activated ();
  private int current_match = -1;

  public StartConversationEntry (Account account) {
    completion_window.set_type_hint (Gdk.WindowTypeHint.COMBO);
    completion_window.set_attached_to (name_entry);
    completion_window.set_screen (name_entry.get_screen ());

    var popup_frame = new Gtk.Frame (null);
    var scroller = new Gtk.ScrolledWindow (null, null);
    popup_frame.add (scroller);
    scroller.add (completion_list);
    completion_window.add (popup_frame);

    user_completion = new UserCompletion (account, MAX_RESULTS);
    user_completion.connect_to (name_entry.buffer, "text");
    user_completion.start_completion.connect (() => {
      completion_window.show_all ();
      position_popup_window ();
      completion_list.foreach ((w) => { completion_list.remove (w); });
    });
    user_completion.populate_completion.connect ((name, screen_name) => {
      var l = new CompletionListEntry (name, screen_name);
      l.show_all ();
      completion_list.add (l);
    });

    name_entry.key_press_event.connect (name_entry_key_pressed);
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
    if (name_entry.text.length > 0)
      activated ();
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
