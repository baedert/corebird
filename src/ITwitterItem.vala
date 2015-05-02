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

public interface ITwitterItem : Gtk.Widget {
 public static int sort_func (Gtk.ListBoxRow a, Gtk.ListBoxRow b) {
    if(((ITwitterItem)a).sort_factor < ((ITwitterItem)b).sort_factor)
      return 1;
    return -1;
  }

  public static int sort_func_inv (Gtk.ListBoxRow a, Gtk.ListBoxRow b) {
    if(((ITwitterItem)a).sort_factor < ((ITwitterItem)b).sort_factor)
      return -1;
    return 1;
  }
  public abstract int64 sort_factor { get;      }

  /**
   * Updates the time delta label found in various ITwitterItem subclasses.
   *
   * @param now The current time.
   *
   * @return The seconds between the creation time and now.
   */
  public abstract int update_time_delta (GLib.DateTime? now = null);
}
