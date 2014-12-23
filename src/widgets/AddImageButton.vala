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
  private static const uint TARGET_STRING   = 1;
  private static const uint TARGET_URI_LIST = 2;
  private static const uint TARGET_IMAGE    = 3;

  private static const int ICON_SIZE = 32;
  private new Gdk.Pixbuf? _image;
  public new Gdk.Pixbuf? image {
    set {
      this._image = value;
      if (value != null) {
        this.get_style_context ().remove_class ("image-placeholder");
        this.get_style_context ().add_class ("image-added");
        this.tooltip_text = _("Click to remove image");
      } else {
        this.get_style_context ().add_class ("image-placeholder");
        this.get_style_context ().remove_class ("image-added");
        this.get_style_context ().remove_class ("image-error");
        this.get_style_context ().remove_class ("image-progress");
        this.tooltip_text = _("Click to add image");
      }
      this.queue_draw ();
    }
    get {
      return _image;
    }
  }
  public string? image_path = null;
  private string? error_message = null;

  public signal void add_clicked ();
  public signal void remove_clicked ();


  public AddImageButton () {
    this.clicked.connect (() => {
      if (_image == null && error_message == null) {
        add_clicked ();
      } else {
        error_message = null;
        remove_clicked ();
      }
    });

    /* DND stuff */
    const Gtk.TargetEntry[] target_entries = {
      {"STRING",          0,   TARGET_STRING},
      {"text/plain",      0,   TARGET_STRING},
      {"text/uri-list",   0,   TARGET_URI_LIST},
      {"image/png",       0,   TARGET_IMAGE},
      {"image/jpeg",      0,   TARGET_IMAGE},
    };
    Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, target_entries,
                       Gdk.DragAction.COPY);
    this.drag_data_received.connect (drag_data_received_cb);
  }

  construct {
    this.image = null;
    this.set_size_request (-1, MultiMediaWidget.HEIGHT);
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
    if (error_message == null) {
      style_context.render_check (ct,
                                  (widget_width / 2.0) - (ICON_SIZE / 2.0),
                                  (widget_height / 2.0) - (ICON_SIZE / 2.0),
                                  ICON_SIZE,
                                  ICON_SIZE);
    } else {
      style_context.render_check (ct,
                                  20,
                                  (widget_height / 2.0) - (ICON_SIZE / 2.0),
                                  ICON_SIZE,
                                  ICON_SIZE);
      Pango.Layout error_layout = this.create_pango_layout (this.error_message);
      error_layout.set_width ((widget_width - ICON_SIZE - 20 - 20 - 20) * Pango.SCALE);
      error_layout.set_height ((widget_height - 20) * Pango.SCALE);
      style_context.render_layout (ct,
                                   20 + ICON_SIZE + 20,
                                   (widget_height / 2.0) -
                                    (error_layout.get_height () / Pango.SCALE / 2.0),
                                   error_layout);
    }

    return false;
  }

  private void drag_data_received_cb (Gdk.DragContext context, int x, int y,
                                      Gtk.SelectionData selection_data,
                                      uint info, uint time) {

    if (info == TARGET_STRING) {
      var uri = selection_data.get_text ().strip ();
      var file = GLib.File.new_for_uri (uri);
      from_file (file);
    } else if (info == TARGET_IMAGE) {
      /* XXX This doesn't work when uploading since it doesn't set image_path? */
      var pixbuf = selection_data.get_pixbuf ();
      from_bigger_pixbuf (pixbuf);
    } else if (info == TARGET_URI_LIST) {
      var uris = selection_data.get_uris ();
      var file = GLib.File.new_for_uri (uris[0]);
      if (file.get_uri_scheme () == "file") {
        from_file (file);
      }
    }
  }

  private void from_file (GLib.File file) {
    try {
      var pixbuf = new Gdk.Pixbuf.from_file (file.get_path ());
      this.image_path = file.get_path ();
      from_bigger_pixbuf (pixbuf);
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }

  private void from_bigger_pixbuf (Gdk.Pixbuf pixbuf) {
    var thumb = Utils.slice_pixbuf (pixbuf, this.get_allocated_width (),
                                    MultiMediaWidget.HEIGHT);
    this.image = thumb;
  }

  public void set_error (string error_message) {
    this.get_style_context ().remove_class ("image-progress");
    this.get_style_context ().remove_class ("image-success");
    this.get_style_context ().add_class ("image-added");
    if (this.image == null) {
      warning ("Progress started but image == null");
    }

    this.get_style_context ().add_class ("image-error");
    this.error_message = error_message;
    this.set_tooltip_text (_("Click to remove image"));
  }

  public void start_progress () {
    this.get_style_context ().remove_class ("image-added");
    if (this.image == null) {
      warning ("Progress started but image == null");
    }

    this.get_style_context ().add_class ("image-progress");
  }

  public void set_success () {
    this.get_style_context ().remove_class ("image-progress");
    this.get_style_context ().remove_class ("image-added");
    if (this.image == null) {
      warning ("Progress started but image == null");
    }

    this.get_style_context ().add_class ("image-success");
    this.set_tooltip_text ("");
  }
}


