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


class AspectImage : Gtk.Widget {
  public Gdk.Pixbuf pixbuf  {
    set {
      if (value != null) {

        if (value != Twitter.no_banner) {
          start_animation ();
        }

        if (this.pixbuf_surface != null)
          this.old_surface = this.pixbuf_surface;

        this.pixbuf_surface = (Cairo.ImageSurface)Gdk.cairo_surface_create_from_pixbuf (value, 1,
                                                                                        this.get_window ());
      }
      this.queue_draw ();
    }
  }
  private double _scale = 1.0;
  public double scale {
    get {
      return _scale;
    }
    set {
      if (value > 1.0)
        value = 1.0;

      this._scale = value;
      this.queue_resize ();
    }
  }

  private Cairo.Surface? old_surface;
  private Cairo.ImageSurface pixbuf_surface;


  public AspectImage () {}

  construct {
    set_has_window (false);
  }

  private void start_animation () {
    if (!this.get_realized ())
      return;

    alpha = 0.0;
    in_transition = true;
    this.start_time = this.get_frame_clock ().get_frame_time ();
    this.add_tick_callback (fade_in_cb);
  }

  private double alpha = 0.0;
  private int64 start_time;
  private bool in_transition = false;
  private bool fade_in_cb (Gtk.Widget widget, Gdk.FrameClock frame_clock) {

    int64 now = frame_clock.get_frame_time ();
    double t = (now - start_time) / TRANSITION_DURATION;

    if (t >= 1.0) {
      t = 1.0;
      in_transition = false;
    }

    this.alpha = ease_out_cubic (t);
    this.queue_draw ();

    return t < 1.0;
  }

  public override void get_preferred_height_for_width (int width,
                                                       out int min_height,
                                                       out int nat_height) {
    if (pixbuf_surface == null) {
      min_height = 0;
      nat_height = 1;
      return;
    }

    double scale_x = width  / (double)pixbuf_surface.get_width ();
    if (scale_x > 1)
      scale_x = 1;
    double final_height = scale_x * pixbuf_surface.get_height ();

    min_height = (int)(final_height * _scale);
    nat_height = (int)(final_height * _scale);
  }


  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override bool draw (Cairo.Context ct) {
    if (this.pixbuf_surface == null)
      return Gdk.EVENT_PROPAGATE;


    int width  = get_allocated_width ();
    int height = get_allocated_height ();

    double scale_x = width  / (double)pixbuf_surface.get_width ();
    double scale_y = scale_x;
    int y = 0;

    /* Never scale it vertically down, instead move it up */
    if (scale_y > 1) {
      scale_y = 1;
    }

    int view_height = (int)(pixbuf_surface.get_height () * scale_y);
    y = height - view_height;


    ct.rectangle (0, 0, width, view_height);
    ct.scale (scale_x, scale_y);


    ct.push_group ();

    if (this.old_surface != null) {
      ct.set_source_surface (this.old_surface, 0, 0);
      ct.paint ();
    } else
      alpha = 1.0;


    ct.set_source_surface (this.pixbuf_surface, 0, 0);
    if (in_transition)
      ct.paint_with_alpha (alpha);
    else
      ct.paint ();

    ct.pop_group_to_source ();

    ct.set_operator (Cairo.Operator.OVER);
    ct.paint ();

    return Gdk.EVENT_PROPAGATE;
  }
}
