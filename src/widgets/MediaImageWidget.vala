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

public class MediaImageWidget : Gtk.ScrolledWindow {
  private Gtk.Image image;

  private double dnd_x;
  private double dnd_y;

  public MediaImageWidget (Media media) {
    this.image = new Gtk.Image ();
    Gtk.EventBox event_box = new Gtk.EventBox ();
    event_box.add (this.image);
    event_box.motion_notify_event.connect (event_box_motion_notify_cb);
    event_box.button_press_event.connect (event_box_button_press_cb);
    this.add (event_box);

    if (media.type == MediaType.GIF) {
      assert (media.animation != null);
      this.image.set_from_animation (media.animation);
    } else {
      this.image.set_from_surface (media.surface);
    }

    int img_width  = media.surface.get_width ();
    int img_height = media.surface.get_height ();

    int win_width  = 800;
    int win_height = 600;
    if(img_width <= Gdk.Screen.width()*0.7) {
      win_width = img_width;
      this.hscrollbar_policy = Gtk.PolicyType.NEVER;
    }

    if(img_height <= Gdk.Screen.height()*0.7) {
      win_height = img_height;
      this.vscrollbar_policy = Gtk.PolicyType.NEVER;
    }

    this.set_size_request(win_width, win_height);
  }

  private bool event_box_motion_notify_cb (Gdk.EventMotion evt) {
    if ((evt.state & Gdk.ModifierType.MODIFIER_MASK) >= Gdk.ModifierType.BUTTON2_MASK) {
      double diff_x = dnd_x - evt.x;
      double diff_y = dnd_y - evt.y;
      this.vadjustment.value += diff_y;
      this.hadjustment.value += diff_x;
      return true;
    }
    return false;
  }

  private bool event_box_button_press_cb (Gdk.EventButton evt) {
    if (evt.button == 2) {
      this.dnd_x = evt.x;
      this.dnd_y = evt.y;
      return true;
    }
    return false;
  }
}
