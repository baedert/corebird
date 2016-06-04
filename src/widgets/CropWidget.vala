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

  private Gdk.Pixbuf? image;
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
  /**
   * Ratio of the width to the height, i.e. (width/height)
   * => values >1.0 for landscape pictures
   */
  public double desired_aspect_ratio { get; set; default = 0.8; }



  construct {
    this.set_events (this.get_events () | Gdk.EventMask.POINTER_MOTION_MASK
                                        | Gdk.EventMask.BUTTON1_MOTION_MASK
                                        | Gdk.EventMask.BUTTON_PRESS_MASK
                                        | Gdk.EventMask.BUTTON_RELEASE_MASK);
    this.motion_notify_event.connect (mouse_motion_cb);
    this.button_press_event.connect (button_press_cb);
    this.button_release_event.connect (button_release_cb);
    this.drag_cursor = new Gdk.Cursor.for_display (this.get_display (),
                                                   Gdk.CursorType.FLEUR);
    this.default_cursor = new Gdk.Cursor.for_display (this.get_display (),
                                                      Gdk.CursorType.ARROW);
    this.resize_cursor = new Gdk.Cursor.for_display (this.get_display (),
                                                     Gdk.CursorType.BOTTOM_RIGHT_CORNER);
    this.image_rect = Gdk.Rectangle ();
    this.selection_rect = Gdk.Rectangle ();
  }


  private bool mouse_motion_cb (Gdk.EventMotion evt) {
    double x = evt.x;
    double y = evt.y;

    /* Resizing */
    if (resize_area_grabbed) {
      resize_selection_rect (x, y);
    }

    /* Dragging the selection */
    if (selection_grabbed) {
      selection_rect.x = (int) evt.x - drag_diff_x;
      selection_rect.y = (int) evt.y - drag_diff_y;

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
      return true;
    }

    if (over_resize_area (x, y) || resize_area_grabbed) {
      resize_area_hovered = true;
      set_cursor (resize_cursor);
      this.queue_draw ();
      return true;
    } else {
      set_cursor (default_cursor);
      resize_area_hovered = false;
      this.queue_draw ();
    }



    /* Check if cursor is over resize position */

    if (cursor_in_selection (x, y)) {
      set_cursor (drag_cursor);
    } else {
      set_cursor (default_cursor);
    }

    return false;
  }

  private bool button_press_cb (Gdk.EventButton evt) {
    if (evt.button != Gdk.BUTTON_PRIMARY) {
      selection_grabbed = false;
      resize_area_grabbed = false;
      return false;
    }

    /* Check for the resize area(s) first */
    if (over_resize_area (evt.x, evt.y)) {
      resize_area_grabbed = true;
      resize_diff_x = (int)evt.x - (selection_rect.x + selection_rect.width);
      resize_diff_y = (int)evt.y - (selection_rect.y + selection_rect.height);
      return true;
    }


    /* Now the selection rect */
    if (cursor_in_selection (evt.x, evt.y)) {
      selection_grabbed = true;
      drag_diff_x = (int)(evt.x - selection_rect.x);
      drag_diff_y = (int)(evt.y - selection_rect.y);
      return true;
    }
    return false;
  }

  private bool button_release_cb (Gdk.EventButton evt) {
    if (selection_grabbed) {
      selection_grabbed = false;
      set_cursor (default_cursor);
      return true;
    }

    if (resize_area_grabbed) {
      resize_area_grabbed = false;
      set_cursor (default_cursor);
      return true;
    }
    return false;
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

  public void set_image (Gdk.Pixbuf image) {
    this.image = image;
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


  public override bool draw (Cairo.Context ct) {
    if (image == null)
      return Gdk.EVENT_PROPAGATE;

    int widget_width  = get_allocated_width ();
    int widget_height = get_allocated_height ();

    ct.set_line_width (1.0);

    /* Draw dark background */
    ct.rectangle (0, 0, widget_width, widget_height);
    ct.set_source_rgba (0.3, 0.3, 0.3, 1.0);
    ct.fill ();

    /* Draw image */
    ct.save ();
    ct.rectangle (image_rect.x, image_rect.y,
                  image_rect.width, image_rect.height);
    ct.scale (current_scale, current_scale);
    Gdk.cairo_set_source_pixbuf (ct, image,
                                 image_rect.x / current_scale,
                                 image_rect.y / current_scale);
    ct.fill ();
    ct.restore ();

    /* Draw selection rectangle border */
    ct.rectangle (selection_rect.x, selection_rect.y,
                  selection_rect.width, selection_rect.height);
    ct.set_source_rgba (1.0, 1.0, 1.0, 1.0);
    ct.stroke ();

    /* Draw resize quad */
    ct.rectangle (selection_rect.x + selection_rect.width - 15,
                  selection_rect.y + selection_rect.height - 15,
                  14.5,
                  14.5);
    if (resize_area_hovered || resize_area_grabbed)
      ct.set_source_rgba (0.0, 0.0, 0.6, 0.7);
    else
      ct.set_source_rgba (1.0, 1.0, 1.0, 0.7);
    ct.fill ();

    return Gdk.EVENT_PROPAGATE;
  }

  private inline void set_cursor (Gdk.Cursor cursor) {
    this.get_window ().set_cursor (cursor);
  }

  private bool cursor_in_selection (double x, double y) {
    return x >= selection_rect.x &&
           x <= selection_rect.x + selection_rect.width &&
           y >= selection_rect.y &&
           y <= selection_rect.y + selection_rect.height;
  }


  public override void size_allocate (Gtk.Allocation alloc) {
    base.size_allocate (alloc);
    calculate_image_rect ();
    restrict_selection_size ();
  }

  private void calculate_image_rect () {
    int widget_width  = this.get_allocated_width ();
    int widget_height = this.get_allocated_height ();

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
