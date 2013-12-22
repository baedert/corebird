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
    add_button ("Cancel", CANCEL_RESPONSE);
    add_button ("Save", SAVE_RESPONSE);


    var content_box = get_content_area ();
    var scroller = new Gtk.ScrolledWindow (null, null);
    scroller.add (list_list_box);
    content_box.pack_start (scroller, true, true);
  }

  public void load_lists () {
    var lists_page = (ListsPage)main_window.get_page (MainWindow.PAGE_LISTS);
    lists_page.get_user_lists.begin ((obj, res) => {
      TwitterList[] lists = lists_page.get_user_lists.end (res);
      foreach (var list in lists) {
        var l = new Gtk.Label (list.name);
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
