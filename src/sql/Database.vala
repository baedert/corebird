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
  public const int    COREBIRD_SQL_VERSION = 2;
  public const string COREBIRD_INIT_FILE = "/org/baedert/corebird/sql/init/Create.%d.sql";
  public const int    ACCOUNTS_SQL_VERSION = 3;
  public const string ACCOUNTS_INIT_FILE = "/org/baedert/corebird/sql/accounts/Create.%d.sql";

  private const int STOP     = -1;
  private const int CONTINUE =  0;

public class Database {
  private Sqlite.Database db;


  public Database (string filename, string init_file, int max_version) {
    int err = Sqlite.Database.open (filename, out db);
    if (err == 1) {
      critical ("Error when opening the database '%s': %s",
                filename, db.errmsg ());
    }
    this.exec ("PRAGMA journal_mode = MEMORY;");

    int user_version = -1;
    this.exec ("pragma user_version;", (n_cols, vals) => {user_version = int.parse(vals[0]); return STOP;});

    for (int cur_version = user_version + 1; cur_version <= max_version; cur_version ++) {
      try {
        var data = GLib.resources_lookup_data (init_file.printf (cur_version), 0);
        unowned string sql_str = (string) data.get_data ();

        debug ("Executing %s for %d", init_file, cur_version);
        db.exec (sql_str);
      } catch (GLib.Error e) {
        critical (e.message);
        break;
      }
    }
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
