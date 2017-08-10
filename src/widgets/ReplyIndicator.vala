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

public class ReplyIndicator : Gtk.Widget {
  private const int FINAL_HEIGHT = 5;
  private bool replies = false;
  public bool replies_available {
    set {
      this.replies = value;
      this.on_replies_available ();
    }
    get { return replies; }
  }
  private int64 start_time;
  private double show_factor = 0.0;

  construct {
    set_has_window (false);
  }

  static construct {
    set_css_name ("replyindicator");
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

    if (orientation == Gtk.Orientation.HORIZONTAL) {
      base.measure (orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline);
    } else {
      minimum = (int)(FINAL_HEIGHT * show_factor);
      natural = (int)(FINAL_HEIGHT * show_factor);
    }

    minimum_baseline = -1;
    natural_baseline = -1;
  }



  private void on_replies_available () {
    if (!replies) {
      show_factor = 0.0;
      queue_resize ();
      return;
    }
    start_time = this.get_frame_clock ().get_frame_time ();
    this.add_tick_callback (tick_callback);
  }

  private bool tick_callback (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
    if (!this.get_mapped ()) {
      this.queue_resize ();
      return GLib.Source.REMOVE;
    }

    int64 now = frame_clock.get_frame_time ();
    int64 end_time = this.start_time + TRANSITION_DURATION;
    double t = 1.0;
    if (now < end_time)
      t = (now - start_time) / (double)(end_time - start_time);

    t = ease_out_cubic (t);
    this.show_factor = t;
    this.queue_resize ();

    if (t >= 1.0) {
      return GLib.Source.REMOVE;
    }

    return GLib.Source.CONTINUE;
  }
}
