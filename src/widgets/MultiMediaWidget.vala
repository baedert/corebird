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


private class MediaButton : Gtk.Button {
  public unowned Media? media;
  private GLib.Menu menu_model;
  private Gtk.Menu menu;
  private GLib.SimpleActionGroup actions;
  private const GLib.ActionEntry[] action_entries = {
    {"copy-url",      copy_url_activated},
    {"save-original", save_original_activated},
  };


  public MediaButton (Media? media) {
    this.media = media;
    this.set_size_request (-1, MultiMediaWidget.HEIGHT);
    this.get_style_context ().add_class ("inline-media");
    actions = new GLib.SimpleActionGroup ();
    actions.add_action_entries (action_entries, this);
    this.insert_action_group ("media", actions);

    this.menu_model = new GLib.Menu ();
    menu_model.append (_("Copy URL"), "media.copy-url");
    menu_model.append (_("Save Original"), "media.save-original");
    this.menu = new Gtk.Menu.from_model (menu_model);
    this.menu.attach_to_widget (this, null);

    this.button_press_event.connect (button_clicked_cb);
  }

  public override bool draw (Cairo.Context ct) {
    int widget_width = get_allocated_width ();
    int widget_height = get_allocated_height ();

    ct.save ();
    ct.set_source_rgb (1, 0, 0);
    ct.rectangle (10, 10, widget_width - 20, widget_height - 20);
    ct.fill ();
    ct.restore ();

    ct.save ();
    ct.rectangle (0, 0, widget_width, widget_height);

    if (media != null && media.thumbnail != null && media.loaded) {
      double scale = (double)widget_width / media.thumbnail.get_width ();
      ct.scale (scale, 1);
      Gdk.cairo_set_source_pixbuf (ct, media.thumbnail, 0, 0);
    }

    ct.fill ();
    ct.restore ();
    return base.draw (ct);
  }

  private bool button_clicked_cb (Gdk.EventButton evt) {
    if (evt.button == Gdk.BUTTON_SECONDARY) {
      menu.show_all ();
      menu.popup (null, null, null, evt.button, evt.time);
      return true;
    }
    return false;
  }

  private void copy_url_activated (GLib.SimpleAction a, GLib.Variant? v) {
    Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (Gdk.Display.get_default (),
                                                             Gdk.SELECTION_CLIPBOARD);
    clipboard.set_text (media.url, -1);
  }

  private void save_original_activated (GLib.SimpleAction a, GLib.Variant? v) {
    message ("save_original");
  }

}


public class MultiMediaWidget : Gtk.Box {
  public static const int HEIGHT = 40;
  public int media_count { public get; private set; default = 0;}
  private MediaButton[] media_buttons;

  public signal void media_clicked (Media m);


  public MultiMediaWidget (int media_count) {
    this.media_count = media_count;
    this.media_buttons = new MediaButton[media_count];
  }
  public void set_all_media (Media[] medias) {
    this.media_buttons = new MediaButton[medias.length];
    this.media_count = medias.length;
    for (int i = 0; i < medias.length; i++) {
      assert (medias[i] != null);
      set_media (i, medias[i]);
    }
  }


  public void set_media (int index, Media media) {
    assert (index < media_count);

    var button = new MediaButton (null);
    media_buttons[index] = button;

    if (media.loaded) {
      media_buttons[index].media = media;
    } else {
      media.finished_loading.connect (media_loaded_cb);
    }
    button.visible = true;
    button.clicked.connect (button_clicked_cb);
    this.pack_start (button, true, true);
    this.queue_draw ();
  }

  private void button_clicked_cb (Gtk.Button source) {
    var mb = (MediaButton)source;
    if (mb.media != null)
      media_clicked (((MediaButton)source).media);
  }


  private void media_loaded_cb (Media source) {
    for (int i = 0; i < media_count; i ++) {
      if (media_buttons[i].media == null) {
        media_buttons[i].media = source;
        media_buttons[i].queue_draw ();
        break;
      }
    }
  }
}

