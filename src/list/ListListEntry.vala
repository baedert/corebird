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




[GtkTemplate (ui = "/org/baedert/corebird/ui/list-list-entry.ui")]
class ListListEntry : Gtk.ListBoxRow {
  [GtkChild]
  private Gtk.Label name_label;
  public new string name {
    set {
      name_label.label = value;
    }
    get {
      return name_label.label;
    }
  }
  [GtkChild]
  private Gtk.Label description_label;
  public string description {
    set {
      description_label.label = value;
    }
    get {
      return description_label.label;
    }
  }
  [GtkChild]
  private Gtk.MenuItem delete_list_item;
  [GtkChild]
  private Gtk.MenuItem unsubscribe_list_item;
  [GtkChild]
  private Gtk.MenuItem subscribe_list_item;

  public int64 id;
  public bool user_list = false;
  public string creator_screen_name;
  public int n_subscribers;
  public int n_members = 0;
  public int64 created_at;
  public string mode;
  private unowned Account account;

  public ListListEntry.from_json_data (Json.Object obj, Account account) {
    this.account = account;
    var user = obj.get_object_member ("user");
    name = obj.get_string_member ("full_name");
    description = obj.get_string_member ("description");
    id = obj.get_int_member ("id");
    creator_screen_name = user.get_string_member ("screen_name");
    n_subscribers = (int)obj.get_int_member ("subscriber_count");
    n_members = (int)obj.get_int_member ("member_count");
    created_at = Utils.parse_date (obj.get_string_member ("created_at")).to_unix ();
    mode = obj.get_string_member ("mode");
    bool following = obj.get_boolean_member ("following");
    if (following) {
      unsubscribe_list_item.show ();
      subscribe_list_item.hide ();
    } else {
      unsubscribe_list_item.hide ();
      subscribe_list_item.show ();
    }

    if (user.get_int_member ("id") == account.id) {
      user_list = true;
      unsubscribe_list_item.hide ();
    } else
      delete_list_item.hide ();
  }

  [GtkCallback]
  private void delete_list_cb () {
    this.sensitive = false;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/destroy.json");
    call.set_method ("POST");
    call.add_param ("list_id", id.to_string ());
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message);
        return;
      }

    });
  }

  [GtkCallback]
  private void unsubscribe_list_cb () {
    this.sensitive = false;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/subscribers/destroy.json");
    call.set_method ("POST");
    call.add_param ("list_id", id.to_string ());
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message);
        return;
      }

    });
  }

  [GtkCallback]
  private void subscribe_list_cb () {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/subscribers/create.json");
    call.set_method ("POST");
    call.add_param ("list_id", id.to_string ());
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message);
        return;
      }
      subscribe_list_item.hide ();
      unsubscribe_list_item.show ();
    });
  }
}
