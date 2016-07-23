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

public class MultiMediaWidget : Gtk.Box {
  public const int MAX_HEIGHT = 180;
  public int media_count { public get; private set; default = 0;}
  public bool restrict_height = false;
  public unowned Gtk.Window window;
  private MediaButton[] media_buttons;

  public signal void media_clicked (Cb.Media m, int index);
  private bool media_invalid_fired = false;
  public signal void media_invalid ();

  construct {
    this.orientation = Gtk.Orientation.HORIZONTAL;
    this.homogeneous = true;
  }

  public void set_all_media (Cb.Media[] medias) {
    this.remove_all ();
    this.media_buttons = new MediaButton[medias.length];
    this.media_count = medias.length;

    for (int i = 0; i < medias.length; i++) {
      assert (medias[i] != null);
      set_media (i, medias[i]);
    }
  }

  private void remove_all () {
    this.get_children ().foreach ((w) => {
      this.remove (w);
    });
  }

  public void set_media (int index, Cb.Media media) {
    assert (index < media_count);

    if (media.loaded && media.invalid)
      return;

    var button = new MediaButton (null, this.restrict_height);
    button.set_data ("pos", index);
    button.window = this.window;
    media_buttons[index] = button;

    if (media.loaded) {
      media_buttons[index].media = media;
    } else {
      media_buttons[index].media = media;
      media.progress.connect (media_loaded_cb);
    }
    button.visible = true;
    button.clicked.connect (button_clicked_cb);
    this.pack_start (button, true, true);
    this.queue_draw ();
  }

  private void button_clicked_cb (MediaButton source) {
    if (source.media != null && source.media.loaded) {
      int index = source.get_data ("pos");
      media_clicked (source.media, index);
    }
  }


  private void media_loaded_cb (Cb.Media source) {
    if (source.percent_loaded < 100)
      return;

    if (source.invalid) {
      for (int i = 0; i < media_count; i ++) {
        if (media_buttons[i] != null && media_buttons[i].media == source) {
          this.remove (media_buttons[i]);
          media_buttons[i] = null;
          if (!media_invalid_fired) {
            media_invalid ();
            media_invalid_fired = true;
          }
          return;
        }
      }
    }

    for (int i = 0; i < media_count; i ++) {
      if (media_buttons[i] != null && media_buttons[i].media == source) {
        media_buttons[i].queue_draw ();
        break;
      }
    }
  }

}

