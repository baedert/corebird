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
 * Trimmed-down version of MediaButton, used in the Compose Widow
 * to add new images.
 */
public class AddImageButton : Gtk.Button {
  private static const int ICON_SIZE = 32;
  private new Gdk.Pixbuf? _image;
  public new Gdk.Pixbuf? image {
    set {
      this._image = value;
      if (value != null) {
        this.get_style_context ().remove_class ("image-placeholder");
        this.get_style_context ().add_class ("image-added");
      } else {
        this.get_style_context ().add_class ("image-placeholder");
        this.get_style_context ().remove_class ("image-added");
      }
      this.queue_draw ();
    }
    get {
      return _image;
    }
  }
  public signal void add_clicked ();
  public signal void remove_clicked ();


  public AddImageButton () {
    this.clicked.connect (() => {
      if (_image == null) {
        add_clicked ();
      } else {
        remove_clicked ();
      }
    });
  }

  construct {
    this.set_size_request (-1, MultiMediaWidget.HEIGHT);
    this.get_style_context ().add_class ("image-placeholder");
  }

  public override bool draw (Cairo.Context ct) {
    int widget_width = get_allocated_width ();
    int widget_height = get_allocated_height ();

    Gtk.StyleContext style_context = this.get_style_context ();

    /* Draw thumbnail */
    if (this._image != null) {
      ct.save ();
      ct.rectangle (0, 0, widget_width, widget_height);

      double scale = (double)widget_width / _image.get_width ();
      ct.scale (scale, 1);
      Gdk.cairo_set_source_pixbuf (ct, _image, 0, 0);
      ct.fill ();
      ct.restore ();
    }

    base.draw (ct);
    style_context.render_check (ct,
                                (widget_width / 2.0) - (ICON_SIZE / 2.0),
                                (widget_height / 2.0) - (ICON_SIZE / 2.0),
                                ICON_SIZE,
                                ICON_SIZE);

    return false;
  }
}


