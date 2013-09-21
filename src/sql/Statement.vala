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
  interface IStatement {
      public abstract Sqlite.Database db { public set; private get; }
      public abstract void run();
  }

  class InsertStatement : IStatement {
    public unowned Sqlite.Database db { public set; private get; }
    private StringBuilder query_builder  = new StringBuilder ();
    private Gee.ArrayList<string> values = new Gee.ArrayList<string> ();

    public InsertStatement (string table_name) {
      query_builder.append ("INSERT INTO `").append (table_name).append ("` (");
    }

    public InsertStatement val (string column_name, string value) {
      values.add (value);
      if (values.size > 0)
        query_builder.append (",");
      query_builder.append ("`").append (column_name).append ("`");
      return this;
    }

    public void run () {
      query_builder.append (") VALUES (");
      query_builder.append ("?");
      for (int i = 0; i < values.size -1; i++)
        query_builder.append (",?");
      query_builder.append (");");


      Sqlite.Statement stmt;
//      this.db.prepare_v2 (query_builder.str, -1, out stmt);
//      stmt.bind_text (

    }
  }
}

