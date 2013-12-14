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
class ListsPage : IPage, ScrollWidget {
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

  public ListsPage (int id) {
    this.id = id;
    user_list_box.row_activated.connect (row_activated);
    subscribed_list_box.row_activated.connect (row_activated);
    var spinner = new Gtk.Spinner ();
    spinner.set_size_request (75, 75);
    spinner.start ();
    spinner.show_all ();
    subscribed_list_box.set_placeholder (spinner);

    var spinner2 = new Gtk.Spinner ();
    spinner2.set_size_request (75, 75);
    spinner2.start ();
    spinner2.show_all ();
    user_list_box.set_placeholder (spinner2);
  }

  public void on_join (int page_id, va_list arg_list) {
    if (inited)
      return;

    inited = true;
    load_newest ();
  }

  public void on_leave () {}


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
      var user = obj.get_object_member ("user");
      var entry = new ListListEntry ();
      entry.name = obj.get_string_member ("full_name");
      entry.description = obj.get_string_member ("description");
      entry.id = obj.get_int_member ("id");
      entry.creator_screen_name = user.get_string_member ("screen_name");
      entry.n_subscribers = (int)obj.get_int_member ("subscriber_count");
      entry.n_members = (int)obj.get_int_member ("member_count");
      entry.created_at = Utils.parse_date (obj.get_string_member ("created_at")).to_unix ();
      entry.mode = obj.get_string_member ("mode");
      if (user.get_int_member ("id") == account.id)
        entry.user_list = true;

      list_box.add (entry);

    });
    return arr.get_length ();
  } // }}}


  private void row_activated (Gtk.ListBoxRow row) {
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

  public void create_tool_button (RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton (group, "corebird-lists-symbolic");
    tool_button.label = _("Lists");
  }

  public RadioToolButton? get_tool_button () {
    return tool_button;
  }

}
