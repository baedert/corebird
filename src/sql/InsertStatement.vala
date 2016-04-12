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
  public delegate bool SelectCallback (string[] vals);

  public class InsertStatement : GLib.Object {
    public unowned Sqlite.Database db;
    private StringBuilder query_builder  = new StringBuilder ();
    private GLib.GenericArray<string> bindings = new GLib.GenericArray<string>();
    private bool ran = false;

    public InsertStatement (string table_name, bool replace = false) {
      if (replace)
        query_builder.append ("INSERT OR REPLACE INTO `");
      else
        query_builder.append ("INSERT INTO `");
      query_builder.append (table_name).append ("` (");
    }

    public int64 run () {
      query_builder.append (") VALUES (");
      query_builder.append ("?");
      for (int i = 0; i < bindings.length -1; i++)
        query_builder.append (",?");
      query_builder.append (");");


      Sqlite.Statement stmt;
      int ok = db.prepare_v2 (query_builder.str, -1, out stmt);

      if (ok != Sqlite.OK) {
        critical (db.errmsg ());
        return -1;
      }

      for (int i = 0; i < bindings.length; i++) {
        stmt.bind_text (i + 1, bindings.get (i));
      }
      ok = stmt.step ();
      if (ok != Sqlite.DONE) {
        critical (db.errmsg ());
        StringBuilder err_msg = new StringBuilder ();
        err_msg.append (stmt.sql ()).append (" --- ");
        for (int i = 0; i < bindings.length; i++) {
          err_msg.append (bindings.get (i)).append (", ");
        }
        critical (err_msg.str);
      }
      ran = true;
      return db.last_insert_rowid ();
    }

    public InsertStatement val (string col_name, string col_value) {
      if (bindings.length > 0)
        query_builder.append (", ");
      query_builder.append ("`").append (col_name).append ("`");
      bindings.add (col_value);
      return this;
    }

    public InsertStatement vali (string col_name, int col_value) {
      return val (col_name, col_value.to_string ());
    }

    public InsertStatement vali64 (string col_name, int64 col_value) {
      return val (col_name, col_value.to_string ());
    }

    public InsertStatement valb (string col_name, bool col_value) {
      return val (col_name, col_value ? "1" : "0");
    }

#if DEBUG
    ~InsertStatement () {
      if (!ran)
        critical ("InsertStatement for %s did not run.", query_builder.str);
    }
#endif
  }

}

