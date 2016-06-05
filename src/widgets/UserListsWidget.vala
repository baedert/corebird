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

[GtkTemplate (ui = "/org/baedert/corebird/ui/user-lists-widget.ui")]
class UserListsWidget : Gtk.Box {
  [GtkChild]
  private Gtk.Label user_list_label;
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
  [GtkChild]
  private NewListEntry new_list_entry;
  [GtkChild]
  private Gtk.Revealer user_lists_revealer;
  [GtkChild]
  private Gtk.Separator upper_separator;
  [GtkChild]
  private Gtk.ListBox new_list_box;

  public unowned MainWindow main_window { get; set; }
  public unowned Account account        { get; set; }
  private bool show_create_entry = true;


  construct {
    user_list_box.set_header_func (default_header_func);
    user_list_box.set_sort_func (ListListEntry.sort_func);
    subscribed_list_box.set_header_func (default_header_func);
    subscribed_list_box.set_sort_func (ListListEntry.sort_func);
  }

  public void hide_user_list_entry () {
    new_list_entry.hide ();
    new_list_entry.no_show_all = true;
    user_list_label.visible = true;
    //user_list_frame.margin_top = 24;
    show_create_entry = false;
    upper_separator.visible = false;
    upper_separator.no_show_all = true;
  }

  [GtkCallback]
  private void row_activated (Gtk.ListBoxRow row) {
    if (row is NewListEntry) {
      ((NewListEntry)row).reveal ();
    } else {
      var entry = (ListListEntry) row;
      var bundle = new Bundle ();
      bundle.put_int64 ("list_id", entry.id);
      bundle.put_string ("name", entry.name);
      bundle.put_bool ("user_list", entry.user_list);
      bundle.put_string ("description", entry.description);
      bundle.put_string ("creator", entry.creator_screen_name);
      bundle.put_int ("n_subscribers", entry.n_subscribers);
      bundle.put_int ("n_members", entry.n_members);
      bundle.put_int64 ("created_at", entry.created_at);
      bundle.put_string ("mode", entry.mode);
      main_window.main_widget.switch_page (Page.LIST_STATUSES, bundle);
    }
  }

  public async void load_lists (int64 user_id) { // {{{
    if (user_id == 0)
      user_id = account.id;

    var collect_obj = new Collect (2);

    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/subscriptions.json");
    call.set_method ("GET");
    call.add_param ("user_id", user_id.to_string ());
    TweetUtils.load_threaded.begin (call, null, (_, res) => {
      Json.Node? root = null;
      try {
        root = TweetUtils.load_threaded.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
      }

      uint n_subscribed_list = lists_received_cb (root, subscribed_list_box);
      if (n_subscribed_list == 0) {
        subscribed_list_box.hide ();
        subscribed_list_frame.hide ();
        subscribed_list_label.hide ();
      } else {
        subscribed_list_box.show ();
        subscribed_list_frame.show ();
        subscribed_list_label.show ();
      }
      collect_obj.emit ();
    });


    var user_call = account.proxy.new_call ();
    user_call.set_function ("1.1/lists/ownerships.json");
    user_call.set_method ("GET");
    user_call.add_param ("user_id", user_id.to_string ());
    TweetUtils.load_threaded.begin (user_call, null, (_, res) => {
      Json.Node? root = null;
      try {
        root = TweetUtils.load_threaded.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
      }

      uint n_user_list = lists_received_cb (root, user_list_box);
      if (n_user_list == 0 && !show_create_entry) {
        user_list_label.hide ();
        user_list_box.hide ();
        user_list_frame.hide ();
        user_list_frame.margin_top = 0;
      } else {
        user_list_label.visible = !show_create_entry;
        user_list_frame.margin_top = show_create_entry ? 24 : 0;
        user_list_box.show ();
        user_list_frame.show ();
        user_lists_revealer.reveal_child = n_user_list > 0;
      }
      collect_obj.emit ();
    });

    collect_obj.finished.connect (() => {
      load_lists.callback ();
    });

    yield;
  } // }}}

  private uint lists_received_cb (Json.Node?  root,
                                  Gtk.ListBox list_box)
  { // {{{
    if (root == null)
      return 0;

    var arr = root.get_object ().get_array_member ("lists");
    arr.foreach_element ((array, index, node) => {
      var obj = node.get_object ();
      var entry = new ListListEntry.from_json_data (obj, account);
      list_box.add (entry);
    });
    return arr.get_length ();
  } // }}}


  public void remove_list (int64 list_id) {
    uint n_user_lists = user_list_box.get_children ().length ();
    user_list_box.foreach ((w) => {
      if (!(w is ListListEntry))
        return;

      if (((ListListEntry)w).id == list_id) {
        user_list_box.remove (w);
        if (n_user_lists - 1 == 0)
          user_lists_revealer.reveal_child = false;
      }
    });

    subscribed_list_box.foreach ((w) => {
      if (!(w is ListListEntry))
        return;

      if (((ListListEntry)w).id == list_id) {
        subscribed_list_box.remove (w);
      }
    });

    if (subscribed_list_box.get_children ().length () == 0) {
      subscribed_list_label.hide ();
      subscribed_list_frame.hide ();
    }
  }

  public void add_list (ListListEntry entry) {
    if (entry.user_list) {
      // Avoid duplicates
      var user_lists = user_list_box.get_children ();
      foreach (Gtk.Widget w in user_lists) {
        if (!(w is ListListEntry))
          continue;

        if (((ListListEntry)w).id == entry.id)
          return;
      }
      user_list_box.add (entry);
      user_lists_revealer.reveal_child = true;
    } else {
      // Avoid duplicates
      var subscribed_lists = subscribed_list_box.get_children ();
      foreach (Gtk.Widget w in subscribed_lists) {
        if (!(w is ListListEntry))
          continue;

        if (((ListListEntry)w).id == entry.id)
          return;
      }
      subscribed_list_box.add (entry);
      subscribed_list_frame.show ();
      subscribed_list_box.show ();
      subscribed_list_label.show ();
    }
  }

  public void update_list (int64 list_id, string name, string description, string mode) {
    user_list_box.foreach ((w) => {
      if (!(w is ListListEntry))
        return;

      var lle = (ListListEntry) w;
      if (lle.id == list_id) {
        lle.name = name;
        lle.description = description;
        lle.mode = mode;
        lle.queue_draw ();
      }
    });
  }

  public void update_member_count (int64 list_id, int increase) {
    var lists = user_list_box.get_children ();
    foreach (var list in lists) {
      if (!(list is ListListEntry))
        continue;

      var lle = (ListListEntry) list;
      if (lle.id == list_id) {
        lle.n_members += increase;
        break;
      }
    }
  }

  public TwitterList[] get_user_lists () {
    GLib.List<weak Gtk.Widget> children = user_list_box.get_children ();
    TwitterList[] lists = new TwitterList[children.length ()];
    int i = 0;
    foreach (Gtk.Widget w in children) {
      assert (w is ListListEntry);
      var lle = (ListListEntry) w;
      lists[i].id = lle.id;
      lists[i].name = lle.name;
      lists[i].description = lle.description;
      lists[i].mode = lle.mode;
      lists[i].n_members = lle.n_members;
      i ++;
    }
    return lists;
  }

  public void clear_lists () {
    user_list_box.foreach ((w) => { user_list_box.remove (w);});
    subscribed_list_box.foreach ((w) => {subscribed_list_box.remove (w);});
  }

  [GtkCallback]
  private void new_list_create_activated_cb (string list_name) { // {{{
    if (list_name.strip ().length <= 0)
      return;

    new_list_entry.sensitive = false;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/create.json");
    call.set_method ("POST");
    call.add_param ("name", list_name);
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE, this.main_window);
        new_list_entry.sensitive = true;
        return;
      }
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }
      var root = parser.get_root ().get_object ();
      var entry = new ListListEntry.from_json_data (root, account);
      add_list (entry);

      var bundle = new Bundle ();
      bundle.put_int64 ("list_id", entry.id);
      bundle.put_string ("name", entry.name);
      bundle.put_bool ("user_list", true);
      bundle.put_string ("description", entry.description);
      bundle.put_string ("creator", entry.creator_screen_name);
      bundle.put_int ("n_subscribers", entry.n_subscribers);
      bundle.put_int ("n_members", entry.n_members);
      bundle.put_int64 ("created_at", entry.created_at);
      bundle.put_string ("mode", entry.mode);

      main_window.main_widget.switch_page (Page.LIST_STATUSES, bundle);
      new_list_entry.sensitive = true;
    });
  } // }}}

  public void unreveal () {
    new_list_entry.unreveal ();
  }

  [GtkCallback]
  private bool new_list_box_keynav_failed_cb (Gtk.DirectionType direction) {
    if (direction == Gtk.DirectionType.DOWN) {
      if (user_list_box.visible) {
        user_list_box.child_focus (direction);
        return Gdk.EVENT_STOP;
      } else if (subscribed_list_box.visible) {
        subscribed_list_box.child_focus (direction);
        return Gdk.EVENT_STOP;
      }
    }
    return Gdk.EVENT_PROPAGATE;
  }

  [GtkCallback]
  private bool user_list_box_keynav_failed_cb (Gtk.DirectionType direction) {
    if (direction == Gtk.DirectionType.UP) {
      if (new_list_box.visible) {
        new_list_box.child_focus (direction);
        return Gdk.EVENT_STOP;
      }
    } else if (direction == Gtk.DirectionType.DOWN) {
      if (subscribed_list_box.visible) {
        subscribed_list_box.child_focus (direction);
        return Gdk.EVENT_STOP;
      }
    }
    return Gdk.EVENT_PROPAGATE;
  }

  [GtkCallback]
  private bool subscribed_list_box_keynav_failed_cb (Gtk.DirectionType direction) {
    if (direction == Gtk.DirectionType.UP) {
      if (user_list_box.visible) {
        user_list_box.child_focus (direction);
        return Gdk.EVENT_STOP;
      } else if (new_list_box.visible) {
        new_list_box.child_focus (direction);
        return Gdk.EVENT_STOP;
      }
    }
    return Gdk.EVENT_PROPAGATE;
  }

  [GtkCallback]
  private void revealer_child_revealed_cb (GLib.Object source, GLib.ParamSpec spec) {
    Gtk.Revealer revealer = (Gtk.Revealer) source;
    if (revealer.child_revealed)
      revealer.show ();
    else
      revealer.hide ();
  }
}
