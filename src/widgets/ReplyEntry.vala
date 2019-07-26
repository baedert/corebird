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

class ReplyEntry : Gtk.Entry {
  [Signal (action = true)]
  public signal void cancelled ();




  public ReplyEntry () {}

  static construct {
    warning ("reply entry doesn't work.");
    //unowned Gtk.BindingSet binding_set = Gtk.BindingSet.by_class ((GLib.ObjectClass)typeof (ReplyEntry).class_ref ());

    //Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.Escape, 0, "cancelled", 0, null);
  }
}
