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

class AddImageButton : Gtk.Widget {
  private const int MIN_WIDTH  = 40;
  private const int MAX_HEIGHT = 150;
  private const int MIN_HEIGHT = 100;
  private const int ICON_SIZE  = 32;
  public string image_path;
  public Gsk.Texture? texture = null;

  public signal void deleted ();

  private double delete_factor = 1.0;
  private uint64 delete_transition_start;

  construct {
    this.set_has_window (false);
  }

  public void get_draw_size (out int    width,
                             out int    height,
                             out double scale) {
    if (this.texture == null) {
      width  = 0;
      height = 0;
      scale  = 0.0;
      return;
    }

    width  = this.get_allocated_width ();
    height = this.get_allocated_height ();
    double scale_x = (double)width / this.texture.get_width ();
    double scale_y = (double)height / this.texture.get_height ();

    scale = double.min (double.min (scale_x, scale_y), 1.0) * delete_factor;

    width  = (int)(this.texture.get_width ()  * scale);
    height = (int)(this.texture.get_height () * scale);
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    if (this.texture == null)
      return;

    /* Draw thumbnail */
    int draw_width, draw_height;
    double scale;

    this.get_draw_size (out draw_width, out draw_height, out scale);


    if (draw_width > 0 && draw_height > 0) {
      Graphene.Rect bounds = {};
      bounds.origin.x = 0;
      bounds.origin.y = 0;
      bounds.size.width = draw_width;
      bounds.size.height = draw_height;

      snapshot.append_texture (texture, bounds, "Texture");
    }

    // TODO: What to do here?
    //style_context.render_check (ct,
                                //(widget_width / 2.0) - (ICON_SIZE / 2.0),
                                //(widget_height / 2.0) - (ICON_SIZE / 2.0),
                                //ICON_SIZE,
                                //ICON_SIZE);
  }

  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void measure (Gtk.Orientation orientation,
                                int             for_size,
                                out int         minimum,
                                out int         natural,
                                out int         minimum_baseline,
                                out int         natural_baseline) {
    int media_width;
    int media_height;

    if (this.texture == null) {
      media_width = MIN_WIDTH;
      media_height = MAX_HEIGHT;
    } else {
      media_width = this.texture.get_width ();
      media_height = this.texture.get_height ();
    }

    if (orientation == Gtk.Orientation.HORIZONTAL) {
      if (for_size == -1) {
        minimum = (int)(int.min (media_width, MIN_WIDTH) * delete_factor);
        natural = (int)(media_width * delete_factor);
      } else {
        double height_ratio = (double)for_size / (double) media_height;
        int width = int.min (media_width, (int)(media_width * height_ratio));
        width = int.max (MIN_WIDTH, width);
        minimum = natural = (int)(width * this.delete_factor);
      }

    } else {
      if (for_size == -1) {
        minimum = (int)(int.min (media_height, MIN_HEIGHT) * delete_factor);
        natural = (int)(media_height * delete_factor);
      } else {
        double width_ratio = (double)for_size / (double) media_width;
        int height = int.min (media_height, (int)(media_height * width_ratio));
        height = int.min (MAX_HEIGHT, height);
        minimum = MIN_HEIGHT;
        natural = int.max (minimum, (int)(height * this.delete_factor));
      }
    }

    minimum_baseline = -1;
    natural_baseline = -1;
  }

  private bool delete_tick_cb (Gtk.Widget     widget,
                               Gdk.FrameClock frame_clock) {
    uint64 now = frame_clock.get_frame_time ();

    double t = (now - this.delete_transition_start) / (double)(TRANSITION_DURATION* 1);

    t = ease_out_cubic (t);
    this.delete_factor = 1.0 - t;
    this.queue_resize ();

    if (t >= 1.0) {
      this.delete_factor = 1.0;
      this.deleted ();
      return GLib.Source.REMOVE;
    }

    return GLib.Source.CONTINUE;
  }

  public void start_remove () {
    if (!this.get_realized ()) return;

    this.delete_transition_start = this.get_frame_clock ().get_frame_time ();
    this.add_tick_callback (delete_tick_cb);
  }
}
