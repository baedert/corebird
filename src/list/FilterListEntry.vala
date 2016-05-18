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
[GtkTemplate (ui = "/org/baedert/corebird/ui/filter-list-entry.ui")]
class FilterListEntry : Gtk.ListBoxRow {
  [GtkChild]
  private Gtk.Label content_label;
  [GtkChild]
  private Gtk.Revealer revealer;
  [GtkChild]
  private Gtk.Stack stack;
  [GtkChild]
  private Gtk.Grid normal_box;
  [GtkChild]
  private Gtk.Box delete_box;

  private unowned Filter _filter;
  public unowned Filter filter {
    set {
      content_label.label = value.content;
      _filter = value;
    }
    get {
      return _filter;
    }
  }
  public string content {
    set {
      content_label.label = value;
    }
    get {
      return content_label.label;
    }
  }
  private unowned Account account;
  private unowned MainWindow main_window;
  public signal void removed (Filter f);

  public FilterListEntry (Filter     f,
                          Account    account,
                          MainWindow main_window) {
    this.filter = f;
    this.account = account;
    this.main_window = main_window;
  }

  construct {
    revealer.notify["child-revealed"].connect (() => {
      if (!revealer.child_revealed) {
        ((Gtk.Container)this.get_parent ()).remove (this);
      }
    });
  }

  [GtkCallback]
  private void menu_button_clicked_cb () {
    stack.visible_child = delete_box;
    this.activatable = false;
  }

  [GtkCallback]
  private void cancel_button_clicked_cb () {
    stack.visible_child = normal_box;
    this.activatable = true;
  }

  [GtkCallback]
  private void delete_button_clicked_cb () {
    for (int i = 0; i < account.filters.length; i ++) {
      var f = account.filters.get (i);
      if (f.id == this.filter.id) {
        account.filters.remove (f);
        account.db.exec ("DELETE FROM `filters` WHERE `id`='%d'".printf (f.id));
        //removed (f);
        revealer.reveal_child = false;
        main_window.rerun_filters ();
        return;
      }
    }
  }

}
