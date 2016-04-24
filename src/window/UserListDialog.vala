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


struct TwitterList {
  int64 id;
  string name;
  string description;
  string mode;
  uint n_members;
}



class UserListDialog : Gtk.Dialog {
  private unowned Account account;
  private unowned MainWindow main_window;
  private Gtk.ListBox list_list_box = new Gtk.ListBox ();
  private Gtk.Label placeholder_label = new Gtk.Label ("");
  private int64 user_id;

  public UserListDialog (MainWindow parent,
                         Account    account,
                         int64      user_id) {
    GLib.Object (use_header_bar: Gtk.Settings.get_default ().gtk_dialogs_use_header ? 1 : 0);
    this.title = _("Add to or Remove User From List");
    this.main_window = parent;
    this.user_id = user_id;
    this.account = account;
    set_modal (true);
    set_transient_for (parent);
    set_default_size (250, 200);
    add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
    add_button (_("Save"), Gtk.ResponseType.OK);

    set_default_response (Gtk.ResponseType.OK);


    var content_box = get_content_area ();
    content_box.border_width = 0;
    var scroller = new Gtk.ScrolledWindow (null, null);
    list_list_box.selection_mode = Gtk.SelectionMode.NONE;
    list_list_box.row_activated.connect ((row) => {
      if (!(row is ListUserEntry)) {
        warning ("Row != ListUserEntry!");
        return;
      }
      ((ListUserEntry)row).toggle ();
    });
    scroller.add (list_list_box);
    content_box.pack_start (scroller, true, true);


    placeholder_label.label = _("You have no lists.");
    placeholder_label.get_style_context ().add_class ("dim-label");
    placeholder_label.show ();
    list_list_box.set_placeholder (placeholder_label);
    this.set_default_size (400, 200);
  }

  public void load_lists () {
    var lists_page = (ListsPage)main_window.get_page (Page.LISTS);
    lists_page.get_user_lists.begin ((obj, res) => {
      TwitterList[] lists = lists_page.get_user_lists.end (res);
      foreach (unowned TwitterList list in lists) {
        var l = new ListUserEntry (list.name, list.description);
        l.id = list.id;
        if (list.n_members >= 500)
          l.disable ();
        list_list_box.add (l);
      }
      this.show_all ();
    });

    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/memberships.json");
    call.add_param ("user_id", user_id.to_string ());
    call.add_param ("filter_to_owned_lists", "true");
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE, this);
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
      var list_arr = root.get_array_member ("lists");
      list_arr.foreach_element ((arr, index, node) => {
        int64 id = node.get_object ().get_int_member ("id");
        list_list_box.@foreach ((w) => {
          var lue = (ListUserEntry) w;
          if (lue.id == id) {
            lue.check ();
            lue.enable ();
          }
        });
      });
    });
  }


  public override void response (int response_id) {
    if (response_id == Gtk.ResponseType.CANCEL) {
      this.destroy ();
    } else if (response_id == Gtk.ResponseType.OK) {
      var list_entries = list_list_box.get_children ();
      foreach (Gtk.Widget w in list_entries) {
        var lue = (ListUserEntry) w;
        if (lue.changed) {
          debug ("VALUE CHANGED");
          if (lue.active) {
            // Add user to the list
            add_user (lue.id);
          } else {
            // Remove user from the list
            remove_user (lue.id);
          }
        }
      }
      this.destroy ();
    }
  }

  private void add_user (int64 list_id) {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/members/create.json");
    call.set_method ("POST");
    call.add_param ("list_id", list_id.to_string ());
    call.add_param ("user_id", user_id.to_string ());
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE, this);
      }
    });
  }

  private void remove_user (int64 list_id) {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/members/destroy.json");
    call.set_method ("POST");
    call.add_param ("list_id", list_id.to_string ());
    call.add_param ("user_id", user_id.to_string ());
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE, this);
      }
    });
  }
}



class ListUserEntry : Gtk.ListBoxRow {
  public int64 id;
  public new bool changed = false;
  private Gtk.CheckButton added_checkbox = new Gtk.CheckButton ();
  public bool active {
    get {
      return added_checkbox.active;
    }
  }

  public ListUserEntry (string list_name, string description) {
    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
    box.margin = 6;
    added_checkbox.valign = Gtk.Align.CENTER;
    added_checkbox.margin_start = 6;
    box.pack_start (added_checkbox, false, false);
    var box2 = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
    var label = new Gtk.Label ("<b>" + list_name + "</b>");
    label.use_markup = true;
    label.halign = Gtk.Align.START;
    box2.pack_start (label, true, false);
    var desc_label = new Gtk.Label (description);
    desc_label.get_style_context ().add_class ("dim-label");
    desc_label.halign = Gtk.Align.START;
    desc_label.ellipsize = Pango.EllipsizeMode.END;
    box2.pack_start (desc_label, true, false);
    box.pack_start (box2, true, true);
    add (box);
    added_checkbox.toggled.connect (() => {
      changed = !changed;
    });
  }

  public void check () {
    added_checkbox.active = true;
    changed = false;
  }

  public void toggle () {
    added_checkbox.active = !added_checkbox.active;
  }

  public void disable () {
    this.added_checkbox.sensitive = false;
  }

  public void enable () {
    this.added_checkbox.sensitive = true;
  }
}

