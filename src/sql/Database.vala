/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */




namespace Sql {
  public const string COREBIRD_INIT_FILE = DATADIR + "/sql/init/Create.%d.sql";
  public const string ACCOUNTS_INIT_FILE = DATADIR + "/sql/accounts/Create.%d.sql";

  public const int STOP     = -1;
  public const int CONTINUE =  0;

public class Database {
  private Sqlite.Database db;


  public Database (string filename, string? init_file = null) {
    int err = Sqlite.Database.open (filename, out db);
    if (err == 1) {
      critical ("Error when opening the database '%s': %s",
                filename, db.errmsg ());
    }
    this.exec ("PRAGMA journal_mode = MEMORY;");
    if (init_file == null)
      return;

    int user_version = -1;
    this.exec ("pragma user_version;", (n_cols, vals) => {user_version = int.parse(vals[0]); return STOP;});
    var next_version_file = init_file.printf(user_version + 1);
    debug ("%s User version: %d", filename, user_version);
    while (FileUtils.test (next_version_file, FileTest.EXISTS)) {
      string sql_content;
      try {
        debug ("Applying file '%s'", next_version_file);
        FileUtils.get_contents (next_version_file, out sql_content);
      } catch (GLib.FileError e) {
        critical (e.message);
        return;
      }
      db.exec (sql_content);
      debug ("Executed init file '%s' for database '%s'", next_version_file, filename);
      this.exec ("pragma user_version;", (n_cols, vals) => {user_version = int.parse(vals[0]); return STOP;});
      next_version_file = init_file.printf (user_version + 1);
    }
  }

  public int64 exec_insert (string sql) {
    db.exec (sql);
    return db.last_insert_rowid ();
  }

  public void exec (string sql, Sqlite.Callback? callback = null) {
#if DEBUG
    string err = "";
    int val = db.exec (sql, callback, out err);
    if (val != Sqlite.OK && val != 4)
      critical ("SQL ERROR(%d): '%s' FOR QUERY '%s'", val, err, sql);
#else
    db.exec (sql, callback);
#endif
  }

  public void execf (string sql, string first_param, ...) {
    db.exec (sql.printf (first_param, va_list ()));
  }

  public Sql.InsertStatement insert (string table_name) {
    var stmt = new InsertStatement (table_name);
    stmt.db = db;
    return stmt;
  }

  public Sql.InsertStatement replace (string table_name) {
    var stmt = new InsertStatement (table_name, true);
    stmt.db = db;
    return stmt;

  }

  public Sql.SelectStatement select (string table_name) {
    var stmt = new SelectStatement (table_name);
    stmt.db = db;
    return stmt;
  }

  public Sql.UpdateStatement update (string table_name) {
    var stmt = new UpdateStatement (table_name);
    stmt.db = db;
    return stmt;
  }

  public void begin_transaction () {
    db.exec ("BEGIN TRANSACTION;");
  }

  public void end_transaction () {
    db.exec ("END TRANSACTION;");
  }
}
}
