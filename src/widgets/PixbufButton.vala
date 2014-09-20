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
 * A button with the given pixbuf as background.
 */
class PixbufButton : Gtk.Button {
  private Gdk.Pixbuf bg;
  private Gtk.Menu menu;
  private string menu_string;

  construct {
    this.border_width = 0;
    get_style_context ().add_class ("pixbuf-button");
  }

  public PixbufButton (bool show_menu = false, string? menu_string = null) {
    if (show_menu) {
      this.button_press_event.connect (button_release_cb);
      this.menu_string = menu_string;
    }
  }

  private bool button_release_cb (Gdk.EventButton evt) {
    if (evt.button == Gdk.BUTTON_SECONDARY) {
      menu = new Gtk.Menu ();
      var source_link_item = new Gtk.MenuItem.with_label (_("Copy link"));
      source_link_item.activate.connect (source_link_item_activate_cb);
      menu.add (source_link_item);
      menu.show_all ();
      menu.popup (null, null, null, evt.button, evt.time);
      return true;
    }
    return false;
  }

  private void source_link_item_activate_cb () {
    Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (Gdk.Display.get_default (),
                                                             Gdk.SELECTION_CLIPBOARD);
    clipboard.set_text (menu_string, -1);
  }

  public override bool draw (Cairo.Context ct) {
    if (bg != null) {
      int widget_width = this.get_allocated_width ();
      int widget_height = this.get_allocated_height ();
      ct.save ();
      ct.rectangle (0, 0, widget_width, widget_height);

      double scale_x = (double)widget_width / bg.get_width ();
      double scale_y = (double)widget_height / bg.get_height ();
      ct.scale (scale_x, scale_y);
      Gdk.cairo_set_source_pixbuf (ct, bg, 0, 0);
      ct.fill ();
      ct.restore ();
    }

    // The css-styled background should be transparent.
    base.draw (ct);
    return false;
  }

  public void set_bg (Gdk.Pixbuf bg){
    this.bg = bg;
    this.set_size_request (bg.get_width(), bg.get_height());
    this.queue_draw ();
  }
}
