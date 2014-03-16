





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
    message ("last: %d, this: %d", last_score, infos[i].score);
    assert (infos[i].score <= last_score);
    last_score = infos[i].score;
  }
}



int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/usercounter/order", order);


  return GLib.Test.run ();
}
