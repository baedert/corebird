


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
      FileUtils.get_contents (next_version_file, out sql_content);
      db.exec (sql_content);
      message ("Executed init file %s", next_version_file);
    }
  }

  public int64 exec_insert (string sql) {
    db.exec(sql);
    return db.last_insert_rowid ();
  }

  public void exec (string sql, Sqlite.Callback? callback = null) {
    db.exec(sql, callback);
  }

/*  public void insert (string table_name, string first_col, string first_value, ...) {
    var builder = new StringBuilder ("INSERT INTO `");
    builder.append (table_name).append ("` (");
    string q = "INSERT INTO `"+table_name+"` (";
    GLib.List<string> items = new GLib.List<string> ();
    var list = va_list();
    int size = 0;
    for (string? s = list.arg<string>(); s != null; s = list.arg<string>()) {
      items.append (s);
      size++;
    }
    if (size % 2 != 0) {
      critical ("Parameter count is no multiple of 2");
      return;
    }

    int col_count = size / 2;
    int pos = 0;
    unowned GLib.List<string> foo = items;
    while (pos < col_count) {
      q += "`" + items.data + "`";
      foo = foo.next;
      pos++;
    }
    q += ")";

    message(q);
  }*/
}


}
