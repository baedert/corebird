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
  string name;
  string description;
  string mode;
}



class UserListDialog : Gtk.Dialog {
  private static const int SAVE_RESPONSE   = 2;
  private static const int CANCEL_RESPONSE = -1;
  private unowned Account account;
  private unowned MainWindow main_window;
  private Gtk.ListBox list_list_box = new Gtk.ListBox ();

  public UserListDialog (MainWindow parent, Account account) {
    this.main_window = parent;
    set_modal (true);
    set_transient_for (parent);
    set_default_size (250, 300);
    add_button ("Cancel", CANCEL_RESPONSE);
    add_button ("Save", SAVE_RESPONSE);


    var content_box = get_content_area ();
    var scroller = new Gtk.ScrolledWindow (null, null);
    list_list_box.selection_mode = Gtk.SelectionMode.NONE;
    scroller.add (list_list_box);
    content_box.pack_start (scroller, true, true);
  }

  public void load_lists () {
    var lists_page = (ListsPage)main_window.get_page (MainWindow.PAGE_LISTS);
    lists_page.get_user_lists.begin ((obj, res) => {
      TwitterList[] lists = lists_page.get_user_lists.end (res);
      foreach (var list in lists) {
        var l = new ListUserEntry (list.name, list.description);
        list_list_box.add (l);
      }
     this.show_all ();
    });
  }


  public override void response (int response_id) {
    if (response_id == CANCEL_RESPONSE) {
      this.destroy ();
    } else if (response_id == SAVE_RESPONSE) {
      this.destroy ();
    }
  }
}

class ListUserEntry : Gtk.ListBoxRow {
  private Gtk.CheckButton added_checkbox = new Gtk.CheckButton ();

  public ListUserEntry (string list_name, string description) {
    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
    box.pack_start (added_checkbox, false, false);
    var box2 = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
    var label = new Gtk.Label (list_name);
    label.justify = Gtk.Justification.LEFT;
    label.get_style_context ().add_class ("list-username");
    box2.pack_start (label, true, false);
    var desc_label = new Gtk.Label (description);
    desc_label.get_style_context ().add_class ("dim-label");
    desc_label.justify = Gtk.Justification.LEFT;
    desc_label.ellipsize = Pango.EllipsizeMode.END;
    box2.pack_start (desc_label, true, false);
    box.pack_start (box2, true, true);
    add (box);
  }
}

