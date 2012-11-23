



class Utils{
	






	/**
	* Parses a date given by Twitter in the form 'Wed Jun 20 19:01:28 +0000 2012'
	* and creates a GLib.Date from it to work with.
	*/
	public static GLib.Date parse_date(string input){
		string month_str = input.substring(4, 3);
		int day = int.parse(input.substring(8, 2));
		int year = int.parse(input.substring(input.length-4));

		int month = -1;
		switch(month_str){
			case "Jan": month = 1;  break;
			case "Feb": month = 2;  break;
			case "Mar": month = 3;  break;
			case "Apr": month = 4;  break;
			case "May": month = 5;  break;
			case "Jun": month = 6;  break;
			case "Jul": month = 7;  break;
			case "Aug": month = 8;  break;
			case "Sep": month = 9;  break;
			case "Oct": month = 10; break;
			case "Nov": month = 11; break;
			case "Dec": month = 12; break;

		}

		// stdout.printf("Month:%s:\n", month_str);
		// stdout.printf("Day:%d:\n", day);
		// stdout.printf("Year:%d:\n", year);

		// stdout.printf("Complete date: %d.%d.%d\n", day, month, year);

		GLib.Date date = {};
		return date;
	}
}