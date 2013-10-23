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
  We then save the first 200 or so results and load them on startup.
  If the user types a name and no result is found, we try to search
  for that name via Twitter's search API.

 XXX: Check if this works well with sqlite, if not move to a simple text file.
*/

struct UserInfo {
  int64 id;
  string screen_name;
  string name;
}


uint char_hash_func (char c) {
  return (uint) c;
}

bool char_equal_func (char a, char b) {
  return a == b;
}

bool user_info_equal_func (UserInfo a, UserInfo b) {
    return a.id == b.id;
}

class UserCounter : GLib.Object {
  private string filename;
  private Gee.HashMap<char, Gee.ArrayList<UserInfo?>> name_list = new Gee.HashMap<char,
                                                                      Gee.ArrayList<UserInfo?>>
                                                              (char_hash_func, char_equal_func);
  private bool changed = false;

  public UserCounter () {
  }

  public void user_seen (string name) {
    // increase the user's seen-count by one
  }


  public string[] query_by_prefix (string prefix, int max_results = -1) {
    return null;
  }

  public void load (Sql.Database db) {
    db.select ("user_cache").cols ("id", "screen_name", "name", "score").order ("score").run ((vals) => {
      UserInfo ui = {int64.parse(vals[0]), vals[1], vals[2]};
      return true;
    });
  }

  public void save () {
    if (!changed)
      return;
  }

}
