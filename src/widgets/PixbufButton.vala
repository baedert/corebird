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

class PixbufButton : Gtk.Button {
  private Cairo.ImageSurface bg;
  private Gtk.Menu menu;
  private string menu_string;
  private bool _round = false;
  public bool round {
    get {
      return _round;
    }
    set {
      if (value) {
        this.get_style_context ().add_class ("pixbuf-button-round");
      } else {
        this.get_style_context ().remove_class ("pixbuf-button-round");
      }
      _round = value;
    }
  }

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
    var sc = this.get_style_context ();
    int widget_width = this.get_allocated_width ();
    int widget_height = this.get_allocated_height ();


    if (bg != null) {

      var surface = new Cairo.Surface.similar (ct.get_target (),
                                               Cairo.Content.COLOR_ALPHA,
                                               widget_width, widget_height);
      var ctx = new Cairo.Context (surface);

      ctx.rectangle (0, 0, widget_width, widget_height);

      double scale_x = (double)widget_width / bg.get_width ();
      double scale_y = (double)widget_height / bg.get_height ();
      ctx.save ();
      ctx.scale (scale_x, scale_y);
      ctx.set_source_surface (bg, 0, 0);
      ctx.fill ();
      ctx.restore ();



      if (_round) {
        // make it round
        ctx.set_operator (Cairo.Operator.DEST_IN);
        ctx.translate (widget_width / 2, widget_height / 2);
        ctx.arc (0, 0, widget_width / 2, 0, 2 * Math.PI);
        ctx.fill ();

        // draw outline
        sc.render_frame (ct, 0, 0, widget_width, widget_height);
      }

      ct.rectangle (0, 0, widget_width, widget_height);
      ct.set_source_surface (surface, 0, 0);
      ct.fill ();
    }

    // The css-styled background should be transparent.
    base.draw (ct);
    return GLib.Source.CONTINUE;
  }

  public void set_bg (Cairo.ImageSurface bg) {
    this.bg = bg;
    this.set_size_request (bg.get_width(), bg.get_height());
    this.queue_draw ();
  }

  public void set_pixbuf (Gdk.Pixbuf pixbuf) {
    this.bg = (Cairo.ImageSurface)Gdk.cairo_surface_create_from_pixbuf (pixbuf, 1, null);
    this.queue_draw ();
  }
}
