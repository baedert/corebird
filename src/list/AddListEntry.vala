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
class AddListEntry : Gtk.ListBoxRow {
  public AddListEntry (string label) {
    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
    var img = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DIALOG);
    img.pixel_size = 32;
    img.margin_start = 10;
    img.hexpand = true;
    img.halign = Gtk.Align.END;
    box.pack_start (img);
    var l = new Gtk.Label (label);
    l.hexpand = true;
    l.halign = Gtk.Align.START;
    box.pack_start (l);
    box.margin_bottom = 4;
    box.margin_top = 4;
    add (box);
  }
}
