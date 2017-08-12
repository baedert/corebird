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

public class ReplyIndicator : Gtk.Revealer {
  private const int FINAL_HEIGHT = 5;
  private bool replies = false;
  public bool replies_available {
    set {
      this.replies = value;
      this.reveal_child = value;
    }
    get { return replies; }
  }
  private Gtk.Button button;

  public signal void clicked ();

  construct {
    this.reveal_child = false;
    this.button = new Gtk.Button.with_label (_("Show replies"));
    button.show_all ();
    button.clicked.connect (() => { this.clicked (); });
    this.add (button);
  }

  static construct {
    set_css_name ("replyindicator");
  }
}
