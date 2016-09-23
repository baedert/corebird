void count () {
  FileUtils.remove (Dirs.config ("accounts/test-account.db"));
  var db = new Sql.Database (Dirs.config ("accounts/test-account.db"),
                             Sql.ACCOUNTS_INIT_FILE,
                             Sql.ACCOUNTS_SQL_VERSION);
  var counter = new UserCounter ();
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

void query_after_save () {
  FileUtils.remove (Dirs.config ("accounts/test-account.db"));
  var db = new Sql.Database (Dirs.config ("accounts/test-account.db"),
                             Sql.ACCOUNTS_INIT_FILE,
                             Sql.ACCOUNTS_SQL_VERSION);
  var counter = new UserCounter ();
  counter.user_seen (10, "baedert", "foobar");
  counter.user_seen (20, "baedert2", "foobar2");
  counter.save (db);

  int n_results;
  UserInfo[] infos = counter.query_by_prefix (db, "b", 10, out n_results);
  assert (n_results == 2);
  assert (infos[0].screen_name == "baedert");
  assert (infos[1].screen_name == "baedert2");
}

void query_no_save () {
  FileUtils.remove (Dirs.config ("accounts/test-account.db"));
  var db = new Sql.Database (Dirs.config ("accounts/test-account.db"),
                             Sql.ACCOUNTS_INIT_FILE,
                             Sql.ACCOUNTS_SQL_VERSION);
  var counter = new UserCounter ();
  counter.user_seen (10, "baedert", "foobar");
  counter.user_seen (10, "baedert", "foobar"); // See this one twice so the order makes sense
  counter.user_seen (20, "baedert2", "foobar2");

  int n_results;
  UserInfo[] infos = counter.query_by_prefix (db, "b", 10, out n_results);
  assert (n_results == 2);
  assert (infos[0].screen_name == "baedert");
  assert (infos[1].screen_name == "baedert2");
}

void query_mixed () {
  FileUtils.remove (Dirs.config ("accounts/test-account.db"));
  var db = new Sql.Database (Dirs.config ("accounts/test-account.db"),
                             Sql.ACCOUNTS_INIT_FILE,
                             Sql.ACCOUNTS_SQL_VERSION);
  var counter = new UserCounter ();
  counter.user_seen (10, "baedert", "foobar");
  counter.user_seen (10, "baedert", "foobar");
  counter.user_seen (10, "baedert", "foobar");
  counter.user_seen (10, "baedert", "foobar");
  counter.user_seen (20, "baedert2", "foobar2");
  counter.save (db);

  /* Make sure nothing's in memory anymore */
  db = new Sql.Database (Dirs.config ("accounts/test-account.db"),
                         Sql.ACCOUNTS_INIT_FILE,
                         Sql.ACCOUNTS_SQL_VERSION);
  counter = new UserCounter ();
  counter.user_seen (11, "b_", "__");
  counter.user_seen (11, "b_", "__");
  counter.user_seen (11, "b_", "__");
  counter.user_seen (12, "ba", "bb");
  counter.user_seen (12, "ba", "bb");

  int n_results;
  UserInfo[] infos = counter.query_by_prefix (db, "b", 10, out n_results);
  assert (n_results == 4);
  assert (infos[0].id == 10);
  assert (infos[1].id == 11);
  assert (infos[2].id == 12);
  assert (infos[3].id == 20);
}

int main (string[] args) {
  GLib.Test.init (ref args);
  Dirs.create_dirs ();
  GLib.Test.add_func ("/usercounter/count", count);
  GLib.Test.add_func ("/usercounter/query-after-save", query_after_save);
  GLib.Test.add_func ("/usercounter/query-no-save", query_no_save);
  GLib.Test.add_func ("/usercounter/query-mixed", query_mixed);

  return GLib.Test.run ();
}
