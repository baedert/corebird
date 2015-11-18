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



class AddImageButton2 : Gtk.Widget {
  private static const int MIN_WIDTH  = 40;
  private static const int MAX_HEIGHT = 150;
  public string image_path;
  public Cairo.ImageSurface? surface;
  private Gdk.Window? event_window;

  construct {
    this.set_has_window (false);
  }


  private void get_draw_size (out int width,
                              out int height,
                              out double scale) {
    if (this.surface == null) {
      width  = 0;
      height = 0;
      scale  = 0.0;
      return;
    }

    width  = this.get_allocated_width ();
    height = this.get_allocated_height ();
    double scale_x = (double)width / this.surface.get_width ();
    double scale_y = (double)height / this.surface.get_height ();

    scale = double.min (double.min (scale_x, scale_y), 1.0);

    width  = (int)(this.surface.get_width ()  * scale);
    height = (int)(this.surface.get_height () * scale);
  }

  public override bool draw (Cairo.Context ct) {
    int widget_width = get_allocated_width ();
    int widget_height = get_allocated_height ();


    /* Draw thumbnail */
    if (this.surface != null) {
      ct.save ();

      ct.rectangle (0, 0, widget_width, widget_height);

      int draw_width, draw_height;
      double scale;
      this.get_draw_size (out draw_width, out draw_height, out scale);

      int draw_x = (widget_width / 2) - (draw_width / 2);
      draw_x = 0;

      ct.scale (scale, scale);
      ct.set_source_surface (this.surface, draw_x / scale, 0);
      ct.fill ();
      ct.restore ();

      var sc = this.get_style_context ();
      sc.render_background (ct, draw_x, 0, draw_width, draw_height);
      sc.render_frame      (ct, draw_x, 0, draw_width, draw_height);
    }

    //else {
      //var sc = this.get_style_context ();
      //double layout_x, layout_y;
      //int layout_w, layout_h;
      //layout.set_text ("%d%%".printf ((int)(media.percent_loaded * 100)), -1);
      //layout.get_size (out layout_w, out layout_h);
      //layout_x = (widget_width / 2.0) - (layout_w / Pango.SCALE / 2.0);
      //layout_y = (widget_height / 2.0) - (layout_h / Pango.SCALE / 2.0);
      //sc.render_layout (ct, layout_x, layout_y, layout);
    //}


    return Gdk.EVENT_PROPAGATE;
  }


  public void start_progress (){}
  public void set_success (){}
  public void set_error (string error_message) {}



  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void get_preferred_height_for_width (int width,
                                                       out int minimum,
                                                       out int natural) {
    int media_width;
    int media_height;

      if (this.surface == null) {
      media_width = MIN_WIDTH;
      media_height = MAX_HEIGHT;
    } else {
      media_width = this.surface.get_width ();
      media_height = this.surface.get_height ();
    }

    double width_ratio = (double)width / (double) media_width;
    int height = int.min (media_height, (int)(media_height * width_ratio));
    height = int.min (MAX_HEIGHT, height);
    minimum = natural = height;
  }

  public override void get_preferred_width (out int minimum,
                                            out int natural) {
    int media_width;
    if (this.surface == null) {
      media_width = 1;
    } else {
      media_width = this.surface.get_width ();
    }

    minimum = int.min (media_width, MIN_WIDTH);
    natural = media_width;
  }

  public override void realize () {
    this.set_realized (true);
    int draw_width;
    int draw_height;
    double scale;

    this.get_draw_size (out draw_width, out draw_height, out scale);

    Gdk.WindowAttr attr = {};
    attr.x = 0;
    attr.y = 0;
    attr.width = draw_width;
    attr.height = draw_height;
    attr.window_type = Gdk.WindowType.CHILD;
    attr.visual = this.get_visual ();
    attr.wclass = Gdk.WindowWindowClass.INPUT_ONLY;
    attr.event_mask = this.get_events () |
                      Gdk.EventMask.BUTTON_PRESS_MASK |
                      Gdk.EventMask.BUTTON_RELEASE_MASK |
                      Gdk.EventMask.TOUCH_MASK |
                      Gdk.EventMask.ENTER_NOTIFY_MASK |
                      Gdk.EventMask.LEAVE_NOTIFY_MASK;

    Gdk.WindowAttributesType attr_mask = Gdk.WindowAttributesType.X |
                                         Gdk.WindowAttributesType.Y;
    Gdk.Window window = this.get_parent_window ();
    this.set_window (window);
    window.ref ();

    this.event_window = new Gdk.Window (window, attr, attr_mask);
    this.register_window (this.event_window);
  }

  public override void unrealize () {
    if (this.event_window != null) {
      this.unregister_window (this.event_window);
      this.event_window.destroy ();
      this.event_window = null;
    }
    base.unrealize ();
  }

  public override void map () {
    base.map ();

    if (this.event_window != null)
      this.event_window.show ();
  }

  public override void unmap () {

    if (this.event_window != null)
      this.event_window.hide ();

    base.unmap ();
  }

  public override void size_allocate (Gtk.Allocation alloc) {
    this.set_allocation (alloc);

    int draw_width;
    int draw_height;
    double scale;

    if (this.get_realized ()) {
      this.get_draw_size (out draw_width, out draw_height, out scale);
      this.event_window.move_resize (alloc.x,    alloc.y,
                                     draw_width, draw_height);
    }
  }



}








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
    this.set_size_request (-1, MultiMediaWidget.MAX_HEIGHT);
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
                                    MultiMediaWidget.MAX_HEIGHT);
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


