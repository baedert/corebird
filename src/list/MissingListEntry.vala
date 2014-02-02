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


[GtkTemplate (ui = "/org/baedert/corebird/ui/missing-list-entry.ui")]
class MissingListEntry : Gtk.ListBoxRow, ITwitterItem {
  public bool seen {get; set; default = true;}
  public int64 id;
  public int64 sort_factor {
    get { return id; }
  }
  [GtkChild]
  private Gtk.Stack stack;


  public MissingListEntry (int64 id) {
    this.id = id;
  }



  public void set_resumed () {
    stack.visible_child_name = "resumed";
  }

  public void set_interrupted () {
    stack.visible_child_name = "interrupted";
  }

  public int update_time_delta (GLib.DateTime? now = null) {return 0;}
}
