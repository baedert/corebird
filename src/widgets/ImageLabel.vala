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

using Gtk;

/**
 * Displays an icon on the left/right side of the
 * specified text. Helps to reduce the complexity of layouts.
 */
class ImageLabel : Label {
  private static const int GAP = 0;
  private int _icon_size = 14;
  private string _icon_name;
  public Gtk.PositionType icon_pos = Gtk.PositionType.LEFT;
  public string icon_name {
    set {
      _icon_name = value;
      load_icon ();
    }
    get {
      return _icon_name;
    }
  }
  public int icon_size {
    set {
      _icon_size = value;
      load_icon ();
    }
    get {
      return _icon_size;
    }
  }
  private Gdk.Pixbuf icon;


  public ImageLabel (string text) {
    this.label = text;
  }

  public override bool draw (Cairo.Context c) {
    int height = this.get_allocated_height ();
    StyleContext context = this.get_style_context ();
    if (icon_pos == PositionType.LEFT) {
      if (icon != null) {
        context.render_icon (c, icon, 0,
                             (height / 2) - (icon_size / 2));
        c.translate (icon.width + GAP, 0);
      }
      base.draw(c);
    } else {
      base.draw(c);
      if (icon != null) {
        c.translate (base.get_allocated_width() - icon.width, 0);
        context.render_icon (c, icon, 0, 0);
      }
    }


    return false;
  }

  public override void size_allocate (Allocation allocation) {
      allocation.width += icon.width + GAP;
      base.size_allocate (allocation);
  }

  private void load_icon () {
    if (icon_name != null && icon_name != "") {
      try {
        this.icon = Gtk.IconTheme.get_default ().load_icon (_icon_name, _icon_size, 0);
      } catch (GLib.Error e) {
        warning (e.message);
      }
    }
  }
}
