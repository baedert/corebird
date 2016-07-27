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

class AvatarWidget : Gtk.Widget {
  private const int SMALL = 0;
  private const int LARGE = 1;
  private bool _round = true;
  public bool make_round {
    get {
      return _round;
    }
    set {
      if (value) {
        this.get_style_context ().add_class ("avatar-round");
      } else {
        this.get_style_context ().remove_class ("avatar-round");
      }

      this._round = value;
      this.queue_draw ();
    }
  }
  public bool verified { get; set; default = false; }

  private Cairo.ImageSurface _surface;
  public Cairo.Surface surface {
    get {
      return _surface;
    }
    set {
      if (this._surface == value) return;

      bool animate = false;

      if (this._surface != null)
        Twitter.get ().unref_avatar (this._surface);
      else
        animate = true;

      this._surface = (Cairo.ImageSurface)value;

      if (this._surface != null) {
        Twitter.get ().ref_avatar (this._surface);
        if (animate)
          this.start_animation ();
      }

      this.queue_draw ();
    }
  }
  private double alpha = 1.0f;
  private int64 start_time;


  static Cairo.Surface[] verified_icons;
  const int[] VERIFIED_SIZES = {12, 18};
  static construct {
    try {
      verified_icons = {
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/verified-small.png"),
          1, null),
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/verified-large.png"),
          1, null),
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/verified-small@2.png"),
          2, null),
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/verified-large@2.png"),
          2, null)
      };
    } catch (GLib.Error e) {
      critical (e.message);
    }
  }

  construct {
    this.set_has_window (false);
    Settings.get ().bind ("round-avatars", this, "make_round",
                          GLib.SettingsBindFlags.DEFAULT);
    this.get_style_context ().add_class ("avatar");
  }

  ~AvatarWidget () {
    if (this._surface != null)
      Twitter.get ().unref_avatar (this._surface);
  }


  private void start_animation () {
    if (!this.get_realized ())
      return;

    alpha = 0.0;
    this.start_time = this.get_frame_clock ().get_frame_time ();
    this.add_tick_callback (fade_in_cb);
  }

  private bool fade_in_cb (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
    int64 now = frame_clock.get_frame_time ();
    double t = (now - start_time) / (double) TRANSITION_DURATION;

    if (t >= 1.0) {
      t = 1.0;
    }

    this.alpha = ease_out_cubic (t);
    this.queue_draw ();

    return t < 1.0;
  }



  public override bool draw (Cairo.Context ctx) {
    int width  = this.get_allocated_width ();
    int height = this.get_allocated_height ();

    if (this._surface == null) {
      return Gdk.EVENT_PROPAGATE;
    }

    double surface_scale;
    this._surface.get_device_scale (out surface_scale, out surface_scale);

    if (width != height) {
      warning ("Avatar with mapped with width %d and height %d", width, height);
    }

    var surface = new Cairo.Surface.similar (ctx.get_target (),
                                             Cairo.Content.COLOR_ALPHA,
                                             width, height);
    var ct = new Cairo.Context (surface);

    double scale = (double)this.get_allocated_width () /
                   (double) (this._surface.get_width () / surface_scale);

    ct.rectangle (0, 0, width, height);
    ct.scale (scale, scale);
    ct.set_source_surface (this._surface, 0, 0);
    ct.fill();

    if (_round) {
      ct.scale (1.0/scale, 1.0/scale);
      ct.set_operator (Cairo.Operator.DEST_IN);
      ct.arc ((width / 2.0), (height / 2.0),
              (width / 2.0) - 0.5, // Radius
              0,                   //Angle from
              2 * Math.PI);        // Angle to
      ct.fill ();

      this.get_style_context ().render_frame (ctx, 0, 0, width, height);
    }

    ctx.set_source_surface (surface, 0, 0);
    ctx.paint_with_alpha (alpha);

    if (verified) {
      int index = SMALL;
      if (width > 48)
        index = LARGE;

      int scale_factor = this.get_scale_factor () - 1;
      Cairo.Surface verified_img = verified_icons[scale_factor * 2 + index];
      ctx.set_source_surface (verified_img,
                              width - VERIFIED_SIZES[index],
                              0);
      ctx.paint_with_alpha (this.alpha);
    }

    return Gdk.EVENT_PROPAGATE;
  }

}


