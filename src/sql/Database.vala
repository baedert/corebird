


namespace Sql {

class Database {
  private Sqlite.Database db;


  public Database (string filename) {
    Sqlite.Database.open (filename, out db);
  }

  public void insert (string table_name, ...) {
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
    q += ")
  }
}
}
