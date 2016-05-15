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

public class DeltaUpdater : GLib.Object {
  private GLib.GenericArray<WeakRef> minutely = new GenericArray<WeakRef> ();
  private GLib.GenericArray<WeakRef> hourly = new GenericArray<WeakRef> ();
  private uint minutely_id;
  private uint hourly_id;

  public DeltaUpdater () {
    minutely_id = GLib.Timeout.add (60 * 1000, () => {
      for (int i = 0, size = minutely.length; i < size; i++) {
        WeakRef item_ref = minutely.get (i);
        ITwitterItem item = item_ref.get ();
        if (!(item is ITwitterItem)) {
          minutely.remove (item_ref);
          size --;
          continue;
        }
        int seconds = item.update_time_delta ();
        if (seconds >= 3600) {
          minutely.remove (item_ref);
          hourly.add (item_ref);
          size --;
        }
      }
      return GLib.Source.CONTINUE;
    });

    hourly_id = GLib.Timeout.add (60 * 60 * 1000, () => {
      for (int i = 0, size = hourly.length; i < size; i++) {
        WeakRef item_ref = hourly.get (i);
        ITwitterItem? item = item_ref.get ();
        if (!(item is ITwitterItem)) {
          hourly.remove (item_ref);
          size --;
          continue;
        }
        item.update_time_delta ();
      }
      return GLib.Source.CONTINUE;
    });
  }

  ~DeltaUpdater() {
    if (minutely_id != 0)
      GLib.Source.remove (minutely_id);
    if (hourly_id != 0)
      GLib.Source.remove (hourly_id);
  }



  public void add (ITwitterItem entry) {
    // TODO: This sucks
    GLib.DateTime now  = new GLib.DateTime.now_local ();
    int64 sort_factor = entry.sort_factor;
    // Fuck.
    if (entry is TweetListEntry) {
      var e = (TweetListEntry)entry;
      sort_factor = e.tweet.source_tweet.created_at;
    }
    GLib.TimeSpan diff = now.difference (new GLib.DateTime.from_unix_local (sort_factor));


    int seconds = (int)(diff / 1000.0 / 1000.0);

    WeakRef r = new WeakRef (entry);
    if (seconds  < 3600)
      minutely.add (r);
    else if (seconds < 60 * 60 * 24)
      hourly.add (r);
  }

}
