/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2016 Timm Bäder
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

class TouchStack : Gtk.Container {
  private Gdk.Window? event_window = null;
  private Gtk.Box box;
  private Gtk.GestureDrag drag_gesture;
  private double drag_start_offset = 0.0;
  private double drag_offset = 0.0;

  private double transition_end_offset;
  private double transition_start_offset;
  private double transition_start_time;

  public signal void child_changed (int new_index);

  construct {
    this.set_has_window (false);
    this.box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
    this.drag_gesture = new Gtk.GestureDrag (this);
    this.drag_gesture.drag_begin.connect (drag_begin_cb);
    this.drag_gesture.drag_update.connect (drag_update_cb);
    this.drag_gesture.drag_end.connect (drag_end_cb);
    box.show ();
    box.set_parent (this);
  }

  private void drag_begin_cb (double start_x, double start_y) {
    this.drag_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
    this.drag_start_offset = this.drag_offset;
  }

  private void drag_end_cb (double offset_x, double offset_y) {
    int child_width = box.get_children ().nth_data (0).get_allocated_width ();
    int child_index = (-(int)this.drag_offset + (child_width / 2)) / child_width;

    this.transition_start_offset = this.drag_offset;
    this.transition_end_offset   = - (child_index * child_width);
    this.start_transition ();
  }

  private bool transition_cb (Gtk.Widget     widget,
                              Gdk.FrameClock frame_clock) {

    if (!this.get_mapped ()) {
      this.drag_offset = this.transition_end_offset;
      return GLib.Source.REMOVE;
    }

    int64 now = frame_clock.get_frame_time ();
    double t = (now - transition_start_time) / TRANSITION_DURATION;

    t = double.min (1.0, t);

    this.drag_offset = this.transition_start_offset +
                       t * (transition_end_offset - transition_start_offset);
    this.queue_allocate ();

    if (t >= 1.0)
      return GLib.Source.REMOVE;

    return GLib.Source.CONTINUE;
  }

  private void start_transition () {
    this.transition_start_time = this.get_frame_clock ().get_frame_time ();
    this.add_tick_callback (transition_cb);
  }

  private void drag_update_cb (double offset_x, double offset_y) {
    this.drag_offset = this.drag_start_offset + offset_x;

    this.drag_offset = double.min (0, drag_offset);
    this.drag_offset = double.max (- (box.get_allocated_width () -
                                      this.get_allocated_width ()),
                                   drag_offset);

    this.queue_allocate ();
  }

  public override void add (Gtk.Widget widget) {
    box.add (widget);
  }

  public override void remove (Gtk.Widget widget) {
    box.remove (widget);
  }

  public override void forall_internal (bool         include_internals,
                                        Gtk.Callback cb) {
    cb (this.box);
  }

  public override void get_preferred_width (out int min, out int nat) {
    Gtk.Widget? first_child = box.get_children ().nth_data (0);

    if (first_child == null) {
      min = nat = 0;
    } else {
      first_child.get_preferred_width (out min, out nat);
    }
  }

  public override void get_preferred_height (out int min, out int nat) {
    Gtk.Widget? first_child = box.get_children ().nth_data (0);

    if (first_child == null) {
      min = nat = 0;
    } else {
      first_child.get_preferred_height (out min, out nat);
    }
  }

  public override bool draw (Cairo.Context ct) {
    Gtk.Allocation alloc;
    this.get_allocation (out alloc);
    ct.save ();
    ct.rectangle (0, 0, alloc.width, alloc.height);
    ct.clip ();
    this.propagate_draw (this.box, ct);
    ct.restore ();

    return Gdk.EVENT_PROPAGATE;
  }

  public override void realize () {
    this.set_realized (true);
    Gtk.Allocation allocation;
    this.get_allocation (out allocation);

    Gdk.WindowAttr attr = {};
    attr.x = allocation.x;
    attr.y = allocation.y;
    attr.width = allocation.width;
    attr.height = allocation.height;
    attr.window_type = Gdk.WindowType.CHILD;
    attr.visual = this.get_visual ();
    attr.wclass = Gdk.WindowWindowClass.INPUT_ONLY;
    attr.event_mask = this.get_events () |
                      Gdk.EventMask.BUTTON_PRESS_MASK |
                      Gdk.EventMask.BUTTON_RELEASE_MASK |
                      Gdk.EventMask.TOUCH_MASK |
                      Gdk.EventMask.ENTER_NOTIFY_MASK |
                      Gdk.EventMask.LEAVE_NOTIFY_MASK;

    Gdk.WindowAttributesType attr_mask = Gdk.WindowAttributesType.X |
                                         Gdk.WindowAttributesType.Y;
    Gdk.Window window = this.get_parent_window ();
    this.set_window (window);
    window.ref ();

    this.event_window = new Gdk.Window (window, attr, attr_mask);
    this.register_window (this.event_window);
    this.box.set_parent_window (this.get_window ());
  }

  public override void unrealize () {
    if (this.event_window != null) {
      this.unregister_window (this.event_window);
      this.event_window.destroy ();
      this.event_window = null;
    }
    base.unrealize ();
  }

  public override void map () {
    base.map ();

    if (this.event_window != null)
      this.event_window.show ();
  }

  public override void unmap () {
    if (this.event_window != null)
      this.event_window.hide ();

    base.unmap ();
  }

  public override void size_allocate (Gtk.Allocation allocation) {
    int min_width, min_height;
    base.size_allocate (allocation);

    box.get_preferred_width (out min_width, null);
    box.get_preferred_height (out min_height, null);
    allocation.width = int.max (allocation.width, min_width);
    allocation.height = int.max (allocation.height, min_height);
    allocation.x += (int)this.drag_offset;
    this.box.size_allocate (allocation);

    if (this.event_window != null) {
      this.event_window.move_resize (allocation.x, allocation.y,
                                     allocation.width, allocation.height);
    }
  }
}

