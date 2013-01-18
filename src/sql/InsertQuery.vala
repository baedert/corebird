


using Sqlite;
// TODO: How to best provide data to the actual result of a query?
class InsertQuery : Query {
	private Gee.HashMap<string, string> binds = new Gee.HashMap<string, string>();

	public InsertQuery(bool replace = false, Sqlite.Database? local_db = null){
		if(replace)
			query.append("INSERT OR REPLACE INTO ");
		else
			query.append("INSERT INTO ");

		this.local_db = local_db;
	}

	public void bind_string(string column, string value){
		binds.set(column, value);
	}
	public void bind_int(string column, int value){
		binds.set(column, value.to_string());
	}
	public void bind_float(string column, float value){
		binds.set(column, value.to_string());
	}


	public new InsertQuery select(string table){
		query.append("`").append(table).append("`");
		return this;
	}

	public new void execute(){
		if(binds.size == 0)
			error("No values bound");

		//Actually build the query
		var key_it = binds.keys.iterator();
		key_it.next();
		query.append("(");
		query.append("`").append(key_it.get())
			 .append("`");
		for(var has_next = key_it.next(); has_next; has_next = key_it.next()){
			query.append(", `").append(key_it.get()).append("`");
		}
		query.append(") VALUES (");

		var value_it = binds.values.iterator();
		value_it.next();
		query.append("'").append(value_it.get()).append("'");
		for(var has_next = value_it.next(); has_next; has_next = value_it.next()){
			query.append(", '").append(value_it.get()).append("'");
		}

		query.append(");");

		// if(local_db == null)
		// 	Query.db.exec(query.str);
		// else
		// 	local_db.exec(query.str);

		// base.execute();
	}


}