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
  private Gtk.Menu image_context_menu;

  private new string path;
  private double dnd_x;
  private double dnd_y;

  public MediaImageWidget (string path) {
    this.path = path;

    this.button_press_event.connect (button_press_event_cb);
    this.image = new Gtk.Image ();
    Gtk.EventBox event_box = new Gtk.EventBox ();
    event_box.add (this.image);
    event_box.motion_notify_event.connect (event_box_motion_notify_cb);
    event_box.button_press_event.connect (event_box_button_press_cb);
    this.add (event_box);

    image_context_menu = new Gtk.Menu ();
    var save_as_item = new Gtk.MenuItem ();
    save_as_item.label = _("Save Image");
    save_as_item.activate.connect (save_item_activated_cb);
    save_as_item.show ();
    image_context_menu.add (save_as_item);

    //Choose proper width/height
    Gdk.Pixbuf? pixbuf = null;
    try {
      pixbuf = new Gdk.Pixbuf.from_file(path);
    } catch (GLib.Error e) {
      critical(e.message);
    }
    try {
      if(path.has_suffix("gif"))
        image.pixbuf_animation = new Gdk.PixbufAnimation.from_file(path);
      else
        image.pixbuf = new Gdk.Pixbuf.from_file(path);
    } catch (GLib.Error e) {
      critical (e.message);
      return;
    }

    int img_width  = pixbuf.get_width();
    int img_height = pixbuf.get_height();

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

    if(win_width < 800 && win_height == 600) {
      int add_width;
      this.get_vscrollbar().get_preferred_width(null, out add_width);
      win_width += add_width;
    }

    if(win_width == 800 && win_height < 600) {
      int add_height;
      this.get_hscrollbar().get_preferred_width(null, out add_height);
      win_height += add_height;
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

  private void save_item_activated_cb () {
     var file_dialog = new Gtk.FileChooserDialog (_("Save image"), null,
                                                  Gtk.FileChooserAction.SAVE,
                                                  _("Cancel"), Gtk.ResponseType.CANCEL,
                                                  _("Save"), Gtk.ResponseType.ACCEPT);
    string filename = Utils.get_file_name (path);
    file_dialog.set_current_name (filename);
    //file_dialog.set_transient_for (this);


    int response = file_dialog.run ();
    if (response == Gtk.ResponseType.ACCEPT) {
      File dest = File.new_for_uri (file_dialog.get_uri ());
      debug ("Source: %s", path);
      debug ("Destin: %s", file_dialog.get_uri ());
      File source = File.new_for_path (path);
      try {
        source.copy (dest, FileCopyFlags.OVERWRITE);
      } catch (GLib.Error e) {
        critical (e.message);
      }
      file_dialog.destroy ();
    } else if (response == Gtk.ResponseType.CANCEL)
      file_dialog.destroy ();

  }

  private bool button_press_event_cb (Gdk.EventButton evt) {
    if (evt.button == 3) {
      image_context_menu.popup (null, null, null, evt.button, evt.time);
      return true;
    }

    return false;
  }

}
