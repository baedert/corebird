void count () {
  FileUtils.remove (Dirs.config ("accounts/test-account.db"));
  var db = new Sql.Database (Dirs.config ("accounts/test-account.db"),
                             Sql.ACCOUNTS_INIT_FILE,
                             Sql.ACCOUNTS_SQL_VERSION);
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
  GLib.Test.add_func ("/usercounter/count", count);


  return GLib.Test.run ();
}
