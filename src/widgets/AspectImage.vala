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

        if (this.pixbuf_surface != null) {
          this.old_surface = this.pixbuf_surface;
          this.old_texture = this.pixbuf_texture;
        }

        this.pixbuf_surface = (Cairo.ImageSurface)Gdk.cairo_surface_create_from_pixbuf (value, 1,
                                                                                        this.get_window ());
        this.pixbuf_texture = Cb.Utils.surface_to_texture (this.pixbuf_surface, 1);
        bg_color.alpha = 0.0;
      }
      this.queue_draw ();
    }
  }
  public string color_string {
    set {
      bg_color.parse (value);
    }
  }

  private Gdk.RGBA bg_color;
  private Cairo.Surface? old_surface;
  private Cairo.ImageSurface? pixbuf_surface = null;
  private Gdk.Texture? old_texture = null;
  private Gdk.Texture? pixbuf_texture = null;


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
    double t = (double)(now - start_time) / TRANSITION_DURATION;

    if (t >= 1.0) {
      t = 1.0;
      in_transition = false;
    }

    this.alpha = ease_out_cubic (t);
    this.queue_draw ();

    return t < 1.0;
  }

  public override void measure (Gtk.Orientation orientation,
                                int             for_size,
                                out int         minimum,
                                out int         natural,
                                out int         minimum_baseline,
                                out int         natural_baseline) {

    if (orientation == Gtk.Orientation.HORIZONTAL) {
      base.measure (orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline);
    } else {
      if (pixbuf_surface != null) {
        minimum = pixbuf_surface.get_height ();
        natural = pixbuf_surface.get_height ();
      } else {
        minimum = 0;
        natural = 0;
      }
    }

    minimum_baseline = -1;
    natural_baseline = -1;
  }

  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    Graphene.Rect bounds = {};
    int width  = get_width ();
    int height = get_height ();

    bounds.origin.x = 0;
    bounds.origin.y = 0;
    bounds.size.width = width;
    bounds.size.height = height;

    // TODO: The old behavior here was to never scale the surface down, so keep scale >= 1.0

    if (this.old_texture != null) {
      snapshot.append_texture (old_texture, bounds, "Old Texture");
    } else if (bg_color.alpha > 0.0) {
      snapshot.append_color (bg_color, bounds, "Background color");
    } else {
      alpha = 1.0;
    }

    if (in_transition)
      snapshot.push_opacity (alpha, "Alpha");

    if (bg_color.alpha == 0.0) {
      snapshot.append_texture (this.pixbuf_texture, bounds, "Pixbuf texture");
    } else {
      snapshot.append_color (bg_color, bounds, "Color");
    }

    if (in_transition)
      snapshot.pop ();
}
}
