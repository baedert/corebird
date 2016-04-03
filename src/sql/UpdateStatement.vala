
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

  public class UpdateStatement : GLib.Object {
    public unowned Sqlite.Database db;
    private StringBuilder query_builder  = new StringBuilder ();
    private GLib.GenericArray<string> bindings = new GLib.GenericArray<string> ();
    private bool ran = false;

    public UpdateStatement (string table_name) {
      query_builder.append ("UPDATE `").append (table_name).append ("` SET ");
    }

    public int64 run () {
      Sqlite.Statement stmt;
      query_builder.append(";");
      int ok = db.prepare_v2 (query_builder.str, -1, out stmt);

      if (ok != Sqlite.OK) {
        critical (db.errmsg ());
        return -1;
      }
      for (int i = 0; i < bindings.length; i++) {
        stmt.bind_text (i + 1, bindings.get (i));
      }
      ok = stmt.step ();
      if (ok == Sqlite.ERROR) {
        critical (db.errmsg ());
        critical (stmt.sql ());
        return -1;
      }
      ran = true;
      return db.last_insert_rowid ();
    }

    public UpdateStatement where (string where) {
      query_builder.append (" WHERE ").append (where);
      return this;
    }

    public UpdateStatement where_eq (string col, string value) {
      query_builder.append (" WHERE `").append (col).append ("`='").append (value).append ("'");
      return this;
    }

    public UpdateStatement where_eqi (string col, int64 iv) {
      return where_eq (col, iv.to_string ());
    }

    public UpdateStatement val (string col_name, string col_value) {
      if (bindings.length > 0)
        query_builder.append (", ");
      query_builder.append ("`").append (col_name).append ("` = ?");
      bindings.add (col_value);
      return this;
    }

    public UpdateStatement vali (string col_name, int col_value) {
      return val (col_name, col_value.to_string ());
    }

    public UpdateStatement vali64 (string col_name, int64 col_value) {
      return val (col_name, col_value.to_string ());
    }

    public UpdateStatement valb (string col_name, bool col_value) {
      return val (col_name, col_value ? "1" : "0");
    }
#if DEBUG
    ~UpdateStatement () {
      if (!ran)
        critical ("UpdateStatement for %s did not run.", query_builder.str);
    }
#endif


  }

}


