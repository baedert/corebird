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

class TextButton : Gtk.Button {
  public TextButton (string label = "") {
    if (label != "")
      this.label= label;
  }

  construct {
    this.get_style_context ().add_class ("text-only-button");
  }

  /**
   * Adds a GtkLabel to the Button using the given text as markup.
   * If the button already contains another child, that will either be replaced if it's
   * no instance of GtkLabel, or - if it's a GtkLabel already - be reused.
   *
   * @param text The markup to use(see pango markup)
   */
  public void set_markup (string text) {
    Gtk.Label label = null;
    Gtk.Widget child = get_child ();
    if (child != null) {
      if (child is Gtk.Label) {
        label = (Gtk.Label)child;
        label.set_markup (text);
      } else {
        this.remove (child);
        label = new Gtk.Label (text);
      }
    } else {
      label = new Gtk.Label (text);
    }
    label.set_use_markup (true);
    label.set_justify (Gtk.Justification.CENTER);
    label.valign = Gtk.Align.BASELINE;

    label.visible = true;
    if(label.parent == null)
      this.add (label);
  }
}
