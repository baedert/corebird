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
  private Gtk.Button delete_button;
  public string content {
    set {
      content_label.label = value;
    }
    get {
      return content_label.label;
    }
  }
  public int block_count = 0;

  public FilterListEntry () {}

  [GtkCallback]
  private void delete_button_clicked_cb () {
    message ("Close pressed!");
  }
}
