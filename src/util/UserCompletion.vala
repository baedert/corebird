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

class UserCompletion : GLib.Object {
  public signal void start_completion ();
  public signal void populate_completion (string name, string screen_name);
  private unowned GLib.Object obj;
  private unowned Account account;
  private string name_property_name;
  private int num_results;

  public UserCompletion (Account account, int num_results) {
    this.account = account;
    this.num_results = num_results;
  }

  public void connect_to (GLib.Object obj, string name_property_name) {
    this.obj = obj;
    this.name_property_name = name_property_name;
    obj.notify[name_property_name].connect (prop_changed);
  }

  private void prop_changed () {
    string name;
    obj.get (name_property_name, out name);
    if (name.has_prefix ("@"))
      name = name.substring (1);
    start_completion ();
    int n_results;
    UserInfo[] names = account.user_counter.query_by_prefix (name, 10, out n_results);


    for (int i = 0; i < n_results; i++)
      populate_completion (names[i].screen_name, names[i].name);
  }
}
