/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
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



class DeltaUpdater : GLib.Object {
  private Gee.ArrayList<weak TweetListEntry> minutely = new Gee.ArrayList<weak TweetListEntry> ();
  private Gee.ArrayList<weak TweetListEntry> hourly   = new Gee.ArrayList<weak TweetListEntry> ();

  public DeltaUpdater () {
    //TODO: Maybe use only one timeout?
    GLib.Timeout.add(60 * 1000, () => {
      for (int i = 0, size = minutely.size; i < size; i++) {
        var item = minutely.get (i);
        int seconds = item.update_time_delta ();
        if (seconds >= 3600) {
          minutely.remove (item);
          hourly.add (item);
          size --;
        }
      }
      return true;
    });

    GLib.Timeout.add(60 * 60 * 1000, () => {
      foreach (var item in hourly) {
        item.update_time_delta ();
      }
      return true;
    });
  }



  public void add (TweetListEntry entry) {
    // TODO: This sucks
    GLib.DateTime now  = new GLib.DateTime.now_local();
    GLib.TimeSpan diff = now.difference(new GLib.DateTime.from_unix_local(
                                        entry.sort_factor));


    int seconds = (int)(diff / 1000.0 / 1000.0);

    if (seconds  < 3600)
      minutely.add (entry);
    else
      hourly.add (entry);
  }

}
