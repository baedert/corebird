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

class UserNameWidget : Gtk.Box {
  public static const int NAME_SCREEN_NAME = 0;
  public static const int SCREEN_NAME_NAME = 1;
  public static const int NAME             = 2;
  public static const int SCREEN_NAME      = 3;

  private int _layout = NAME_SCREEN_NAME;
  public int layout {
    set {
      this._layout = value;
      if (_layout == NAME_SCREEN_NAME) {
        name_label.show ();
        screen_name_label.show ();
        this.reorder_child (name_label, 0);
        this.reorder_child (screen_name_label, 1);
      } else if (_layout == SCREEN_NAME_NAME) {
        name_label.show ();
        screen_name_label.show ();
        this.reorder_child (name_label, 1);
        this.reorder_child (screen_name_label, 0);
      } else if (_layout == NAME) {
        screen_name_label.hide ();
        name_label.show ();
      } else if (_layout == SCREEN_NAME) {
        name_label.hide ();
        screen_name_label.show ();
      } else
        assert (false);
    }
    get {
      return this._layout;
    }
  }

  public new string name {
    set {
      name_label.set_label (value);
    }
    get {
      return name_label.get_label ();
    }
  }

  public string screen_name {
    set {
      screen_name_label.set_label (value);
    }
    get {
      return screen_name_label.get_label ();
    }
  }

  private Gtk.Label name_label;
  private Gtk.Label screen_name_label;


  construct {
    this.name_label = new Gtk.Label ("");
    this.name_label.no_show_all = true;
    this.name_label.valign = Gtk.Align.BASELINE;
    Pango.AttrList attr_list = new Pango.AttrList ();
    attr_list.insert (Pango.attr_weight_new (Pango.Weight.BOLD));
    this.name_label.set_attributes (attr_list);
    this.screen_name_label = new Gtk.Label ("");
    this.screen_name_label.no_show_all = true;
    this.screen_name_label.valign = Gtk.Align.BASELINE;
    this.screen_name_label.get_style_context ().add_class ("dim-label");


    this.pack_start (name_label);
    this.pack_start (screen_name_label);
    this.spacing = 6;
  }
}
