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


[GtkTemplate (ui = "/org/baedert/corebird/ui/list-statuses-page.ui")]
class ListStatusesPage : ScrollWidget, IPage {
  public int id                         { get; set; }
  public unowned MainWindow main_window { get; set; }
  public unowned Account account        { get; set; }
  private int64 list_id;
  [GtkChild]
  private Gtk.ListBox tweet_list;
  [GtkChild]
  private MaxSizeContainer max_size_container;
  [GtkChild]
  private Gtk.Button delete_button;
  [GtkChild]
  private Gtk.Button edit_button;
  [GtkChild]
  private Gtk.Label description_label;
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
  private Gtk.Label creator_label;
  [GtkChild]
  private Gtk.Label subscribers_label;
  [GtkChild]
  private Gtk.Label members_label;
  [GtkChild]
  private Gtk.Label created_at_label;
  [GtkChild]
  private Gtk.Stack name_stack;
  [GtkChild]
  private Gtk.Entry name_entry;
  [GtkChild]
  private Gtk.Stack description_stack;
  [GtkChild]
  private Gtk.TextView description_text_view;
  [GtkChild]
  private Gtk.Stack delete_stack;
  [GtkChild]
  private Gtk.Button cancel_button;
  [GtkChild]
  private Gtk.Stack edit_stack;
  [GtkChild]
  private Gtk.Button save_button;
  [GtkChild]
  private Gtk.Stack mode_stack;
  [GtkChild]
  private Gtk.Label mode_label;
  [GtkChild]
  private Gtk.ComboBoxText mode_combo_box;


  public ListStatusesPage (int id) {
    this.id = id;
    this.scroll_event.connect (scroll_event_cb);
    var spinner = new Gtk.Spinner ();
    spinner.set_size_request (75, 75);
    spinner.start ();
    spinner.show_all ();
    tweet_list.set_placeholder (spinner);
  }

  private bool scroll_event_cb (Gdk.EventScroll evt) {
    if (evt.delta_y < 0 && this.vadjustment.value == 0) {
      int inc = (int)(vadjustment.step_increment * (-evt.delta_y));
      max_size_container.max_size += inc;
      max_size_container.queue_resize ();
      return true;
    }
    return false;
  }
  /**
   *
   *
   * va_list params:
   *  - int64 list_id - The id of the list to show
   *  - string name - The lists's name
   *  - bool user_list - true if the list belongs to the user, false otherwise
   *  - string description - the lists's description
   *  - string creator
   *  - int subscribers_count
   *  - int memebers_count
   *  - int64 created_at
   */
  public void on_join (int page_id, va_list args) { // {{{
    int64 list_id = args.arg<int64> ();
    if (list_id == 0)
      list_id = this.list_id;

    string? list_name = args.arg<string> ();
    if (list_name != null) {
      bool user_list = args.arg<bool> ();
      string description = args.arg<string> ();
      string creator = args.arg<string> ();
      int n_subscribers = args.arg<int> ();
      int n_members = args.arg<int> ();
      int64 created_at = args.arg<int64> ();

      delete_button.sensitive = user_list;
      edit_button.sensitive = user_list;

      name_label.label = list_name;
      description_label.label = "<big><big>" + description + "</big></big>";
      creator_label.label = creator;
      members_label.label = "%'d".printf (n_members);
      subscribers_label.label = "%'d".printf (n_subscribers);
      created_at_label.label = new GLib.DateTime.from_unix_local (created_at).format ("%x, %X");
    }

    message (@"Showing list with id $list_id");
    if (list_id == this.list_id) {
      this.list_id = list_id;
    } else {
      this.list_id = list_id;
      load_newest ();
    }

  } // }}}

  public void on_leave () {}

  private void load_newest () { // {{{
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/statuses.json");
    call.set_method ("GET");
    call.add_param ("list_id", list_id.to_string ());
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message);
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }

      var now = new GLib.DateTime.now_local ();
      var root_array = parser.get_root ().get_array ();
      root_array.foreach_element ((array, index, node) => {
        Tweet t = new Tweet ();
        t.load_from_json (node, now);

        TweetListEntry entry = new TweetListEntry (t, main_window, account);
        entry.show_all ();
        tweet_list.add (entry);
      });
    });

  } // }}}




  [GtkCallback]
  private void edit_button_clicked_cb () {
    name_stack.visible_child = name_entry;
    description_stack.visible_child = description_text_view;
    delete_stack.visible_child = cancel_button;
    edit_stack.visible_child = save_button;
    mode_stack.visible_child = mode_combo_box;

    name_entry.text = name_label.label;
  }

  [GtkCallback]
  private void cancel_button_clicked_cb () {
    name_stack.visible_child = name_label;
    description_stack.visible_child = description_label;
    delete_stack.visible_child = delete_button;
    edit_stack.visible_child = edit_button;
    mode_stack.visible_child = mode_label;
  }

  public void create_tool_button (Gtk.RadioToolButton? group) {}
  public Gtk.RadioToolButton? get_tool_button () {return null;}
}
