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
  public interface IStatement {
      public abstract Sqlite.Database db { public set; protected get; }
  }
  public delegate bool SelectCallback (string[] vals);

  public class InsertStatement : IStatement {
    public unowned Sqlite.Database db { public set; private get; }
    private StringBuilder query_builder  = new StringBuilder ();
    private Gee.ArrayList<string> bindings = new Gee.ArrayList<string>();
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
      for (int i = 0; i < bindings.size -1; i++)
        query_builder.append (",?");
      query_builder.append (");");


      Sqlite.Statement stmt;
      int ok = db.prepare_v2 (query_builder.str, -1, out stmt);

      if (ok != Sqlite.OK) {
        critical (db.errmsg ());
        return -1;
      }

      for (int i = 0; i < bindings.size; i++) {
        stmt.bind_text (i + 1, bindings.get (i));
      }
      ok = stmt.step ();
      if (ok != Sqlite.DONE) {
        critical (db.errmsg ());
        critical (stmt.sql ());
      }
      ran = true;
      return db.last_insert_rowid ();
    }

    public InsertStatement val (string col_name, string col_value) {
      if (bindings.size > 0)
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

#if __DEV
    ~InsertStatement () {
      if (!ran)
        critical ("InsertStatement for %s did not run.", query_builder.str);
    }
#endif
  }

  /**
   *
   *
   *
   *
   *
   */
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
      query_builder.append ("WHERE ").append (stmt);
      return this;
    }

    public SelectStatement order (string order_by) {
      query_builder.append ("ORDER BY ").append (order_by);
      return this;
    }

    public void run (SelectCallback callback) {
      Sqlite.Statement stmt;
      int ok = db.prepare_v2 (query_builder.str, -1, out stmt);
      if (ok != Sqlite.OK) {
        critical (db.errmsg ());
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
  }


  public class UpdateStatement : IStatement {
    public unowned Sqlite.Database db { public set; private get; }
    private StringBuilder query_builder  = new StringBuilder ();
    private Gee.ArrayList<string> bindings = new Gee.ArrayList<string>();
    private bool ran = false;

    public UpdateStatement (string table_name) {
      query_builder.append ("UPDATE `").append (table_name).append ("` SET ");
    }

    public int64 run () {
      Sqlite.Statement stmt;
      int ok = db.prepare_v2 (query_builder.str, -1, out stmt);

      if (ok != Sqlite.OK) {
        critical (db.errmsg ());
        return -1;
      }
      for (int i = 0; i < bindings.size; i++) {
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
      if (bindings.size > 0)
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
#if __DEV
    ~UpdateStatement () {
      if (!ran)
        critical ("UpdateStatement for %s did not run.", query_builder.str);
    }
#endif


  }



}

