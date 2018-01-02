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

class CropWidget : Gtk.DrawingArea {
  private const int MIN_SIZE = 48;

  private Gtk.GestureDrag drag_gesture;
  private Gdk.Pixbuf? image;
  private Cairo.Surface? surface;
  private Gdk.Rectangle selection_rect;
  private Gdk.Rectangle image_rect;
  private Gdk.Cursor drag_cursor;
  private Gdk.Cursor default_cursor;
  private Gdk.Cursor resize_cursor;
  private bool selection_grabbed = false;
  private bool resize_area_grabbed = false;
  private int drag_diff_x = 0;
  private int drag_diff_y = 0;
  private int resize_diff_x = 0;
  private int resize_diff_y = 0;
  private bool resize_area_hovered = false;
  private double current_scale = 1.0;
  private int min_width  = MIN_SIZE;
  private double drag_start_x;
  private double drag_start_y;
  /**
   * Ratio of the width to the height, i.e. (width/height)
   * => values >1.0 for landscape pictures
   */
  public double desired_aspect_ratio { get; set; default = 0.8; }



  construct {
    this.motion_notify_event.connect (mouse_motion_cb);
    this.drag_cursor = new Gdk.Cursor.from_name ("grabbing", null);
    this.default_cursor = new Gdk.Cursor.from_name ("default", null);
    this.resize_cursor = new Gdk.Cursor.from_name ("se-resize", null);
    this.image_rect = Gdk.Rectangle ();
    this.selection_rect = Gdk.Rectangle ();

    this.drag_gesture = new Gtk.GestureDrag (this);
    this.drag_gesture.set_button (Gdk.BUTTON_PRIMARY);
    this.drag_gesture.drag_begin.connect (drag_gesture_begin_cb);
    this.drag_gesture.drag_end.connect (drag_gesture_end_cb);
    this.drag_gesture.drag_update.connect (drag_gesture_update_cb);
  }

  private bool mouse_motion_cb (Gdk.Event event) {
    double x, y;
    /* Just check whether the cursor is over the drag or resize area (or not)
       and change the cursor accordingly */

    event.get_coords (out x, out y);

    if (over_resize_area (x, y)) {
      set_cursor (resize_cursor);
      resize_area_hovered = true;
      queue_draw ();
      return false; /* Don't check resize area */
    } else if (resize_area_hovered) {
      resize_area_hovered = false;
      set_cursor (default_cursor);
      queue_draw ();
    }


    if (cursor_in_selection (x, y)) {
      set_cursor (drag_cursor);
    } else {
      set_cursor (default_cursor);
    }

    return false;
  }

  private void drag_gesture_update_cb (Gtk.GestureDrag gesture,
                                       double          offset_x,
                                       double          offset_y) {
    double x = drag_start_x + offset_x; // XXX start_x + offset_x ?
    double y = drag_start_y + offset_y;

    /* Resizing */
    if (resize_area_grabbed) {
      resize_selection_rect (x, y);
    }

    /* Dragging the selection */
    if (selection_grabbed) {
      selection_rect.x = (int) x - drag_diff_x;
      selection_rect.y = (int) y - drag_diff_y;

      /* Limit to image boundaries */
      if (selection_rect.x < image_rect.x)
        selection_rect.x = image_rect.x;

      if (selection_rect.y < image_rect.y)
        selection_rect.y = image_rect.y;

      if (selection_rect.x + selection_rect.width > image_rect.x + image_rect.width)
        selection_rect.x = image_rect.x + image_rect.width - selection_rect.width;

      if (selection_rect.y + selection_rect.height > image_rect.y + image_rect.height)
        selection_rect.y = image_rect.y + image_rect.height - selection_rect.height;

      this.queue_draw ();
      return;
    }
  }

  private void drag_gesture_begin_cb (Gtk.GestureDrag gesture,
                                      double          x,
                                      double          y) {
    this.drag_start_x = x;
    this.drag_start_y = y;

    /* Check for the resize area(s) first */
    if (over_resize_area (x, y)) {
      resize_area_grabbed = true;
      resize_diff_x = (int)x - (selection_rect.x + selection_rect.width);
      resize_diff_y = (int)y - (selection_rect.y + selection_rect.height);
      gesture.set_state (Gtk.EventSequenceState.CLAIMED);
      set_cursor (resize_cursor);
      return;
    }

    /* Now the selection rect */
    if (cursor_in_selection (x, y)) {
      selection_grabbed = true;
      drag_diff_x = (int)(x - selection_rect.x);
      drag_diff_y = (int)(y - selection_rect.y);
      gesture.set_state (Gtk.EventSequenceState.CLAIMED);
      set_cursor (drag_cursor);
      return;
    }

    gesture.set_state (Gtk.EventSequenceState.DENIED);
  }

  private void drag_gesture_end_cb (Gtk.GestureDrag gesture,
                                    double          offset_x,
                                    double          offset_y) {
    if (selection_grabbed) {
      selection_grabbed = false;
      set_cursor (default_cursor);
      return;
    }

    if (resize_area_grabbed) {
      resize_area_grabbed = false;
      set_cursor (default_cursor);
      return;
    }
  }

  private inline void restrict_selection_size () {
    if (selection_rect.width > image_rect.width)
      selection_rect.width = image_rect.width;

    if (selection_rect.height > image_rect.height)
      selection_rect.height = image_rect.height;


    if (selection_rect.width < (min_width * current_scale)) {
      selection_rect.width = (int)(min_width * current_scale);
      selection_rect.height = (int)(min_width * current_scale / desired_aspect_ratio);
    }

    if (selection_rect.x < image_rect.x)
      selection_rect.x = image_rect.x;

    if (selection_rect.y < image_rect.y)
      selection_rect.y = image_rect.y;


    if (selection_rect.x + selection_rect.width > image_rect.x + image_rect.width)
      selection_rect.x = image_rect.x + image_rect.width - selection_rect.width;

    if (selection_rect.y + selection_rect.height > image_rect.y + image_rect.height)
      selection_rect.y = image_rect.y + image_rect.height - selection_rect.height;

  }

  private void resize_selection_rect (double x, double y) {

    if (!resize_area_grabbed)
      return;

    int max_width = int.min (image_rect.width,
                             int.min ((int)(image_rect.width),
                                      (int)(image_rect.height * desired_aspect_ratio)));

    int new_width  = (int)x - selection_rect.x - resize_diff_x;
    int new_height = (int)(new_width / desired_aspect_ratio);

    if (new_width <= max_width) {
      selection_rect.width = new_width;
      selection_rect.height = new_height;
    } else {
      selection_rect.width = max_width;
      //message ("%d", selection_rect.width);
      //message ("%f", image_rect.width / desired_aspect_ratio);
      selection_rect.height = (int)(max_width / desired_aspect_ratio);
    }

    restrict_selection_size ();

    this.queue_draw ();
  }

  public void set_image (Gdk.Pixbuf? image) {
    this.image = image;
    if (image != null)
      this.surface = Gdk.cairo_surface_create_from_pixbuf (image, this.get_scale_factor (), null);
    calculate_image_rect ();

    /* Place the selection rect initially, using the maximum size
       given the desired_aspect_ratio */

    selection_rect.width = image_rect.width;
    selection_rect.height = (int)(selection_rect.width / desired_aspect_ratio);

    if (selection_rect.height > image_rect.height) {
      selection_rect.height = image_rect.height;
      selection_rect.width = (int)(selection_rect.height * desired_aspect_ratio);
    }

    selection_rect.x = image_rect.x + ((image_rect.width - selection_rect.width) / 2);
    selection_rect.y = image_rect.y + ((image_rect.height - selection_rect.height) / 2);

    restrict_selection_size ();
    this.queue_draw ();
  }


  public override void snapshot (Gtk.Snapshot snapshot) {
    if (image == null)
      return;

    int widget_width  = get_width ();
    int widget_height = get_height ();

    Graphene.Rect bounds = {};
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    bounds.size.width = widget_width;
    bounds.size.height = widget_height;


    /* Draw dark background */
    Gdk.RGBA bg_color = {0.3, 0.3, 0.3, 1.0};
    snapshot.append_color (bg_color, bounds, "Background Color");

    /* Draw image */
    Graphene.Rect image_bounds = {};
    image_bounds.origin.x = image_rect.x;
    image_bounds.origin.y = image_rect.y;
    image_bounds.size.width = image_rect.width;
    image_bounds.size.height = image_rect.height;
    var texture = Cb.Utils.surface_to_texture (this.surface,
                                               this.get_scale_factor ());
    snapshot.append_texture (texture, image_bounds, "Crop Texture");

    /* Draw half-transparent dark over the non-selected part of the image */
    Graphene.Rect dark_bounds = {};
    Gdk.RGBA dark = { 0.0, 0.0, 0.0, 0.5};

    /* Left */
    dark_bounds.origin.x = image_rect.x;
    dark_bounds.origin.y = image_rect.y;
    dark_bounds.size.width = selection_rect.x - image_rect.x;
    dark_bounds.size.height = image_rect.height;
    snapshot.append_color (dark, dark_bounds, "Dark Left");

    /* Top */
    dark_bounds.origin.x = selection_rect.x;
    dark_bounds.origin.y = image_rect.y;
    dark_bounds.size.width = selection_rect.width;
    dark_bounds.size.height = selection_rect.y - image_rect.y;
    snapshot.append_color (dark, dark_bounds, "Dark Top");

    /* Right */
    dark_bounds.origin.x = selection_rect.x + selection_rect.width;
    dark_bounds.origin.y = image_rect.y;
    dark_bounds.size.width = image_rect.x + image_rect.width - (selection_rect.x + selection_rect.width);
    dark_bounds.size.height = image_rect.height;
    snapshot.append_color (dark, dark_bounds, "Dark Right");

    /* Bottom */
    dark_bounds.origin.x = selection_rect.x;
    dark_bounds.origin.y = selection_rect.y + selection_rect.height;
    dark_bounds.size.width = selection_rect.width;
    dark_bounds.size.height = image_rect.y + image_rect.height - (selection_rect.y + selection_rect.height);
    snapshot.append_color (dark, dark_bounds, "Dark Top");



    /* Draw selection rectangle */
    Gdk.RGBA selection_color = {1.0, 1.0, 1.0, 1.0};
    int stroke_width = 2;
    Graphene.Rect selection_bounds = {};

    /* Left */
    selection_bounds.origin.x = selection_rect.x;
    selection_bounds.origin.y = selection_rect.y;
    selection_bounds.size.width = stroke_width;
    selection_bounds.size.height = selection_rect.height;
    snapshot.append_color (selection_color, selection_bounds, "Selection Rect Left");

    /* Top */
    selection_bounds.origin.x = selection_rect.x;
    selection_bounds.origin.y = selection_rect.y;
    selection_bounds.size.width = selection_rect.width;
    selection_bounds.size.height = stroke_width;
    snapshot.append_color (selection_color, selection_bounds, "Selection Rect Top");

    /* Right */
    selection_bounds.origin.x = selection_rect.x + selection_rect.width - stroke_width;
    selection_bounds.origin.y = selection_rect.y;
    selection_bounds.size.width = stroke_width;
    selection_bounds.size.height = selection_rect.height;
    snapshot.append_color (selection_color, selection_bounds, "Selection Rect Right");

    /* Bottom */
    selection_bounds.origin.x = selection_rect.x;
    selection_bounds.origin.y = selection_rect.y + selection_rect.height - stroke_width;
    selection_bounds.size.width = selection_rect.width;
    selection_bounds.size.height = stroke_width;
    snapshot.append_color (selection_color, selection_bounds, "Selection Rect Bottom");

    /* Resize quad */
    Gdk.RGBA quad_color = {0.0, 0.0, 0.6, 0.7};
    int quad_size = 15;
    Graphene.Rect quad_bounds = {};

    quad_bounds.origin.x = selection_rect.x + selection_rect.width - quad_size;
    quad_bounds.origin.y = selection_rect.y + selection_rect.height - quad_size;
    quad_bounds.size.width = quad_size;
    quad_bounds.size.height = quad_size;

    snapshot.append_color (quad_color, quad_bounds, "Resize quad");
  }

  private bool cursor_in_selection (double x, double y) {
    return x >= selection_rect.x &&
           x <= selection_rect.x + selection_rect.width &&
           y >= selection_rect.y &&
           y <= selection_rect.y + selection_rect.height;
  }


  public override void size_allocate (Gtk.Allocation alloc, int baseline, out Gtk.Allocation out_clip) {
    calculate_image_rect ();
    restrict_selection_size ();

    out_clip = alloc;
  }

  private void calculate_image_rect () {
    int widget_width  = this.get_width ();
    int widget_height = this.get_height ();

    if (this.image == null) {
      return;
    }

    /* current_scale the image down */
    if (image.get_width () > image.get_height ()) {
      current_scale = (double) widget_width / image.get_width ();
    } else {
      current_scale = (double) widget_height / image.get_height ();
    }

    if (image.get_width () * current_scale > widget_width)
      current_scale = (double) widget_width / image.get_width ();

    if (image.get_height () * current_scale > widget_height)
      current_scale = (double) widget_height / image.get_height ();

    /* Cap at 1.0 */
    if (current_scale > 1.0)
      current_scale = 1.0;


    this.image_rect.width  = (int)(this.image.get_width () * current_scale);
    this.image_rect.height = (int)(this.image.get_height () * current_scale);
    this.image_rect.x      = (widget_width - image_rect.width) / 2;
    this.image_rect.y      = (widget_height - image_rect.height) / 2;
  }

  private bool over_resize_area (double x, double y) {

    if (x > selection_rect.x + selection_rect.width  - 15 &&
        x < selection_rect.x + selection_rect.width  + 5  &&
        y > selection_rect.y + selection_rect.height - 15 &&
        y < selection_rect.y + selection_rect.height + 5) {
      return true;
    }

    return false;
  }

  public Gdk.Pixbuf get_cropped_image () {
    int absolute_x = (int)((selection_rect.x - image_rect.x) / current_scale);
    int absolute_y = (int)((selection_rect.y - image_rect.y) / current_scale);
    int absolute_w = (int)(selection_rect.width / current_scale);
    int absolute_h = (int)(selection_rect.height / current_scale);

    Gdk.Pixbuf final_image = new Gdk.Pixbuf (Gdk.Colorspace.RGB,
                                             this.image.get_has_alpha (),
                                             8,
                                             absolute_w,
                                             absolute_h);

    this.image.copy_area (absolute_x,
                          absolute_y,
                          absolute_w,
                          absolute_h,
                          final_image,
                          0,
                          0);

    return final_image;
  }

  public void set_min_size (int min_width) {
    this.min_width = min_width;
  }
}
