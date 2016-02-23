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

const int TOP    = 1;
const int BOTTOM = 2;
const int NONE   = 0;

public class ScrollWidget : Gtk.ScrolledWindow {
  public signal void scrolled_to_start(double value);
  public signal void scrolled_to_end();
  private double upper_cache;
  private double value_cache;
  private int balance = NONE;
  public double end_diff {get; set; default = 200;}
  private ulong scroll_down_id;
  private ulong scroll_up_id;
  public bool scrolled_down {
    get {
      return vadjustment.value >= vadjustment.upper - vadjustment.page_size - 5;
    }
  }
  public bool scrolled_up {
    get {
      return vadjustment.value <= 5;
    }
  }
  //Transition times
  private int64 start_time;
  private int64 end_time;
  private double transition_diff;
  private double transition_start_value;

  construct {
    vadjustment.notify["upper"].connect (keep_upper_func);
    vadjustment.notify["value"].connect (keep_value_func);
  }

  private void keep_upper_func() { // {{{
    double upper = vadjustment.upper;
    if (balance == TOP){
      double inc = (upper - upper_cache);

      this.vadjustment.value += inc;
      balance = NONE;
    }
    this.upper_cache = vadjustment.upper;
    this.value_cache = vadjustment.value;
  } // }}}

  private void keep_value_func () { // {{{
    // Call the scrolled_to_top signal if necessary
    if(vadjustment.value < 10.0) {
      scrolled_to_start(vadjustment.value);
    }

    double max = vadjustment.upper - vadjustment.page_size;
    if (vadjustment.value >= max - end_diff)
      scrolled_to_end ();

    double upper = vadjustment.upper;
    if (balance == BOTTOM) {
      double inc = (upper - upper_cache);

      this.vadjustment.value -= inc;
      balance = NONE;
    }
    this.upper_cache = vadjustment.upper;
    this.value_cache = vadjustment.value;
  } // }}}

  public void balance_next_upper_change (int mode) {
    balance = mode;
  }


  /**
   * TODO: Update scroll_down_next
   * Scroll to the very top of the scrolled window once the next
   * size_allocate occurs.
   * This will use a transition if the correct Gtk+ settings is set
   * to true.
   *
   * @param animate    Whether to animate/transition the change or not (default: true)
   */
  public void scroll_up_next (bool animate = true,
                              bool force_start = false) { // {{{
    if (!this.get_mapped ()) {
      this.vadjustment.value = 0;
      return;
    }

    // TODO: I really can't stand the duplication here
    if (force_start) {
      if (Gtk.Settings.get_default ().gtk_enable_animations && animate) {
        this.start_time = this.get_frame_clock ().get_frame_time ();
        this.end_time = start_time + TRANSITION_DURATION;
        this.transition_diff = - this.vadjustment.value;
        this.transition_start_value = vadjustment.value;
        this.add_tick_callback (scroll_up_tick_cb);
      } else {
        this.vadjustment.value = 0;
      }
    } else {
      if (scroll_up_id != 0) {
        this.transition_diff = -this.vadjustment.value;
        this.transition_start_value = this.vadjustment.value;
        return;
      }
      scroll_up_id = this.vadjustment.notify["upper"].connect (() => {
        if (Gtk.Settings.get_default ().gtk_enable_animations && animate) {
          this.start_time = this.get_frame_clock ().get_frame_time ();
          this.end_time = start_time + TRANSITION_DURATION;
          this.transition_diff = - this.vadjustment.value;
          this.transition_start_value = vadjustment.value;
          this.add_tick_callback (scroll_up_tick_cb);
        } else {
          this.vadjustment.value = 0;
        }
        this.vadjustment.disconnect (scroll_up_id);
        this.scroll_up_id = 0;
      });
    }
  } // }}}

  /**
   * Scroll to the very end of the scrolled window once the next
   * size_alocate occurs.
   * This will use a transition if the correct Gtk+ settings is set
   * to true
   *
   * @param animate Whether to animate/transition the change or not (default: true)
   * @param force_wait If this is set to true, we will wait for the next size_allocate
   *                   event, even if the widget is unmapped (default: false).
   */
  public void scroll_down_next (bool animate = true, bool force_wait = false) { // {{{
    if (!this.get_mapped () && !force_wait) {
      this.vadjustment.value = this.vadjustment.upper - this.vadjustment.page_size;
      return;
    }

    if (this.scroll_down_id != 0)
      return;

    scroll_down_id = this.size_allocate.connect (() => {
      if (Gtk.Settings.get_default ().gtk_enable_animations && animate) {
        this.start_time = this.get_frame_clock ().get_frame_time ();
        this.end_time = start_time + TRANSITION_DURATION;
        this.transition_diff = (vadjustment.upper - vadjustment.page_size - vadjustment.value);
        this.transition_start_value = this.vadjustment.value;
        this.add_tick_callback (scroll_up_tick_cb);
      } else {
        this.vadjustment.value = this.vadjustment.upper - this.vadjustment.page_size;
      }
      this.disconnect (scroll_down_id);
      this.scroll_down_id = 0;
    });
  } // }}}


  /* This is essentially a straight-up vala port of the transition code in
     GtkStack/GtkRevealer */
  private bool scroll_up_tick_cb (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
    if (!this.get_mapped ()) {
      vadjustment.value = transition_start_value + transition_diff;
      return false;
    }

    int64 now = frame_clock.get_frame_time ();

    double t = 1.0;
    if (now < this.end_time)
      t = (now - start_time) / (double)(end_time - start_time);

    t = ease_out_cubic (t);

    this.vadjustment.value = transition_start_value + (t * transition_diff);
    if (this.vadjustment.value <= 0 || now >= end_time) {
      this.queue_draw ();
      return false;
    }

    return true;
  }

}
