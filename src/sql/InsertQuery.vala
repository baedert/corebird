


using Sqlite;
// TODO: How to best provide data to the actual result of a query?
class InsertQuery : Query {
	private Gee.HashMap<string, string> binds = new Gee.HashMap<string, string>();

	public InsertQuery(Sqlite.Database? local_db = null, 
	                   bool update_or_insert = false){
		if(update_or_insert)
			query.append("INSERT OR REPLACE INTO");
		else
			query.append("INSERT INTO");

		this.local_db = local_db;
	}

	public void bind(string column, string value){
		binds.set(column, value);
	}


	public new void select(string table){
		query.append("`").append(table).append("`");
	}

	public new void execute(Sqlite.Callback? callback = null){
		if(binds.size == 0)
			error("No values bind");

		//Actually build the query
		var key_it = binds.keys.iterator();
		query.append("(");
		query.append("`").append(key_it.get())
			 .append("`");
		for(var has_next = key_it.next(); has_next; has_next = key_it.next()){
			query.append(", `").append(key_it.get()).append("`");
		}
		query.append(") VALUES (");

		var value_it = binds.values.iterator();

		query.append("'").append(value_it.get()).append("'");
		for(var has_next = value_it.next(); has_next; has_next = value_it.next()){
			query.append(", `").append(value_it.get()).append("`");
		}
		query.append(");");

		if(local_db == null)
			Query.db.exec(query.str, callback);
		else
			local_db.exec(query.str, callback);

		base.execute(callback);
	}


}