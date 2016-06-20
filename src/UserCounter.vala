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
*/

public class UserInfo : GLib.Object {
  public int64 id;
  public string screen_name;
  public string name;
  public int score;
  public bool changed;
}


public class UserCounter : GLib.Object {
  private bool changed = false;
  private GLib.GenericArray<UserInfo?> names = new GLib.GenericArray<UserInfo?> ();

  public UserCounter () {}

  public void id_seen (ref Cb.UserIdentity id) {
    this.user_seen (id.id, id.screen_name, id.user_name);
  }

  public void user_seen (int64 id, string screen_name, string name) {
    // increase the user's seen-count by one
    bool found = false;
    this.changed = true;
    for (int i = 0; i < names.length; i ++) {
      var ui = names.get (i);
      if (ui.id == id) {
        found = true;
        ui.score ++;
        //debug ("New score: %d", ui.score);
        ui.changed = true;
        break;
      }
    }

    if (!found) {
      UserInfo ui = new UserInfo ();
      ui.id = id;
      ui.screen_name = screen_name;
      ui.name = name;
      ui.changed = true;
      ui.score = 1;
      names.add(ui);
    }
  }

  public UserInfo[] query_by_prefix (string prefix, int max_results, out int num_results) {
    int n_results = 0;
    string p = prefix.down ();
    UserInfo[] results = new UserInfo[max_results];
    for (int i = 0; i < names.length; i ++) {
      var ui = names.get (i);
      if (n_results >= max_results)
        break;

      if (ui.name.down ().has_prefix (p) || ui.screen_name.down ().has_prefix (p)) {
        results[n_results] = ui;
        n_results ++;
      }
    }
    num_results = n_results;
    return results;
  }

  public void load (Sql.Database db) {
    db.select ("user_cache")
      .cols ("id", "screen_name", "user_name", "score")
      .order ("score DESC")
      .limit (300)
      .run ((vals) => {
      UserInfo ui = new UserInfo ();
      ui.id = int64.parse (vals[0]);
      ui.screen_name = vals[1];
      ui.name = vals[2];
      ui.changed = false;
      ui.score = int.parse (vals[3]);
      names.add (ui);
      return true;
    });
  }

  /**
   * Saves all the changed user counts into the database.
   *
   * @return The number of changes users.
   */
  public int save (Sql.Database db) {
    if (!changed)
      return 0;

    int saved = 0;
    db.begin_transaction ();
    for (int i = 0; i < names.length; i ++) {
      var ui = names.get (i);
      if (!ui.changed)
        continue;
      ui.changed = false;
      db.replace ("user_cache").vali64 ("id", ui.id)
                               .vali ("score", ui.score)
                               .val ("screen_name", ui.screen_name)
                               .val ("user_name", ui.name)
                               .run();
      saved ++;
    }
    db.end_transaction ();
    changed = false;
    return saved;
  }

}
