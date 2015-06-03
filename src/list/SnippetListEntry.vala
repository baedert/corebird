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

class SnippetListEntry : Gtk.ListBoxRow {
  private Gtk.Label key_label;
  private Gtk.Label value_label;
  private Gtk.Revealer revealer;
  public string key {
    get {
      return key_label.label;
    }
    set {
      key_label.label = value;
    }
  }
  public string value {
    get {
      return value_label.label;
    }
    set {
      value_label.label = value;
    }
  }

  public SnippetListEntry (string key, string value) {
    this.revealer = new Gtk.Revealer ();
    revealer.reveal_child = true;
    var stack = new Gtk.Stack ();
    stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
    box.margin = 6;

    key_label = new Gtk.Label (key);
    key_label.halign = Gtk.Align.FILL;
    key_label.hexpand = true;
    key_label.ellipsize = Pango.EllipsizeMode.END;
    box.add (key_label);

    value_label = new Gtk.Label (value);
    value_label.halign = Gtk.Align.FILL;
    value_label.hexpand = true;
    value_label.xalign = 0;
    value_label.ellipsize = Pango.EllipsizeMode.END;
    box.add (value_label);

    var delete_button = new Gtk.Button.from_icon_name ("list-remove-symbolic",
                                                       Gtk.IconSize.MENU);
    delete_button.clicked.connect (() => {
      stack.visible_child_name = "delete";
      this.activatable = false;
    });
    box.add (delete_button);
    stack.add_named (box, "default");


    var box2 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
    box2.homogeneous = true;
    box2.valign = Gtk.Align.CENTER;
    var cancel_button = new Gtk.Button.with_label ("Cancel");
    cancel_button.clicked.connect (() => {
      stack.visible_child_name = "default";
      this.activatable = true;
    });
    cancel_button.halign = Gtk.Align.END;
    box2.add (cancel_button);

    var real_delete_button = new Gtk.Button.with_label ("Delete");
    real_delete_button.halign = Gtk.Align.START;
    real_delete_button.get_style_context ().add_class ("destructive-action");
    real_delete_button.clicked.connect (real_delete_snippet);
    box2.add (real_delete_button);
    stack.add_named (box2, "delete");

    revealer.add (stack);
    this.add (revealer);
  }

  private void real_delete_snippet () {
    revealer.notify["child-revealed"].connect (() => {
      if (!revealer.child_revealed) {
        Corebird.snippet_manager.remove_snippet (this.key);
      }
    });
    revealer.reveal_child = false;
  }
}
