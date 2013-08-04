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

class LoaderThread : GLib.Object {
  private Json.Array root;
  private unowned MainWindow? window;
  private unowned Gtk.ListBox list;
  private Thread<void*> thread;
  public delegate void EndLoadFunc(int tweet_count, int64 lowest_id);
  private unowned EndLoadFunc? finished;
  private int tweet_type;
  private int64 lowest_id = int64.MAX - 1;
  private unowned Account acc;

  public LoaderThread(Json.Array root, Account acc,
                      MainWindow? window, Gtk.ListBox list,
                      int tweet_type = -1){
    this.root       = root;
    this.window     = window;
    this.list       = list;
    this.tweet_type = tweet_type;
    this.acc        = acc;
  }

  public void run(EndLoadFunc? finished = null){
    this.finished = finished;
    thread = new Thread<void*>("TweetLoaderThread", thread_func);
  }

  public void* thread_func(){
    GLib.DateTime now = new GLib.DateTime.now_local();

    var entries = new TweetListEntry[root.get_length()];
    root.foreach_element( (array, index, node) => {
      Json.Object o = node.get_object();
      Tweet t = new Tweet();
      t.load_from_json(o, now);

      if (tweet_type != -1){
        t.type = tweet_type;
      }

      if(t.id < lowest_id)
        lowest_id = t.id;

      var entry  = new TweetListEntry(t, window, acc);
      entries[index] = entry;
    });

    GLib.Idle.add( () => {
      message("Results: %d", entries.length);
      for(int i = 0; i < entries.length; i++)
        list.add(entries[i]);
      if (finished != null){
        finished(entries.length, lowest_id);
      }
      return false;
    });

    return null;
  }
}
