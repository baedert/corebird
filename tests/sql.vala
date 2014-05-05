

const string DB = "./_test.db";

void normal () {
  GLib.FileUtils.remove(DB);
  var db = new Sql.Database (DB, "./sql_init%d.sql");
  int user_version = 0;
  db.exec ("pragma user_version;", (n_cols, vals) => {
    user_version = int.parse(vals[0]);
    return Sql.STOP;
  });
  // sql_init1.sql sets user_version to 1
  message ("User version after sql_init1.sql: %d", user_version);
  assert (user_version == 1);
}

void init_file_gap () {
  GLib.FileUtils.remove(DB);
  var db = new Sql.Database (DB, "./_sql_init%d.sql");
  int user_version = 0;
  db.exec ("pragma user_version;", (n_cols, vals) => {
    user_version = int.parse(vals[0]);
    return Sql.STOP;
  });
  // user_version should be 1 (from _sql_init1.sql), not 3 (from _sql_init3.sql).
  message ("User version after _sql_init1.sql: %d", user_version);
  assert (user_version == 1);
}

void consecutive_init_files () {
  GLib.FileUtils.remove(DB);
  var db = new Sql.Database (DB, "./__sql_init%d.sql");
  int user_version = 0;
  db.exec ("pragma user_version;", (n_cols, vals) => {
    user_version = int.parse(vals[0]);
    return Sql.STOP;
  });
  // user_version should be 1 (from _sql_init1.sql), not 3 (from _sql_init3.sql).
  message ("User version after_ _sql_init1.sql/2: %d", user_version);
  assert (user_version == 2);
}



int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/sql/normal", normal);
  GLib.Test.add_func ("/sql/init-file-gap", init_file_gap);
  GLib.Test.add_func ("/sql/consecutive-init-files", consecutive_init_files);

  return GLib.Test.run ();
}
