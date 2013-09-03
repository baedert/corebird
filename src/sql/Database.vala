


namespace Sql {
  public const string COREBIRD_INIT_FILE = DATADIR + "";
  public const string ACCOUNT_INIT_FILE  = DATADIR + "";

class Database {
  private Sqlite.Database db;


  public Database (string filename, string? init_file = null) {
    Sqlite.Database.open (filename, out db);
    if (init_file != null) {
      // TODO: Load file, execute query
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
