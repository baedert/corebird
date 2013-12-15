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

[GtkTemplate (ui = "/org/baedert/corebird/ui/lists-page.ui")]
class ListsPage : IPage, ScrollWidget, IMessageReceiver {
  public static const int MODE_DELETE = 1;

  private BadgeRadioToolButton tool_button;
  public int unread_count                   { get; set; }
  public unowned MainWindow main_window     { get; set; }
  public unowned Account account            { get; set; }
  public unowned DeltaUpdater delta_updater { get; set; }
  public int id                             { get; set; }
  private bool inited = false;
  [GtkChild]
  private Gtk.ListBox user_list_box;
  [GtkChild]
  private Gtk.Frame user_list_frame;
  [GtkChild]
  private Gtk.Label subscribed_list_label;
  [GtkChild]
  private Gtk.ListBox subscribed_list_box;
  [GtkChild]
  private Gtk.Frame subscribed_list_frame;

  private NewListEntry new_list_entry = new NewListEntry ();

  public ListsPage (int id) {
    this.id = id;
    user_list_box.row_activated.connect (row_activated);
    subscribed_list_box.row_activated.connect (row_activated);
    var spinner = new Gtk.Spinner ();
    spinner.set_size_request (75, 75);
    spinner.start ();
    spinner.show_all ();
    subscribed_list_box.set_placeholder (spinner);

    user_list_box.set_header_func (header_func);
    new_list_entry.create_activated.connect (new_list_create_activated_cb);
    user_list_box.add (new_list_entry);
  }

  public void on_join (int page_id, va_list arg_list) {
    int mode = arg_list.arg<int> ();

    if (mode == 0 && !inited) {
      inited = true;
      load_newest ();
    } else if (mode  == MODE_DELETE) {
      int64 list_id = arg_list.arg<int64> ();
      message (@"Deleting list with id $list_id");
      remove_list (list_id);
    }
  }

  public void on_leave () {
    new_list_entry.unreveal ();
  }


  private void load_newest () { // {{{
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/subscriptions.json");
    call.set_method ("GET");
    call.add_param ("user_id", account.id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      uint n_subscribed_list = lists_received_cb (obj, res, subscribed_list_box);
      if (n_subscribed_list == 0) {
        subscribed_list_box.hide ();
        subscribed_list_frame.hide ();
        subscribed_list_label.hide ();
      }
    });


    var user_call = account.proxy.new_call ();
    user_call.set_function ("1.1/lists/ownerships.json");
    user_call.set_method ("GET");
    user_call.add_param ("user_id", account.id.to_string ());
    user_call.invoke_async.begin (null, (obj, res) => {
      uint n_user_list = lists_received_cb (obj, res, user_list_box);
      if (n_user_list == 0) {
        user_list_box.hide ();
        user_list_frame.hide ();
      }
    });
  } // }}}

  private uint lists_received_cb (GLib.Object ?o, GLib.AsyncResult res,
                                 Gtk.ListBox list_box) { // {{{
    var call = (Rest.ProxyCall) o;
    try {
      call.invoke_async.end (res);
    } catch (GLib.Error e) {
      Utils.show_error_object (call.get_payload (), e.message);
      return 0;
    }
    var parser = new Json.Parser ();
    try {
      parser.load_from_data (call.get_payload ());
    } catch (GLib.Error e) {
      warning (e.message);
      return 0;
    }

    var arr = parser.get_root ().get_object ().get_array_member ("lists");
    arr.foreach_element ((array, index, node) => {
      var obj = node.get_object ();
      var entry = new ListListEntry.from_json_data (obj, account.id);
      list_box.add (entry);
    });
    return arr.get_length ();
  } // }}}


  private void stream_message_received (StreamMessageType type, Json.Node root) { // {{{
    if (type == StreamMessageType.EVENT_LIST_CREATED) {
      var obj = root.get_object ().get_object_member ("target_object");
      var entry = new ListListEntry.from_json_data (obj, account.id);
      user_list_box.add (entry);
    } else if (type == StreamMessageType.EVENT_LIST_DESTROYED) {
      var obj = root.get_object ().get_object_member ("target_object");
      int64 list_id = obj.get_int_member ("id");
      remove_list (list_id);
    }
  } // }}}



  private void row_activated (Gtk.ListBoxRow row) {
    if (row is NewListEntry) {
      ((NewListEntry)row).reveal ();
    } else {
      var entry = (ListListEntry) row;
      main_window.switch_page (MainWindow.PAGE_LIST_STATUSES,
                               entry.id,
                               entry.name,
                               entry.user_list,
                               entry.description,
                               entry.creator_screen_name,
                               entry.n_subscribers,
                               entry.n_members,
                               entry.created_at,
                               entry.mode);
    }
  }


  private void header_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? row_before) { //{{{
    if (row_before == null)
      return;

    Widget header = row.get_header ();
    if (header == null) {
      header = new Gtk.Separator (Orientation.HORIZONTAL);
      header.show ();
      row.set_header (header);
    }
  } //}}}

  private void new_list_create_activated_cb (string list_name) { // {{{
    new_list_entry.sensitive = false;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/create.json");
    call.set_method ("POST");
    call.add_param ("name", list_name);
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message);
        return;
      }
      new_list_entry.sensitive = true;
    });
  } // }}}


  private void remove_list (int64 list_id) {
    user_list_box.foreach ((w) => {
      if (!(w is ListListEntry))
        return;

      if (((ListListEntry)w).id == list_id) {
        user_list_box.remove (w);
      }
    });
  }

  public void create_tool_button (RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton (group, "corebird-lists-symbolic");
    tool_button.label = _("Lists");
  }

  public RadioToolButton? get_tool_button () {
    return tool_button;
  }

}
