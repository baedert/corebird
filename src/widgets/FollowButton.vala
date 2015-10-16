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

class FollowButton : Gtk.Button {
  private bool _following;
  public bool following {
    get { return _following; }
    set {
      var sc = this.get_style_context ();
      if (value) {
        sc.remove_class ("suggested-action");
        sc.add_class ("destructive-action");
        this.stack.visible_child = unfollow_label;
      } else {
        sc.remove_class ("destructive-action");
        sc.add_class ("suggested-action");
        this.stack.visible_child = follow_label;
      }
      this._following = value;
    }
  }
  private Gtk.Stack stack;
  private Gtk.Label follow_label;
  private Gtk.Label unfollow_label;

  construct {
    this.stack = new Gtk.Stack ();
    this.stack.margin_start = 3;
    this.stack.margin_end   = 3;

    this.follow_label = new Gtk.Label (_("Follow"));
    this.unfollow_label = new Gtk.Label (_("Unfollow"));

    stack.add (follow_label);
    stack.add (unfollow_label);

    this.add (stack);
  }

}
