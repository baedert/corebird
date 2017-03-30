/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2016 Timm Bäder
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

namespace Benchmark {
  public class Bench {
    public string name;
    public GLib.DateTime first;
    public void stop () {
#if DEBUG
      var ts = new GLib.DateTime.now_local ().difference (first);
      int64 ms = (ts / 1000);

      debug (@"$(this.name) took $ms ms ($ts us)");
#endif
    }
  }


  public Bench start (string name) {
    var b = new Bench ();

#if DEBUG
    b.name = name;
    b.first = new GLib.DateTime.now_local ();
#endif
    return b;
  }
}
