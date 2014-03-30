





// XXX This only works for my account ID
void order () {
  var db = new Sql.Database (Dirs.config ("accounts/118055879.db"),
                             Sql.ACCOUNTS_INIT_FILE);
  var counter = new UserCounter ();
  counter.load (db);

  int num_results;
  UserInfo[] infos = counter.query_by_prefix ("", 200, out num_results);
  message ("Results: %d", num_results);

  // They need to be sorted from highest-scoring to lowest-scoring
  int last_score = int.MAX;
  for (int i = 0; i < num_results; i++) {
    assert (infos[i].score <= last_score);
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
  GLib.Test.add_func ("/usercounter/order", order);
  GLib.Test.add_func ("/usercounter/count", count);


  return GLib.Test.run ();
}
