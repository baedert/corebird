



class Utils{
	private static string[] MONTHS = {
		"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
	};


	/**
	* Parses a date given by Twitter in the form 'Wed Jun 20 19:01:28 +0000 2012'
	* and creates a GLib.DateTime in the local time zone to work with.
	*
	* @return The given date as GLib.DateTime in the current time zone.
	*/
	public static GLib.DateTime parse_date(string input){
		if (input == ""){
			return new GLib.DateTime.now_local();
		}
		string month_str = input.substring(4, 3);
		int day = int.parse(input.substring(8, 2));
		int year = int.parse(input.substring(input.length-4));
		string timezone = input.substring(20, 5);

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
		
		int hour   = int.parse(input.substring(11, 2));
		int minute = int.parse(input.substring(14, 2));
		int second = int.parse(input.substring(17, 2));
		GLib.DateTime dt = new GLib.DateTime(new GLib.TimeZone(timezone), year, month, day, hour, minute, second);
		return dt.to_timezone(new TimeZone.local());
	}

	/**
	 * Calculates an easily human-readable version of the time difference between 
	 * time and now.
	 * Example: "5m" or "3h" or "26m" or "16 Nov"
	 */
	public static string get_time_delta(GLib.DateTime time, GLib.DateTime now){
		//diff is the time difference in microseconds
		GLib.TimeSpan diff = now.difference(time);

		int minutes = (int)(diff / 1000.0 / 1000.0 / 60.0);
		if (minutes < 60)
			return "%dm".printf(minutes);
		
		int hours = (int)(minutes / 60.0);
		if (hours < 24)
			return "%dh".printf(hours);

		//If 'time' was over 24 hours ago, we just return that
		return "%d %s".printf(time.get_day_of_month(), MONTHS[time.get_month()-1]);
	}


	/**
	 * Extracts the actual filename out of a given path.
	 * E.g. for /home/foo/bar.png, it will return "bar.png"
	 *
	 * @return The filename of the given path, and nothing else.
	 */
	public static string get_file_name(string path){
		return path.substring(path.last_index_of("/") + 1);
	}

	/**
	 * Extracts the file type from the given path.
	 * E.g. for http://foo.org/bar/bla.png, this will just return "png"
	 */
	public static string get_file_type(string path){
		return path.substring(path.last_index_of(".") + 1);
	}

	public static string get_avatar_name(string path){
		string[] parts = path.split("/");
		return parts[parts.length - 2]+"_"+parts[parts.length - 1];
	}
}