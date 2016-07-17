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

[GtkTemplate (ui = "/org/baedert/corebird/ui/lists-page.ui")]
class ListsPage : IPage, ScrollWidget, IMessageReceiver {
  public const int MODE_DELETE = 1;

  private BadgeRadioButton radio_button;
  public int unread_count                   { get; set; }
  private unowned MainWindow main_window;
  public unowned MainWindow window {
    set {
      main_window = value;
      user_lists_widget.main_window = value;
    }
  }
  public unowned Account account            { get; set; }
  public unowned DeltaUpdater delta_updater { get; set; }
  public int id                             { get; set; }
  private bool inited = false;
  private int64 user_id;
  [GtkChild]
  private UserListsWidget user_lists_widget;


  public ListsPage (int id, Account account) {
    this.id = id;
    this.account = account;
    this.user_lists_widget.account = account;
  }

  public void on_join (int page_id, Bundle? args) {
    int mode = 0;

    if (!GLib.NetworkMonitor.get_default ().get_network_available ())
      return;

    if (args != null)
      mode = args.get_int ("mode");

    if (mode == 0 && !inited) {
      inited = true;
      this.user_id = account.id;
      load_newest.begin ();
    } else if (mode  == MODE_DELETE) {
      int64 list_id = args.get_int64 ("list_id");
      message (@"Deleting list with id $list_id");
      user_lists_widget.remove_list (list_id);
    }
  }

  public void on_leave () {
    user_lists_widget.unreveal ();
  }


  private async void load_newest () {
    yield user_lists_widget.load_lists (user_id);
  }

  private void stream_message_received (StreamMessageType type, Json.Node root) { // {{{
    if (type == StreamMessageType.EVENT_LIST_CREATED ||
        type == StreamMessageType.EVENT_LIST_SUBSCRIBED) {
      var obj = root.get_object ().get_object_member ("target_object");
      var entry = new ListListEntry.from_json_data (obj, account);
      user_lists_widget.add_list (entry);
    } else if (type == StreamMessageType.EVENT_LIST_DESTROYED ||
               type == StreamMessageType.EVENT_LIST_UNSUBSCRIBED) {
      var obj = root.get_object ().get_object_member ("target_object");
      int64 list_id = obj.get_int_member ("id");
      user_lists_widget.remove_list (list_id);
    } else if (type == StreamMessageType.EVENT_LIST_UPDATED) {
      var obj = root.get_object ().get_object_member ("target_object");
      int64 list_id = obj.get_int_member ("id");
      update_list (list_id, obj);
    } else if (type == StreamMessageType.EVENT_LIST_MEMBER_ADDED) {
      var obj = root.get_object ().get_object_member ("target_object");
      int64 list_id = obj.get_int_member ("id");
      user_lists_widget.update_member_count (list_id, 1);
    } else if (type == StreamMessageType.EVENT_LIST_MEMBER_REMOVED) {
      var obj = root.get_object ().get_object_member ("target_object");
      int64 list_id = obj.get_int_member ("id");
      user_lists_widget.update_member_count (list_id, -1);
    }

  } // }}}

  public async TwitterList[] get_user_lists () {
    if (!inited) {
      inited = true;
      yield user_lists_widget.load_lists (user_id);
    }

    return user_lists_widget.get_user_lists ();
  }

  private void update_list (int64 list_id, Json.Object obj) {
    string name = obj.get_string_member ("full_name");
    string description = obj.get_string_member ("description");
    string mode = obj.get_string_member ("mode");
    user_lists_widget.update_list (list_id, name, description, mode);
  }


  public void create_radio_button (Gtk.RadioButton? group) {
    radio_button = new BadgeRadioButton (group, "view-list-symbolic", _("Lists"));
  }


  public string get_title () {
    return _("Lists");
  }

  public Gtk.RadioButton? get_radio_button () {
    return radio_button;
  }

}
