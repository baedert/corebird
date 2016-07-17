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
  private double height = 0;
  private bool replies = false;
  public bool replies_available {
    set {
      this.replies = value;
      this.on_replies_available ();
    }
    get { return replies; }
  }
  private int64 start_time;

  construct {
    set_has_window (false);
    get_style_context ().add_class ("reply-indicator");
  }

  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }


  public override void get_preferred_height_for_width (int     width,
                                                       out int min_height,
                                                       out int nat_height) {
    min_height = FINAL_HEIGHT;
    nat_height = FINAL_HEIGHT;
  }

  private void on_replies_available () {
    if (!replies) {
      height = 0.0;
      return;
    }
    start_time = this.get_frame_clock ().get_frame_time ();
    this.add_tick_callback (tick_callback);
  }

  private bool tick_callback (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
    if (!this.get_mapped ()) {
      height = FINAL_HEIGHT;
      this.queue_draw ();
      return false;
    }

    int64 now = frame_clock.get_frame_time ();
    int64 end_time = this.start_time + (750 * 1000); /* .75s */
    double t = 1.0;
    if (now < end_time)
      t = (now - start_time) / (double)(end_time - start_time);

    t = ease_out_cubic (t);

    height = t * FINAL_HEIGHT;
    if (height >= FINAL_HEIGHT) {
      height = FINAL_HEIGHT;
      this.queue_draw ();
      return false;
    }

    this.queue_draw ();
    return true;
  }

  public override bool draw (Cairo.Context ct) {
    if (!replies) {
      return false;
    }
    var style_context = this.get_style_context ();
    int width = this.get_allocated_width ();

    style_context.render_background (ct, 0, 0, width, height);

    return false;
  }
}
