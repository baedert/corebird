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

using Gtk;

class ProgressEntry : ListBoxRow, ITwitterItem {
  public int64 sort_factor{
    get{ return 0;}
  }
  public bool seen{get; set; default = true;}
  private Spinner spinner     = new Spinner();

  public ProgressEntry(int size = 25){
    this.get_style_context().add_class("progress-item");
    this.border_width = 5;
    spinner.set_size_request(size, size);
    this.set_size_request(size, size);
    this.add (spinner);
    spinner.start ();
  }

  public int update_time_delta (GLib.DateTime? now = null) {return 0;}
}
