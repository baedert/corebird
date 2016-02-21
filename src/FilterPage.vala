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

[GtkTemplate (ui = "/org/baedert/corebird/ui/filter-page.ui")]
class FilterPage : Gtk.ScrolledWindow, IPage, IMessageReceiver {
  public int id { get; set; }
  public unowned MainWindow main_window {get; set;}
  public unowned Account account        {get; set;}
  private BadgeRadioButton radio_button;
  [GtkChild]
  private Gtk.ListBox filter_list;
  [GtkChild]
  private Gtk.ListBox user_list;
  [GtkChild]
  private Gtk.Frame user_list_frame;
  private bool filters_loaded = false;
  private bool users_loaded = false;

  public FilterPage (int id, Account account) {
    this.id = id;
    this.account = account;

    filter_list.set_header_func (default_header_func);
    filter_list.add (new AddListEntry (_("Add new Filter")));
    filter_list.row_activated.connect ((row) => {
      if (row is AddListEntry) {
        var dialog = new ModifyFilterDialog (main_window, account);
        dialog.filter_added.connect (filter_added_cb);
        dialog.show_all ();
      } else if (row is FilterListEntry) {
        var filter_row = (FilterListEntry) row;
        var dialog = new ModifyFilterDialog (main_window, account, filter_row.filter);
        dialog.filter_added.connect (filter_added_cb);
        dialog.show_all ();
      }
    });

    user_list.set_header_func (default_header_func);
  }

  public void on_join (int page_id, Bundle? args) { // {{{

    if (!filters_loaded) {
      foreach (Filter f in account.filters) {
        var entry = new FilterListEntry (f, account, main_window);
        filter_list.add (entry);
      }
      filters_loaded = true;
    }

    if (!GLib.NetworkMonitor.get_default ().get_network_available ())
      return;

    if (users_loaded)
      return;



    var call = account.proxy.new_call ();
    call.set_function ("1.1/blocks/list.json");
    call.set_method ("GET");
    call.add_param ("include_entities", "false");
    call.add_param ("skip_status", "true");
    TweetUtils.load_threaded.begin (call, null, (_, res) => {
      Json.Node? root = null;
      try  {
        root = TweetUtils.load_threaded.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }


      Json.Array users = root.get_object ().get_array_member ("users");
      uint n_users = users.get_length ();
      users.foreach_element ((arr, index, node) => {
        var obj = node.get_object ();
        add_user (obj);
      });
      if (n_users > 0) {
        user_list_frame.show ();
      }
    });

    users_loaded = true;
  } // }}}

  /**
   * Called when the user adds a new Filter via the AddFilterDialog
   *
   **/
  private void filter_added_cb (Filter f, bool created) {
    if (created) {
      var entry = new FilterListEntry (f, account, main_window);
      filter_list.add (entry);
    } else {
      var children = filter_list.get_children ();
      foreach (Gtk.Widget w in children) {
        if (!(w is FilterListEntry))
          continue;

        var le = (FilterListEntry) w;
        if (le.filter.id == f.id) {
          le.content = f.content;
          break;
        }
      }
    }
  }

  public void stream_message_received (StreamMessageType type, Json.Node root_node) {
    if (type == StreamMessageType.EVENT_BLOCK) {
      var obj = root_node.get_object ().get_object_member ("target");
      add_user (obj);
    } else if (type == StreamMessageType.EVENT_UNBLOCK) {
      var obj = root_node.get_object ().get_object_member ("target");
      int64 user_id = obj.get_int_member ("id");
      remove_user (user_id);
    }
  }

  private void add_user (Json.Object user_obj) {
    int64 id = user_obj.get_int_member ("id");
    string avatar_url = user_obj.get_string_member ("profile_image_url");

    if (this.get_scale_factor () == 2)
      avatar_url = avatar_url.replace ("_normal", "_bigger");

    // make sure the user does not yet exist in the list
    remove_user (id);
    var entry = new UserFilterEntry ();
    entry.user_id = id;
    entry.name = user_obj.get_string_member ("name");
    entry.screen_name = user_obj.get_string_member ("screen_name");
    entry.avatar_url = avatar_url;
    entry.deleted.connect ((id) => { unblock_user (id);});
    user_list.add (entry);
    user_list_frame.show ();
  }

  private void remove_user (int64 id) {
    foreach (Gtk.Widget w in user_list.get_children ()) {
      if (!(w is UserFilterEntry))
        continue;

      if (((UserFilterEntry)w).user_id == id)
        user_list.remove (w);
    }

    if (user_list.get_children ().length () == 0) {
      user_list_frame.hide ();
    }
  }

  private void unblock_user (int64 id) {
    var call = account.proxy.new_call ();
    call.set_method ("POST");
    call.set_function ("1.1/blocks/destroy.json");
    call.add_param ("include_entities", "false");
    call.add_param ("skip_status", "true");
    call.add_param ("user_id", id.to_string ());
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE);
        warning (e.message);
        return;
      }
    });
    remove_user (id);
  }

  [GtkCallback]
  private bool filter_list_keynav_failed_cb (Gtk.DirectionType direction) {
    if (direction == Gtk.DirectionType.DOWN) {
      if (user_list.visible) {
        user_list.child_focus (direction);
      }
      return true;
    }
    return false;
  }

  [GtkCallback]
  private bool user_list_keynav_failed_cb (Gtk.DirectionType direction) {
    if (direction == Gtk.DirectionType.UP) {
      filter_list.child_focus (direction);
      return true;
    }
    return false;
  }



  public void on_leave () {}
  public void create_radio_button (Gtk.RadioButton? group) {
    radio_button = new BadgeRadioButton(group, "corebird-filter-symbolic", _("Filters"));
  }

  public Gtk.RadioButton? get_radio_button() { return radio_button; }

  public string? get_title () {
    return _("Filters");
  }

}
