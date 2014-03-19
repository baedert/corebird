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


/**
 * MissingListEntry represents a list item in a stream to tell the
 * user that his connection to the Twitter server is interrupted.
 * It therefore saves 2 tweet ids, lower_id and upper_id(which can be
 * set once the connection has been established again) to save what
 * portion of the stream is lost.
 * It has 4 states:
 *  - interrupted: If the stream has been interrupted
 *  - resumed: If the stream was once interrupted but is not resumed
 *  - loading: If the user pressed 'load missing tweets' in
 *             the resumed state and we now load those
 *  - error: If anything went wrong at any point
 *
 */
[GtkTemplate (ui = "/org/baedert/corebird/ui/missing-list-entry.ui")]
public class MissingListEntry : Gtk.ListBoxRow, ITwitterItem {
  public bool  seen     { get; set; default = true; }
  public int64 lower_id;
  public int64 upper_id;
  public int64 timestamp;
  public int64 sort_factor {
    get { return timestamp; }
  }
  [GtkChild]
  private Gtk.Stack stack;
  [GtkChild]
  private Gtk.Label error_label;
  [GtkChild]
  private Gtk.Button load_missing_button;
  public signal void load_clicked ();


  public MissingListEntry () {}

  public void set_resumed () {
    stack.visible_child_name = "resumed";
  }

  public void set_interrupted () {
    stack.visible_child_name = "interrupted";
  }

  public void set_loading () {
    stack.visible_child_name = "loading";
  }

  public void set_error (string? msg = null) {
    if (msg != null) {
      error_label.label = msg;
    }
    stack.visible_child_name = "error";
  }

  [GtkCallback]
  private void load_button_clicked_cb () {
    load_clicked ();
  }

  public int update_time_delta (GLib.DateTime? now = null) {return 0;}
}
