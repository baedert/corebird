


namespace Sql {
  public const string COREBIRD_INIT_FILE = DATADIR + "/sql/init/Create.%d.sql";
  public const string ACCOUNTS_INIT_FILE = DATADIR + "/sql/accounts/Create.%d.sql";

  public const int STOP     = -1;
  public const int CONTINUE = 0;

class Database {
  private Sqlite.Database db;


  public Database (string filename, string? init_file = null) {
    Sqlite.Database.open (filename, out db);
    if (init_file == null)
      return;

    int user_version = -1;
    this.exec ("pragma user_version;", (n_cols, vals) => {user_version = int.parse(vals[0]); return STOP;});
    var next_version_file = init_file.printf(user_version + 1);
    if (FileUtils.test (next_version_file, FileTest.EXISTS)) {
      string sql_content;
      try {
      FileUtils.get_contents (next_version_file, out sql_content);
      } catch (GLib.FileError e) {
        critical (e.message);
        return;
      }
      db.exec (sql_content);
      message ("Executed init file %s", next_version_file);
    }
  }

  public int64 exec_insert (string sql) {
    db.exec (sql);
    return db.last_insert_rowid ();
  }

  public void exec (string sql, Sqlite.Callback? callback = null) {
    db.exec (sql, callback);
  }

}
}
