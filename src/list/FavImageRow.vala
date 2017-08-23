/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2017 Timm Bäder
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

class FavImageRow : Gtk.FlowBoxChild {
  private const int THUMB_WIDTH  = 80;
  private const int THUMB_HEIGHT = 50;

  private static Cairo.ImageSurface play_icon;

  private Gtk.EventBox event_box;
  private Gtk.Image image;
  private string file_path;
  private Gtk.GestureMultiPress gesture;

  public bool is_gif = false;

  static construct {
    try {
      play_icon = (Cairo.ImageSurface)Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/play.png"), 1, null);
    } catch (GLib.Error e) {
      critical (e.message);
    }
  }

  public FavImageRow (string path) {
    this.file_path = path;

    event_box = new Gtk.EventBox ();
    event_box.show ();


    image = new Gtk.Image ();
    image.set_size_request (THUMB_WIDTH, THUMB_HEIGHT);
    image.set_halign (Gtk.Align.CENTER);
    image.set_valign (Gtk.Align.CENTER);
    image.margin = 3;
    image.show ();
    event_box.add (image);
    this.add (event_box);

    this.set_valign (Gtk.Align.START);

    /* Sigh */
    event_box.enter_notify_event.connect (() => {
      var flags = this.get_state_flags ();
      this.set_state_flags (flags | Gtk.StateFlags.PRELIGHT, true);

      return false;
    });

    event_box.leave_notify_event.connect (() => {
      this.unset_state_flags (Gtk.StateFlags.PRELIGHT);

      return false;
    });

    gesture = new Gtk.GestureMultiPress (event_box);
    gesture.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
    gesture.set_button (0);
    gesture.pressed.connect (() => {
      Gdk.EventSequence sequence = this.gesture.get_current_sequence ();
      Gdk.EventButton event = (Gdk.EventButton)this.gesture.get_last_event (sequence);

      if (event.triggers_context_menu ()) {
        var menu = new Gtk.Menu ();
        var delete_item = new Gtk.MenuItem.with_label (_("Delete"));
        delete_item.activate.connect (() => {
          var flowbox = this.get_parent ();
          if (!(flowbox is Gtk.FlowBox)) {
            warning ("Parent is not a flowbox");
            return;
          }

          try {
            var file = GLib.File.new_for_path (this.file_path);
            file.trash ();
            flowbox.remove (this);
          } catch (GLib.Error e) {
            warning (e.message);
          }
        });
        menu.add (delete_item);
        menu.attach_to_widget (this, null);
        menu.show_all ();
        menu.popup (null,
                    null,
                    null,
                    event.button,
                    event.time);
      } else {
        this.set_state_flags (this.get_state_flags () | Gtk.StateFlags.ACTIVE, true);
      }

      gesture.set_state (Gtk.EventSequenceState.CLAIMED);
    });

    gesture.released.connect (() => {
      Gdk.EventSequence sequence = this.gesture.get_current_sequence ();
      Gdk.EventButton? event = (Gdk.EventButton?)this.gesture.get_last_event (sequence);

      this.unset_state_flags (Gtk.StateFlags.ACTIVE);

      if (event != null && event.button == Gdk.BUTTON_PRIMARY) {
        /* This gesture blocks the flowbox gesture so implement activating manually. */
        if (this.get_parent () is Gtk.FlowBox) {
          ((Gtk.FlowBox)this.get_parent ()).child_activated (this);
        }
      }
    });

    this.get_style_context ().add_class ("fav-image-item");
    load_image.begin ();
  }

  public override bool draw (Cairo.Context ct) {
    base.draw (ct);

    if (this.is_gif) {
      double scale = 0.6;
      int width = this.get_allocated_width ();
      int height = this.get_allocated_height ();

      double x = (width / 2.0) / scale - (play_icon.get_width () / 2.0);
      double y = (height / 2.0) / scale - (play_icon.get_height () / 2.0);

      ct.scale (scale, scale);
      ct.set_source_surface (play_icon, x, y);
      ct.paint ();
    }

    return false;
  }

  public unowned string get_image_path () {
    return file_path;
  }

  private async void load_image () {
    try {
      var in_stream = GLib.File.new_for_path (file_path).read ();
      var pixbuf = yield new Gdk.Pixbuf.from_stream_at_scale_async (in_stream, THUMB_WIDTH, THUMB_HEIGHT, true);
      in_stream.close ();

      this.image.set_from_pixbuf (pixbuf);
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }
}
