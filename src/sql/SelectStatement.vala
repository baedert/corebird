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
  public class SelectStatement : IStatement {
    public unowned Sqlite.Database db { public set; private get; }
    private StringBuilder query_builder = new StringBuilder ();
    private string table_name;

    public SelectStatement (string table_name) {
      this.table_name = table_name;
    }
    public SelectStatement cols (string first, ...) {
      var arg_list = va_list ();
      query_builder.append ("SELECT `").append (first).append ("`");
      for (string? arg = arg_list.arg<string> (); arg != null; arg = arg_list.arg<string> ()) {
        query_builder.append (", `").append (arg).append ("`");
      }
      query_builder.append (" FROM `").append (table_name).append ("`");
      return this;
    }

    public SelectStatement where (string stmt) {
      query_builder.append (" WHERE ").append (stmt);
      return this;
    }

    public SelectStatement order (string order_by) {
      query_builder.append (" ORDER BY ").append (order_by);
      return this;
    }

    public SelectStatement limit (int limit) {
      query_builder.append (" LIMIT ").append (limit.to_string ());
      return this;
    }

    public void run (SelectCallback callback) {
      Sqlite.Statement stmt;
      int ok = db.prepare_v2 (query_builder.str, -1, out stmt);
      if (ok != Sqlite.OK) {
        critical (db.errmsg ());
        critical (query_builder.str);
        return;
      }
      bool next = true;
      int n_cols = stmt.column_count ();
      while (stmt.step () == Sqlite.ROW && next) {
        string[] vals = new string[n_cols];
        for (int i = 0; i < n_cols; i++)
          vals[i] = stmt.column_text (i);
        next = callback (vals);
      }
    }

    public int64 once_i64 () {
      int64 back = -1;
      this.run ((vals) => {
        back = int64.parse (vals[0]);
        return false;
      });
      return back;
    }
  }

}
