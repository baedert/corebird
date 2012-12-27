

using SQLHeavy;

class SQLHeavyBenchmark {

	static void main(string[] args){
		int COUNT = 100;
		Database db = new Database("test.db");
		//Initialize the database
		db.execute("CREATE TABLE IF NOT EXISTS `foo`
						('a' VARCHAR(255), 'b' VARCHAR(255), 'c' VARCHAR(255), 'd' VARCHAR(255));");

		GLib.Timer timer = new GLib.Timer();


		stdout.printf("Uncached queries:\n");
		timer.start();
		for(int i = 0; i < COUNT; i++){
			Query q = new Query(db, 
				"INSERT INTO `foo`(a, b, c, d) VALUES (:a, 'b', :c, 'd');");
			q.set_string(":a", "A");
			q.set_string(":c", "C");

			q.execute();
		}
		timer.stop();
		double seconds = timer.elapsed();
		stdout.printf("Took %f seconds\n", seconds);

		timer.reset();


		stdout.printf("Cached query:\n");
		timer.start();
		Query q = new Query(db, "INSERT INTO `foo`(a, b, c, d) VALUES (:a, 'b', :c, 'd');");
		for(int i = 0; i < COUNT; i++){
			q.set_string(":a", "A");
			q.set_string(":c", "C");
			q.execute();
		}
		timer.stop();
		seconds = timer.elapsed();
		stdout.printf("Took %f seconds\n", seconds);


		timer.reset();
		stdout.printf("Direct:\n");
		timer.start();
		for(int i = 0; i < COUNT; i++){
			db.execute("INSERT INTO `foo`(a, b, c, d) VALUES ('A', 'b', 'C', 'd');");
		}
		timer.stop();
		seconds = timer.elapsed();
		stdout.printf("Took %f seconds\n", seconds);


	}

}
