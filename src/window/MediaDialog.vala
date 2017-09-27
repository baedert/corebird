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

[GtkTemplate (ui = "/org/baedert/corebird/ui/media-dialog.ui")]
class MediaDialog : Gtk.Window {
  [GtkChild]
  private Gtk.Frame frame;
  [GtkChild]
  private Gtk.Revealer next_revealer;
  [GtkChild]
  private Gtk.Revealer previous_revealer;
  private unowned Cb.Tweet tweet;
  private int cur_index = 0;
  private Gtk.GestureMultiPress button_gesture;
  private double initial_px;
  private double initial_py;

  public MediaDialog (Cb.Tweet tweet,
                      int      start_media_index,
                      double   px = 0.0,
                      double   py = 0.0) {
    Cb.Media cur_media = tweet.get_medias()[start_media_index];
    this.tweet = tweet;
    this.cur_index = start_media_index;
    this.button_gesture = new Gtk.GestureMultiPress (this);
    this.button_gesture.set_button (0);
    this.button_gesture.set_propagation_phase (Gtk.PropagationPhase.BUBBLE);
    this.button_gesture.released.connect (button_released_cb);

    this.initial_px = px;
    this.initial_py = py;

    if (tweet.get_medias ().length == 1) {
      next_revealer.hide ();
      previous_revealer.hide ();
    }

    change_media (cur_media);
  }

  private void button_released_cb (int    n_press,
                                   double x,
                                   double y) {
    this.destroy ();
    button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
  }

  private void change_media (Cb.Media media) {
    /* Remove the current child */
    var cur_child = frame.get_child ();
    int cur_width = 0, cur_height = 0,
        new_width, new_height;


    if (frame.get_child () != null) {
      frame.remove (cur_child);
      cur_child.get_size_request (out cur_width, out cur_height);
    }

    Gtk.Widget new_widget = null;
    if (media.is_video ()) {
      new_widget = new Cb.MediaVideoWidget (media);
      frame.add (new_widget);
      ((Cb.MediaVideoWidget)new_widget).start ();
    } else {
      new_widget = new Cb.MediaImageWidget (media);
      ((Cb.MediaImageWidget)new_widget).scroll_to (this.initial_px, this.initial_py);
      frame.add (new_widget);

      /* Reset to default values */
      this.initial_px = 0.5;
      this.initial_py = 0.0;
    }

    new_widget.show ();

    new_widget.get_size_request (out new_width, out new_height);
    if ((new_width != cur_width ||
        new_height != cur_height) && new_width > 0 && new_height > 0) {
      this.resize (new_width, new_height);
    }
    this.queue_resize ();

    next_revealer.set_visible (cur_index != tweet.get_medias ().length - 1);
    previous_revealer.set_visible (cur_index != 0);
  }

  private void next_media () {
    if (cur_index < tweet.get_medias ().length - 1) {
      cur_index ++;
      change_media (tweet.get_medias ()[cur_index]);
    }
  }

  private void previous_media () {
    if (cur_index > 0) {
      cur_index --;
      change_media (tweet.get_medias ()[cur_index]);
    }
  }

  [GtkCallback]
  private bool key_press_event_cb (Gdk.EventKey evt) {
    uint keyval;
    evt.get_keyval (out keyval);

    if (keyval == Gdk.Key.Left)
      previous_media ();
    else if (keyval == Gdk.Key.Right)
      next_media ();
    else
      this.destroy ();

    return Gdk.EVENT_PROPAGATE;
  }

  [GtkCallback]
  private void next_button_clicked_cb () {
    next_media ();
  }

  [GtkCallback]
  private void previous_button_clicked_cb () {
    previous_media ();
  }

  public override bool enter_notify_event (Gdk.EventCrossing event) {
    uint detail;

    event.get_crossing_detail (out detail);

    if (event.get_window () == this.get_window () &&
        detail != Gdk.NotifyType.INFERIOR) {
      next_revealer.reveal_child = true;
      previous_revealer.reveal_child = true;
    }

    return false;
  }

  public override bool leave_notify_event (Gdk.EventCrossing event) {
    uint detail;

    event.get_crossing_detail (out detail);

    if (event.get_window () == this.get_window () &&
        detail != Gdk.NotifyType.INFERIOR) {
      next_revealer.reveal_child = false;
      previous_revealer.reveal_child = false;
    }

    return false;
  }
}
