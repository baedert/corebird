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
  private Gtk.Overlay overlay;

  public MediaDialog (Tweet tweet, int start_media_index) {
    Media cur_media = tweet.medias[start_media_index];
    change_media (cur_media);
  }

  private void change_media (Media media) {
    /* XXX The individual widgets could also just support changing their contents... */
    /* Remove the current child */
    if (overlay.get_child () != null)
      overlay.remove (overlay.get_child ());

    if (media.type == MediaType.IMAGE || media.type == MediaType.GIF) {
      var widget = new MediaImageWidget (media.path);
      overlay.add (widget);
      widget.show_all ();
    }
  }



  [GtkCallback]
  private bool key_press_event_cb () {
    this.destroy ();
    return true;
  }

  [GtkCallback]
  private bool button_press_event_cb () {
    this.destroy ();
    return true;
  }
}
