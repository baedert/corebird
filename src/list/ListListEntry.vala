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

  public int64 id;
  public bool user_list = false;
  public string creator_screen_name;
  public int n_subscribers;
  public int n_members = 0;
}
