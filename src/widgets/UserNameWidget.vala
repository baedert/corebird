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
      switch (value) {
        case NAME_SCREEN_NAME:
          if (_layout == SCREEN_NAME_NAME || _layout == SCREEN_NAME) {
            switch_names ();
          }
          secondary_name_label.show ();
        break;

        case SCREEN_NAME_NAME:
          if (_layout == NAME_SCREEN_NAME || _layout == NAME) {
            switch_names ();
          }
          secondary_name_label.show ();
        break;

        case NAME:
          if (_layout == SCREEN_NAME_NAME || _layout == SCREEN_NAME) {
            switch_names ();
          }

          secondary_name_label.hide ();
        break;

        case SCREEN_NAME:
          if (_layout == NAME_SCREEN_NAME || _layout == NAME) {
            switch_names ();
          }
          secondary_name_label.hide ();
        break;

        default:
          assert (false);
        break;
      }
      this._layout = value;
    }
    get {
      return this._layout;
    }
  }

  /**
   * Set the name (not screen_name) on the correct label.
   */
  private void set_label_name (string name) {
    switch (_layout) {
      case NAME_SCREEN_NAME:
      case NAME:
        primary_name_label.set ("label", name, null);
        break;
      case SCREEN_NAME_NAME:
      case SCREEN_NAME:
        secondary_name_label.label = name;
        break;
    }
  }

  private void set_label_screen_name (string screen_name) {
    switch (_layout) {
      case NAME_SCREEN_NAME:
      case NAME:
        secondary_name_label.label = screen_name;
        break;
      case SCREEN_NAME_NAME:
      case SCREEN_NAME:
        primary_name_label.set ("label", screen_name, null);
        break;
    }
  }

  public new string name {
    set {
      set_label_name (value);
    }
    get {
      unowned string s;
      primary_name_label.get ("name", out s, null);
      return s;
    }
  }

  public string screen_name {
    set {
      set_label_screen_name (value);
    }
    get {
      return secondary_name_label.get_label ();
    }
  }

  private bool _primary_name_clickable = false;
  public bool primary_name_clickable {
    set {
      if (value) {
        this.remove (this.primary_name_label);
        primary_name_label = new TextButton ();
        ((TextButton)primary_name_label).clicked.connect (() => {
          primary_name_clicked ();
        });
        primary_name_label.no_show_all = true;
        primary_name_label.valign = Gtk.Align.BASELINE;
        primary_name_label.show ();
        this.add (primary_name_label);
        this.reorder_child (primary_name_label, 0);
      } else
        assert (false);
      _primary_name_clickable = value;
    }
    get {
      return _primary_name_clickable;
    }
  }

  private Gtk.Widget primary_name_label;
  private Gtk.Label secondary_name_label;
  public signal void primary_name_clicked ();

  construct {
    this.primary_name_label = new Gtk.Label ("");
    this.primary_name_label.no_show_all = true;
    this.primary_name_label.valign = Gtk.Align.BASELINE;
    this.primary_name_label.halign = Gtk.Align.START;
    Pango.AttrList attr_list = new Pango.AttrList ();
    attr_list.insert (Pango.attr_weight_new (Pango.Weight.BOLD));
    this.primary_name_label.set ("attributes", attr_list, null);
    this.primary_name_label.show ();
    this.secondary_name_label = new Gtk.Label ("");
    this.secondary_name_label.no_show_all = true;
    this.secondary_name_label.valign = Gtk.Align.BASELINE;
    this.secondary_name_label.halign = Gtk.Align.START;
    this.secondary_name_label.get_style_context ().add_class ("dim-label");


    this.pack_start (primary_name_label);
    this.pack_start (secondary_name_label);
    this.spacing = 6;

    Settings.get ().bind ("name-scheme",
                          this,
                          "layout",
                          GLib.SettingsBindFlags.GET);
    this.notify["orientation"].connect (orientation_changed_cb);
  }

  private void orientation_changed_cb () {
    if (this.orientation == Gtk.Orientation.VERTICAL) {
      this.primary_name_label.valign = Gtk.Align.END;
      this.secondary_name_label.valign = Gtk.Align.START;
      this.spacing = 3;
    }
  }

  private void switch_names () {
    string tmp;
    primary_name_label.get ("label", out tmp, null);
    primary_name_label.set ("label", secondary_name_label.label, null);
    secondary_name_label.label = tmp;
  }
}
