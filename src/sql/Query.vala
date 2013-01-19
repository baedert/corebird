


class Query{
	public enum CompareType{
		EQUALS,
		LOWER_THAN,
		GREATER_THAN
	}
	public enum OrderType{
		DESC, ASC
	}
	
	public static Sqlite.Database db;	
	protected StringBuilder query = new StringBuilder();
	protected unowned Sqlite.Database local_db;

	public Query(Sqlite.Database? local_db = null){
		this.local_db = local_db;
	}


	public Query select(string field1, ...){
		query.append("SELECT ").append("`")
			 .append(field1).append("`");

		var list = va_list();

		while(true){
			string field = list.arg();
			if(field == null)
				break;
			query.append(", `")
				   .append(field)
				   .append("`");
		}
		return this;
	}

	public Query from(string table_name){
		query.append(" FROM ").append(table_name);
		return this;
	}


	public Query where(string field, CompareType ct = CompareType.EQUALS,
	                   string value){
		//TODO: Support the others
		query.append(" WHERE `").append(field).append("`='")
		     .append(value).append("'");
		return this;
	}

	public Query order(string field_name, OrderType ot = OrderType.ASC){
		string o = ot == OrderType.ASC ? "ASC" : "DESC";
		query.append(" ORDER BY `").append(field_name).append("` ")
		     .append(o);

		return this;
	}

	public void execute(Sqlite.Callback? callback = null){
		if (local_db == null)
			Query.db.exec(query.str, callback);
		else
			local_db.exec(query.str, callback);
	}

	public static void execute_query(string sql){
		Query.db.exec(sql, null);
	}


	public string get_sql(){
		return query.str;
	}
}