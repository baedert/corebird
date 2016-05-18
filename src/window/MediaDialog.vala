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
  //private Gtk.Overlay overlay;
  private Gtk.Frame frame;
  //[GtkChild]
  //private Gtk.Button next_button;
  //[GtkChild]
  //private Gtk.Button back_button;
  //[GtkChild]
  //private Gtk.Revealer back_revealer;
  //[GtkChild]
  //private Gtk.Revealer next_revealer;
  private unowned Tweet tweet;
  private int cur_index = 0;

  public MediaDialog (Tweet tweet, int start_media_index) {
    Media cur_media = tweet.medias[start_media_index];
    this.tweet = tweet;
    this.cur_index = start_media_index;
    change_media (cur_media);
  }

  private void change_media (Media media) {
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
      new_widget = new MediaVideoWidget (media);
      frame.add (new_widget);
      ((MediaVideoWidget)new_widget).init ();
    } else {
      new_widget = new MediaImageWidget (media);
      frame.add (new_widget);
    }

    new_widget.show_all ();

    new_widget.get_size_request (out new_width, out new_height);
    if ((new_width != cur_width ||
        new_height != cur_height) && new_width > 0 && new_height > 0) {
      this.resize (new_width, new_height);
    }
    this.queue_resize ();

    //if (cur_index >= tweet.medias.length - 1)
      //next_button.hide ();
    //else
      //next_button.show ();

    //if (cur_index <= 0)
      //back_button.hide ();
    //else
      //back_button.show ();
  }

  private void next_media () {
    if (cur_index < tweet.medias.length - 1) {
      cur_index ++;
      change_media (tweet.medias[cur_index]);
    }
  }

  private void previous_media () {
    if (cur_index > 0) {
      cur_index --;
      change_media (tweet.medias[cur_index]);
    }
  }

  //[GtkCallback]
  //private void next_button_clicked_cb () {
    //next_media ();
  //}

  //[GtkCallback]
  //private void back_button_clicked_cb () {
    //previous_media ();
  //}


  [GtkCallback]
  private bool key_press_event_cb (Gdk.EventKey evt) {
    if (evt.keyval == Gdk.Key.Left)
      previous_media ();
    else if (evt.keyval == Gdk.Key.Right)
      next_media ();
    else
      this.destroy ();

    return Gdk.EVENT_STOP;
  }

  [GtkCallback]
  private bool button_press_event_cb () {
    this.destroy ();
    return Gdk.EVENT_STOP;
  }

  [GtkCallback]
  private bool leave_notify_cb () {
    //back_revealer.reveal_child= false;
    //next_revealer.reveal_child= false;
    return Gdk.EVENT_PROPAGATE;
  }

  [GtkCallback]
  private bool enter_notify_cb () {
    //back_revealer.reveal_child= true;
    //next_revealer.reveal_child= true;
    return Gdk.EVENT_PROPAGATE;
  }


  /* Fake handlers to route events from the overlay box down to
     the actual child of the GtkOverlay */
  //[GtkCallback]
  //private bool fake_button_press_cb (Gdk.EventButton e) {
    //return overlay.get_child ().event (e);
  //}

  //[GtkCallback]
  //private bool fake_scroll_event_cb (Gdk.EventScroll e) {
    //return overlay.get_child ().event (e);
  //}

}
