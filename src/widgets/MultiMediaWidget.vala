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

// TODO: Allow D'n'D out of the button
private class MediaButton : Gtk.Button {
  private unowned Media? _media;
  private Gdk.Pixbuf? play_icon = null;
  public unowned Media? media {
    get {
      return _media;
    }
    set {
      _media = value;
      if (value != null && value.type == MediaType.IMAGE) {
        menu_model.append (_("Copy URL"), "media.copy-url");
        menu_model.append (_("Save Original"), "media.save-original");
      } else if (value != null && (value.type == MediaType.VINE ||
                                   value.type == MediaType.ANIMATED_GIF)) {
        play_icon = new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/assets/play.png");
      }
    }
  }
  public unowned Gtk.Window window;
  private GLib.Menu menu_model;
  private Gtk.Menu menu;
  private GLib.SimpleActionGroup actions;
  private const GLib.ActionEntry[] action_entries = {
    {"copy-url",        copy_url_activated},
    {"save-original",   save_original_activated},
    {"open-in-browser", open_in_browser_activated}
  };


  public MediaButton (Media? media) {
    this.media = media;
    this.set_size_request (-1, MultiMediaWidget.HEIGHT);
    this.get_style_context ().add_class ("inline-media");
    actions = new GLib.SimpleActionGroup ();
    actions.add_action_entries (action_entries, this);
    this.insert_action_group ("media", actions);

    this.menu_model = new GLib.Menu ();
    menu_model.append (_("Open in Browser"), "media.open-in-browser");
    this.menu = new Gtk.Menu.from_model (menu_model);
    this.menu.attach_to_widget (this, null);

    this.button_press_event.connect (button_clicked_cb);
  }

  public override bool draw (Cairo.Context ct) {
    int widget_width = get_allocated_width ();
    int widget_height = get_allocated_height ();

    ct.save ();
    ct.rectangle (0, 0, widget_width, widget_height);

    if (media != null && media.thumbnail != null && media.loaded) {
      double scale = (double)widget_width / media.thumbnail.get_width ();
      ct.scale (scale, 1);
      Gdk.cairo_set_source_pixbuf (ct, media.thumbnail, 0, 0);
    }

    ct.fill ();
    ct.restore ();


   if (media != null && (this.media.type == MediaType.VINE ||
       this.media.type == MediaType.ANIMATED_GIF)) {
     int x = (widget_width  / 2) - (play_icon.get_width ()  / 2);
     int y = (widget_height / 2) - (play_icon.get_height () / 2);
     ct.rectangle (x, y,
                   play_icon.get_width (), play_icon.get_height ());
     Gdk.cairo_set_source_pixbuf (ct, play_icon, x, y);
     ct.fill ();
   }

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

  private void open_in_browser_activated (GLib.SimpleAction a, GLib.Variant? v) {
    message ("Open in browser! %s", media.url);
    Gtk.show_uri (Gdk.Screen.get_default (),
                  media.url,
                  Gtk.get_current_event_time ());
  }

  private void save_original_activated (GLib.SimpleAction a, GLib.Variant? v) {
     var file_dialog = new Gtk.FileChooserDialog (_("Save image"), window,
                                                  Gtk.FileChooserAction.SAVE,
                                                  _("Cancel"), Gtk.ResponseType.CANCEL,
                                                  _("Save"), Gtk.ResponseType.ACCEPT);
    string filename = Utils.get_file_name (media.path);
    file_dialog.set_current_name (filename);
    file_dialog.set_transient_for (window);


    int response = file_dialog.run ();
    if (response == Gtk.ResponseType.ACCEPT) {
      File dest = File.new_for_uri (file_dialog.get_uri ());
      File source = File.new_for_path (media.path);
      try {
        source.copy (dest, FileCopyFlags.OVERWRITE);
      } catch (GLib.Error e) {
        critical (e.message);
      }
      file_dialog.destroy ();
    } else if (response == Gtk.ResponseType.CANCEL)
      file_dialog.destroy ();
  }

}


public class MultiMediaWidget : Gtk.Box {
  public static const int HEIGHT = 60;
  public int media_count { public get; private set; default = 0;}
  public unowned Gtk.Window window;
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
    button.window = this.window;
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
    if (source.invalid) {
      for (int i = 0; i < media_count; i ++) {
        if (media_buttons[i] != null && media_buttons[i].media == null) {
          this.remove (media_buttons[i]);
          media_buttons[i] = null;
          return;
        }
      }
    }
    for (int i = 0; i < media_count; i ++) {
      if (media_buttons[i] != null && media_buttons[i].media == null) {
        media_buttons[i].media = source;
        media_buttons[i].queue_draw ();
        break;
      }
    }
  }
}

