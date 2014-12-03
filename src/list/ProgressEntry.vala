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

public class ProgressEntry : Gtk.ListBoxRow, ITwitterItem {
  public int64 sort_factor {
    get { return 0; }
  }
  public bool seen {
    get { return true; }
    set {}
  }


  public ProgressEntry () {
    this.activatable = false;
    Gtk.Spinner spinner = new Gtk.Spinner ();
    Gtk.Label l = new Gtk.Label (_("Loading more data..."));
    Gtk.Box box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);

    l.set_halign (Gtk.Align.START);
    l.hexpand = true;

    spinner.set_size_request (16, 16);
    spinner.set_halign (Gtk.Align.END);
    spinner.set_valign (Gtk.Align.CENTER);
    spinner.margin_top = 12;
    spinner.margin_bottom = 12;
    spinner.hexpand = true;
    spinner.start ();
    box.pack_start (spinner, true, true);
    box.pack_start (l, true, true);
    this.add (box);
  }

  public int update_time_delta (GLib.DateTime? now = null) {
    return 0;
  }
}
