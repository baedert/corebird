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
  private static Cairo.Surface[] play_icons;
  private static const int PLAY_ICON_SIZE = 32;
  public unowned Media? media {
    get {
      return _media;
    }
    set {
      _media = value;
      if (value != null) {
          _media.notify["percent-loaded"].connect (this.queue_draw);
      }
      if (value != null && (value.type == MediaType.IMAGE ||
                            value.type == MediaType.GIF)) {
        menu_model.append (_("Copy URL"), "media.copy-url");
        menu_model.append (_("Save Original"), "media.save-original");
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
  private Pango.Layout layout;


  static construct {
    try {
      play_icons = {
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/assets/play.png"), 1, null),
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/assets/play@2.png"), 2, null),
      };
    } catch (GLib.Error e) {
      critical (e.message);
    }
  }

  public MediaButton (Media? media) {
    this.media = media;
    this.set_size_request (-1, MultiMediaWidget.HEIGHT);
    this.get_style_context ().add_class ("inline-media");
    this.get_style_context ().add_class ("dim-label");
    actions = new GLib.SimpleActionGroup ();
    actions.add_action_entries (action_entries, this);
    this.insert_action_group ("media", actions);

    this.menu_model = new GLib.Menu ();
    menu_model.append (_("Open in Browser"), "media.open-in-browser");
    this.menu = new Gtk.Menu.from_model (menu_model);
    this.menu.attach_to_widget (this, null);

    this.layout = this.create_pango_layout ("0%");

    this.button_press_event.connect (button_clicked_cb);
  }

  public override bool draw (Cairo.Context ct) {
    int widget_width = get_allocated_width ();
    int widget_height = get_allocated_height ();


    /* Draw thumbnail */
    if (media != null && media.thumbnail != null && media.loaded) {
      ct.save ();
      ct.rectangle (0, 0, widget_width, widget_height);

      double scale = (double)widget_width / ((Cairo.ImageSurface)media.thumbnail).get_width ();
      ct.scale (scale, 1);
      ct.set_source_surface (media.thumbnail, 0, 0);
      ct.fill ();
      ct.restore ();

      /* Draw play indicator */
      if (media.type == MediaType.VINE ||
          media.type == MediaType.ANIMATED_GIF ||
          media.type == MediaType.GIF ||
          media.type == MediaType.TWITTER_VIDEO) {
       int x = (widget_width  / 2) - (PLAY_ICON_SIZE  / 2);
       int y = (widget_height / 2) - (PLAY_ICON_SIZE / 2);
       ct.rectangle (x, y, PLAY_ICON_SIZE, PLAY_ICON_SIZE);
       ct.set_source_surface (play_icons[this.get_scale_factor () - 1], x, y);
       ct.fill ();
      }
    } else {
      var sc = this.get_style_context ();
      double layout_x, layout_y;
      int layout_w, layout_h;
      layout.set_text ("%d%%".printf ((int)(media.percent_loaded * 100)), -1);
      layout.get_size (out layout_w, out layout_h);
      layout_x = (widget_width / 2.0) - (layout_w / Pango.SCALE / 2.0);
      layout_y = (widget_height / 2.0) - (layout_h / Pango.SCALE / 2.0);
      sc.render_layout (ct, layout_x, layout_y, layout);
    }

    return base.draw (ct);
  }

  private bool button_clicked_cb (Gdk.EventButton evt) {
    if (evt.button == Gdk.BUTTON_SECONDARY && this.media != null) {
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
    try {
      Gtk.show_uri (Gdk.Screen.get_default (),
                    media.target_url,
                    Gtk.get_current_event_time ());
    } catch (GLib.Error e) {
      critical (e.message);
    }
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

  public signal void media_clicked (Media m, int index);
  private bool media_invalid_fired = false;
  public signal void media_invalid ();


  public MultiMediaWidget (int media_count) {
    this.media_count = media_count;
    this.media_buttons = new MediaButton[media_count];
  }


  public void set_all_media (Media[] medias) {
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


  public void set_media (int index, Media media) {
    assert (index < media_count);

    if (media.loaded && media.invalid)
      return;

    var button = new MediaButton (null);
    button.set_data ("pos", index);
    button.window = this.window;
    media_buttons[index] = button;

    if (media.loaded) {
      media_buttons[index].media = media;
    } else {
      media_buttons[index].media = media;
      media.finished_loading.connect (media_loaded_cb);
    }
    button.visible = true;
    button.clicked.connect (button_clicked_cb);
    this.pack_start (button, true, true);
    this.queue_draw ();
  }

  private void button_clicked_cb (Gtk.Button source) {
    var mb = (MediaButton)source;
    if (mb.media != null && mb.media.loaded) {
      int index = mb.get_data ("pos");
      media_clicked (mb.media, index);
    }
  }


  private void media_loaded_cb (Media source) {
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

