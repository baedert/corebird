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
  private static const int SMALL = 0;
  private static const int LARGE = 1;
  private bool _round = true;
  public bool make_round {
    get {
      return _round;
    }
    set {
      this._round = value;
      this.queue_draw ();
    }
  }
  public bool verified { get; set; default = false; }

  private Cairo.Surface _surface;
  public Cairo.Surface surface {
    get {
      return _surface;
    }
    set {
      if (this._surface != null)
        Twitter.unref_avatar (this._surface);

      this._surface = value;

      if (this._surface != null)
        Twitter.ref_avatar (this._surface);

      this.queue_resize ();
    }
  }



  static Cairo.Surface[] verified_icons;
  static const int[] VERIFIED_SIZES = {12, 18};
  static construct {
    try {
      verified_icons = {
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/assets/verified-small.png"),
          1, null),
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/assets/verified-large.png"),
          1, null),
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/assets/verified-small@2.png"),
          2, null),
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/assets/verified-large@2.png"),
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
    get_style_context ().add_class ("avatar");
  }

  ~AvatarWidget () {
    if (this._surface != null)
      Twitter.unref_avatar (this._surface);
  }


  public override bool draw (Cairo.Context ctx) {
    int width  = this.get_allocated_width ();
    int height = this.get_allocated_height ();

    if (this._surface == null) {
      return false;
    }

    if (width != height) {
      warning ("Avatar with mapped with width %d and height %d", width, height);
    }

    var surface = new Cairo.Surface.similar (ctx.get_target (),
                                             Cairo.Content.COLOR_ALPHA,
                                             width, height);
    var ct = new Cairo.Context (surface);

    ct.rectangle (0, 0, width, height);
    ct.set_source_surface (this._surface, 0, 0);
    ct.fill();

    if (_round) {
      var sc = this.get_style_context ();
      // make it round
      ct.set_operator (Cairo.Operator.DEST_IN);
      ct.arc ((width / 2.0), (height / 2.0),
              (width / 2.0) - 0.5, /* Radius */
              0, /* Angle from */
              2 * Math.PI); /* Angle to */
      ct.fill ();

      // draw outline
      ct.set_operator (Cairo.Operator.OVER);
      Gdk.RGBA border_color = sc.get_border_color (this.get_state_flags ());
      ct.arc ((width / 2.0), (height / 2.0),
              (width / 2.0) - 0.5,
              0,
              2 * Math.PI);
      ct.set_line_width (1.0);
      ct.set_source_rgba (border_color.red, border_color.green, border_color.blue,
                          border_color.alpha);
      ct.stroke ();
    }

    ctx.rectangle (0, 0, width, height);
    ctx.set_source_surface (surface, 0, 0);
    ctx.fill ();


    /* Draw verification indicator */
    if (verified) {
      int index = SMALL;
      if (width > 48)
        index = LARGE;

      int scale_factor = this.get_scale_factor () - 1;
      Cairo.Surface verified_img = verified_icons[scale_factor * 2 + index];
      ctx.rectangle (0, 0, width, height);
      ctx.set_source_surface (verified_img,
                              width - VERIFIED_SIZES[index],
                              0);
      ctx.fill ();
    }

    return false;
  }


  public override void get_preferred_height (out int minimal,
                                             out int natural) {

    if (this._surface == null) {
      minimal = 0;
      natural = 0;
    } else {
      minimal = ((Cairo.ImageSurface)this._surface).get_height ();
      natural = ((Cairo.ImageSurface)this._surface).get_height ();
    }
  }
}


