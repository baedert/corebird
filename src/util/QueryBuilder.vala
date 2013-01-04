


class QueryBuilder{
	public enum CompareType{
		EQUALS,
		LOWER_THAN,
		GREATER_THAN
	}
	public enum OrderType{
		DESC, ASC
	}
	private string query;


	public QueryBuilder(){
	}


	public QueryBuilder select(string field1, ...){
		StringBuilder builder = new StringBuilder("SELECT ");
		builder.append("`").append(field1).append("`");

		var list = va_list();

		while(true){
			string field = list.arg();
			if(field == null)
				break;
			builder.append(", `")
				   .append(field)
				   .append("`");
		}

		query =  builder.str;
		return this;
	}


	public QueryBuilder where(string field, string value,
	                          CompareType ct = CompareType.EQUALS){
		//TODO: Support the others
		query += " WHERE `%s`='%s'".printf(field, value);
		return this;
	}

	public QueryBuilder order(string field_name, OrderType ot = OrderType.ASC){
		string o = ot == OrderType.ASC ? "ASC" : "DESC";
		query += " ORDER BY `%s` %s".printf(field_name, o);

		//This is the last call, so we just set the sql string
		// this.sql = query;

		return this;
	}

	public SQLHeavy.QueryResult execute(SQLHeavy.Database db) throws SQLHeavy.Error{
		SQLHeavy.Query q = new SQLHeavy.Query(db, query);
		return q.execute();
	}

}