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


/*
  So, this is the plan:
  we wil just save every single time the user encounters another user.
  We then save the first 500 or so results and load them on startup.
  If the user types a name and no result is found, we try to search
  for that name via Twitter's search API.
*/

struct UserInfo {
  int64 id;
  string screen_name;
  string name;
}


class UserCounter : GLib.Object {
  private string filename;

  public UserCounter (string filename) {
    this.filename = filename;
  }

  public void user_seen (string name) {
    // increase the user's seen-count by one
  }


  public string[] query_by_prefix (string prefix, int max_results = -1) {

  }

  public void load () {
    var in_stream = new DataInputStream (new FileInputStream (filename));
    string line;
    while ((line = in_stream.read_line) != null) {
      string[] splits = line.split(",");
      if (splits.length != 3) {
        warning ("'%s' is not a valid line", line);
        continue;
      }
    }
  }

  public void save () {
  }

}
