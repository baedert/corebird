/*  This file is part of corebird.
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