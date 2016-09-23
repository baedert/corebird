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

  public UserInfo[] query_by_prefix (Sql.Database db, string prefix, int max_results, out int num_results) {
    var b = Benchmark.start ("query_by_prefix(%s)".printf (prefix));
    GLib.GenericArray<UserInfo> infos = new GLib.GenericArray<UserInfo> ();
    int n_results = 0;
    int highscore = 0;
    int lowscore  = int.MAX;

    db.select ("user_cache")
      .cols ("id", "screen_name", "user_name", "score")
      .where_prefix ("screen_name", prefix)
      .or ()
      .where_prefix2 ("user_name", prefix)
      .order ("score DESC")
      .limit (max_results)
      .nocase()
      .run ((vals) => {

      int score = int.parse (vals[3]);
      var ui = new UserInfo ();
      ui.id = int64.parse(vals[0]);
      ui.screen_name = vals[1];
      ui.name = vals[2];
      ui.score = score;

      infos.add (ui);

      highscore = int.max (highscore, score);
      lowscore  = int.min (lowscore, score);

      n_results ++;
      return true;
    });
    if (n_results == 0) {
      lowscore = -1;
    }

    /* So we have all possible results from the DB, now
       now we just need to mix those with the local ones */
    for (uint i = 0; i < names.length; i ++) {
      var ui = this.names.get (i);
      bool full = infos.length >= max_results;
      if (full && ui.score < lowscore)
        continue;

      if (ui.name.down().has_prefix (prefix) ||
          ui.screen_name.down().has_prefix (prefix)) {
        infos.add (ui);
      }
    }

    // Sort it after score
    infos.sort ((a,b) => { if (a.score < b.score) return 1; return -1; });

    UserInfo[] results = new UserInfo[int.min (max_results, infos.length)];
    for (int i = 0; i < results.length; i ++) {
      results[i] = infos.get (i);
    }
    num_results = results.length;

    b.stop ();
    return results;
  }

  /**
   * Saves all the changed user counts into the database.
   *
   * @return The number of changes users.
   */
  public int save (Sql.Database db) {
    if (!changed)
      return 0;

    var b = Benchmark.start ("save");

    debug ("Saving %d user infos", names.length);
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
    this.names.remove_range (0, this.names.length);

    b.stop ();
    return saved;
  }

}
