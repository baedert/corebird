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

public class Collect : GLib.Object {
  private int cur = 0;
  private int max;
  private GLib.Error? error = null;
  public bool done {
    get {
      return this.cur == this.max;
    }
  }


  public signal void finished (GLib.Error? error);

  public Collect (int max)
  requires (max >= 0)
  {
    this.max = max;
  }

  public void emit (GLib.Error? error = null)
  requires (cur < max)
  {
    /* If our global error is set, something previously went wrong and we ignore
       this call to emit(); */
    if (this.error != null)
      return;

    /* If error is set, we call finished() with that error and ignore all
       following calls to emit() */
    if (error != null) {
      finished (error);
      this.error = error;
      return;
    }

    cur++;
    if (cur == max) {
      finished (null);
    }
  }
}
