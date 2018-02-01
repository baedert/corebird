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

  private static Gdk.Texture play_icon;

  private Gtk.Image image;
  private string file_path;
  private Gtk.GestureMultiPress gesture;

  public bool is_gif = false;

  static construct {
    play_icon = Gdk.Texture.from_resource ("/org/baedert/corebird/data/play.png");
  }

  public FavImageRow (string path) {
    this.file_path = path;

    image = new Gtk.Image ();
    image.set_size_request (THUMB_WIDTH, THUMB_HEIGHT);
    image.set_halign (Gtk.Align.CENTER);
    image.set_valign (Gtk.Align.CENTER);
    image.margin = 3;
    image.show ();
    this.add (image);

    this.set_valign (Gtk.Align.START);

    gesture = new Gtk.GestureMultiPress (this);
    gesture.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
    gesture.set_button (0);
    gesture.pressed.connect (() => {
      Gdk.EventSequence sequence = this.gesture.get_current_sequence ();
      Gdk.Event event = this.gesture.get_last_event (sequence);

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
            ((Gtk.Container)flowbox).remove (this);
          } catch (GLib.Error e) {
            warning (e.message);
          }
        });
        menu.add (delete_item);
        menu.attach_to_widget (this, null);
        menu.show ();
        menu.popup (null,
                    null,
                    null,
                    gesture.get_current_button (),
                    event.get_time ());
      } else {
        this.set_state_flags (this.get_state_flags () | Gtk.StateFlags.ACTIVE, true);
      }

      gesture.set_state (Gtk.EventSequenceState.CLAIMED);
    });

    gesture.released.connect (() => {
      this.unset_state_flags (Gtk.StateFlags.ACTIVE);

      if (gesture.get_current_button () == Gdk.BUTTON_PRIMARY) {
        /* This gesture blocks the flowbox gesture so implement activating manually. */
        if (this.get_parent () is Gtk.FlowBox) {
          ((Gtk.FlowBox)this.get_parent ()).child_activated (this);
        }
      }
    });

    this.get_style_context ().add_class ("fav-image-item");
    load_image.begin ();
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    base.snapshot (snapshot);

    if (this.is_gif) {
      float scale = 0.6f;
      int width = this.get_width ();
      int height = this.get_height ();

      float x = (width / 2.0f) - (play_icon.get_width () * scale / 2.0f);
      float y = (height / 2.0f) - (play_icon.get_height () * scale / 2.0f);

      Graphene.Rect bounds = {};
      bounds.origin.x = x;
      bounds.origin.y = y;
      bounds.size.width = (int)(play_icon.get_width ());
      bounds.size.height = (int)(play_icon.get_height ());

      snapshot.append_texture (play_icon, bounds, "GIF indicator");
    }
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
