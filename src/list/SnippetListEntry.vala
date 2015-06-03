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

class SnippetListEntry : Gtk.ListBoxRow {
  private Gtk.Label key_label;
  private Gtk.Label value_label;
  public string key {
    get {
      return key_label.label;
    }
    set {
      key_label.label = value;
    }
  }
  public string value {
    get {
      return value_label.label;
    }
    set {
      value_label.label = value;
    }
  }

  public SnippetListEntry (string key, string value) {
    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    box.homogeneous = true;
    box.margin = 6;

    key_label = new Gtk.Label (key);
    key_label.halign = Gtk.Align.START;
    box.add (key_label);

    value_label = new Gtk.Label (value);
    value_label.halign = Gtk.Align.START;
    value_label.ellipsize = Pango.EllipsizeMode.END;
    box.add (value_label);


    this.add (box);
  }
}
