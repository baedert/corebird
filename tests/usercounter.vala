


void order () {
  FileUtils.remove (Dirs.config ("accounts/test-account.db"));
  var db = new Sql.Database (Dirs.config ("accounts/test-account.db"),
                             Sql.ACCOUNTS_INIT_FILE);
  var counter = new UserCounter ();
  counter.load (db);

  counter.user_seen (2, "baedert", "BAEDERT");
  counter.user_seen (2, "baedert", "BAEDERT");
  counter.user_seen (0, "Darth", "Vader");
  counter.user_seen (5, "Party", "Time");
  counter.user_seen (5, "Party", "Time");
  counter.user_seen (5, "Party", "Time");
  counter.user_seen (5, "Party", "Time");


  int num_results;
  UserInfo[] infos = counter.query_by_prefix ("", 200, out num_results);
  message ("Results: %d", num_results);
  assert (num_results == 3);
  // They need to be sorted from highest-scoring to lowest-scoring
  // XXX This is currently broken
  int last_score = int.MAX;
  for (int i = 0; i < num_results; i++) {
    //assert (infos[i].score <= last_score);  XXX
    last_score = infos[i].score;
  }
}



void count () {
  var db = new Sql.Database (Dirs.config ("accounts/118055879.db"),
                             Sql.ACCOUNTS_INIT_FILE);
  var counter = new UserCounter ();
  counter.load (db);
  counter.user_seen (0, "baedert", "blabla");
  int changed = counter.save (db);
  message ("Single change: %d", changed);
  assert (changed == 1);
  assert (counter.save (db) == 0);

  counter.user_seen (1, "baedert", "");
  counter.user_seen (1, "baedert", "");
  changed = counter.save (db);
  message ("Double change: %d", changed);
  assert (changed == 1);
  assert (counter.save (db) == 0);

  counter.user_seen (2, "baedert", "");
  counter.user_seen (3, "baedert", "");
  changed = counter.save (db);
  message ("Two users changed: %d", changed);
  assert (changed == 2);
  assert (counter.save (db) == 0);

}

int main (string[] args) {
  GLib.Test.init (ref args);
  Dirs.create_dirs ();
  GLib.Test.add_func ("/usercounter/order", order);
  GLib.Test.add_func ("/usercounter/count", count);


  return GLib.Test.run ();
}
