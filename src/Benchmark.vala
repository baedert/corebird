


class Benchmark{
	private static GLib.Timer timer;
	private static string action_name;


	public static void start(string name){
		if(timer == null){
			timer = new GLib.Timer();
		}

		timer.start();
		action_name = name;
	}

	public static void stop(){
		timer.stop();
		ulong microseconds;
		timer.elapsed(out microseconds);
		float s = microseconds / 1000000.0f;
		message("%s took %fs", action_name, s);
	}


}