


class DeltaUpdater {
	private static DeltaUpdater instance;
	public static new DeltaUpdater get() {
		if(instance == null)
			instance = new DeltaUpdater();
		return instance;
	}

	private GLib.SList<weak TweetListEntry> minutely = new SList<weak TweetListEntry>();
	private GLib.SList<weak TweetListEntry> hourly   = new SList<weak TweetListEntry>();


	private DeltaUpdater() {
		//TODO: Maybe use only one timeout?
		GLib.Timeout.add(60000, // All 60 seconds
		() => {
			minutely.@foreach((item) => {
				int seconds = item.update_time_delta();
				if(seconds >= 3600){
					minutely.remove(item);
					hourly.append(item);
				}
			});
			return true;
		});

		GLib.Timeout.add(3600000, // all 3600 seconds(one hour)
		() => {
			hourly.@foreach((item) => {
				item.update_time_delta();
			});
			return true;
		});
	}



	public void add(TweetListEntry entry) {
		// TODO: This sucks
		GLib.DateTime now  = new GLib.DateTime.now_local();
		GLib.TimeSpan diff = now.difference(new GLib.DateTime.from_unix_local(
		                                    entry.timestamp));


		int seconds = (int)(diff / 1000.0 / 1000.0);

		if(seconds  < 3600)
			minutely.append(entry);
		else
			hourly.append(entry);
	}

}