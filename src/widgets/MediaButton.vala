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

private class MediaButton : Gtk.Widget {
  private const int PLAY_ICON_SIZE = 32;
  private const int MAX_HEIGHT     = 200;
  /* We use MIN_ constants in case the media has not yet been loaded */
  private const int MIN_HEIGHT     = 40;
  private const int MIN_WIDTH      = 40;
  private Cb.Media? _media = null;
  private static Gdk.Texture[] play_icons;
  public Cb.Media? media {
    get {
      return _media;
    }
    set {
      if (_media != null) {
        _media.progress.disconnect (media_progress_cb);
      }
      _media = value;
      if (value != null) {
        if (!media.loaded) {
          _media.progress.connect (media_progress_cb);
        } else {
          this.media_alpha = 1.0;
        }
        bool is_m3u8 = _media.url.has_suffix (".m3u8");
        ((GLib.SimpleAction)actions.lookup_action ("save-as")).set_enabled (!is_m3u8);

      }
      if (value != null && (value.type == Cb.MediaType.IMAGE ||
                            value.type == Cb.MediaType.GIF)) {
        menu_model.append (_("Copy URL"), "media.copy-url");
      }
    }
  }
  public unowned Gtk.Window main_window;
  private GLib.Menu menu_model;
  private Gtk.Menu? menu = null;
  private GLib.SimpleActionGroup actions;
  private const GLib.ActionEntry[] action_entries = {
    {"copy-url",        copy_url_activated},
    {"open-in-browser", open_in_browser_activated},
    {"save-as",         save_as_activated},
  };
  private Pango.Layout layout;
  private Gtk.GestureMultiPress press_gesture;
  private bool restrict_height = false;
  private int64 fade_start_time;
  private double media_alpha = 0.0;


  public signal void clicked (MediaButton source, double px, double py);

  static construct {
    try {
      play_icons = { Gdk.Texture.from_resource ("/org/baedert/corebird/data/play.png"),
                     Gdk.Texture.from_resource ("/org/baedert/corebird/data/play@2.png") };
    } catch (GLib.Error e) {
      critical (e.message);
    }

    set_css_name ("mediabutton");
  }

  construct {
    this.set_has_window (false);
    this.set_can_focus (true);
  }

  ~MediaButton () {
    if (_media != null) {
      _media.progress.disconnect (media_progress_cb);
    }
  }

  public MediaButton (Cb.Media? media, bool restrict_height = false) {
    this.media = media;
    this.restrict_height = restrict_height;
    actions = new GLib.SimpleActionGroup ();
    actions.add_action_entries (action_entries, this);
    this.insert_action_group ("media", actions);

    this.menu_model = new GLib.Menu ();
    menu_model.append (_("Open in Browser"), "media.open-in-browser");

    menu_model.append (_("Save as…"), "media.save-as");

    this.layout = this.create_pango_layout ("0%");
    this.press_gesture = new Gtk.GestureMultiPress (this);
    this.press_gesture.set_exclusive (true);
    this.press_gesture.set_button (0);
    this.press_gesture.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
    this.press_gesture.released.connect (gesture_released_cb);
    this.press_gesture.pressed.connect (gesture_pressed_cb);
  }

  private void media_progress_cb () {
    this.queue_draw ();

    if (this._media.loaded) {
      if (!_media.invalid && _media.texture != null) {
        this.queue_resize ();
        this.start_fade ();
      } else {
        /* Invalid media. */
        this.hide ();
        this.set_sensitive (false);
        this.queue_resize ();
      }
    }
  }

  private bool fade_in_cb (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
    if (!this.get_mapped ()) {
      this.media_alpha = 1.0;
      return GLib.Source.REMOVE;
    }

    int64 now = frame_clock.get_frame_time ();
    double t = 1.0;
    if (now < this.fade_start_time + TRANSITION_DURATION)
      t = (now - fade_start_time) / (double)(TRANSITION_DURATION );

    t = ease_out_cubic (t);

    this.media_alpha = t;
    this.queue_draw ();
    if (t >= 1.0) {
      this.media_alpha = 1.0;
      return GLib.Source.REMOVE;
    }

    return GLib.Source.CONTINUE;
  }

  private void start_fade () {
    assert (this.media != null);
    assert (this.media.texture != null);

    if (!this.get_realized () || !this.get_mapped () ||
        !Gtk.Settings.get_default ().gtk_enable_animations) {
      this.media_alpha = 1.0;
      return;
    }

    this.fade_start_time = this.get_frame_clock ().get_frame_time ();
    this.add_tick_callback (fade_in_cb);
  }

  private void get_draw_size (out int width,
                              out int height,
                              out double scale) {
    if (this._media.width == -1 && this._media.height == -1) {
      width  = 0;
      height = 0;
      scale  = 0.0;
      return;
    }

    width  = this.get_width ();
    height = this.get_height ();
    double scale_x = (double)width / this._media.width;
    double scale_y = (double)height / this._media.height;

    scale = double.min (double.min (scale_x, scale_y), 1.0);

    width  = (int)(this._media.width  * scale);
    height = (int)(this._media.height * scale);
  }

  /* TODO: We conceptually use the texture as a separate widget here... */
  public override void snapshot (Gtk.Snapshot snapshot) {
    int widget_width = get_width ();
    int widget_height = get_height ();

    /* Draw thumbnail */
    if (_media != null && _media.texture != null && _media.loaded) {
      Graphene.Rect texture_bounds = {};
      int draw_width, draw_height;
      double scale;
      this.get_draw_size (out draw_width, out draw_height, out scale);

      int draw_x = (widget_width / 2) - (draw_width / 2);

      if (media_alpha < 1.0)
        snapshot.push_opacity (media_alpha, "Media Opacity");

      texture_bounds.origin.x = draw_x;
      texture_bounds.origin.y = 0;
      texture_bounds.size.width = draw_width;
      texture_bounds.size.height = draw_height;

      snapshot.append_texture (media.texture, texture_bounds, "Media");

      /* Draw play indicator */
      if (_media.is_video ()) {
        Graphene.Rect icon_bounds = {};

        var icon_texture = play_icons[this.get_scale_factor () - 1];
        icon_bounds.origin.x = (widget_width  / 2) - (PLAY_ICON_SIZE / 2);
        icon_bounds.origin.y = (widget_height / 2) - (PLAY_ICON_SIZE / 2);
        icon_bounds.size.width = PLAY_ICON_SIZE;
        icon_bounds.size.height = PLAY_ICON_SIZE;

        snapshot.append_texture (icon_texture, icon_bounds, "Media Play Icon");
      }

      if (media_alpha < 1.0)
        snapshot.pop ();

    } else {
      var sc = this.get_style_context ();
      double layout_x, layout_y;
      int layout_w, layout_h;
      layout.set_text ("%d%%".printf ((int)(_media.percent_loaded * 100)), -1);
      layout.get_size (out layout_w, out layout_h);
      layout_x = (widget_width / 2.0) - (layout_w / Pango.SCALE / 2.0);
      layout_y = (widget_height / 2.0) - (layout_h / Pango.SCALE / 2.0);
      snapshot.render_layout (sc, layout_x, layout_y, layout);
    }
  }

  private void copy_url_activated (GLib.SimpleAction a, GLib.Variant? v) {
    warning ("Re-Enable copy url menu item");
    //Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (Gdk.Display.get_default (),
                                                             //Gdk.SELECTION_CLIPBOARD);
    //clipboard.set_text (media.url, -1);
  }

  private void open_in_browser_activated (GLib.SimpleAction a, GLib.Variant? v) {
    try {
      Gtk.show_uri_on_window (this.main_window,
                    media.target_url ?? media.url,
                    Gtk.get_current_event_time ());
    } catch (GLib.Error e) {
      critical (e.message);
    }
  }

  private void save_as_activated (GLib.SimpleAction a, GLib.Variant? v) {
    string title;
    if (_media.is_video ())
      title = _("Save Video");
    else
      title = _("Save Image");

    var filechooser = new Gtk.FileChooserNative (title,
                                                 this.main_window,
                                                 Gtk.FileChooserAction.SAVE,
                                                 _("Save"),
                                                 _("Cancel"));

    filechooser.set_current_name (Utils.get_media_display_name (_media));
    if (filechooser.run () == Gtk.ResponseType.ACCEPT) {
      var file = GLib.File.new_for_path (filechooser.get_filename ());
      // Download the file
      string url = _media.target_url ?? _media.url;
      debug ("Downloading %s to %s", url, filechooser.get_filename ());

      GLib.OutputStream? out_stream = null;
      try {
        out_stream = file.create (0, null);
      } catch (GLib.Error e) {
        Utils.show_error_dialog (e.message, this.main_window);
        warning (e.message);
      }

      if (out_stream != null) {
        Utils.download_file.begin (url, out_stream, () => {
          debug ("Download of %s finished", url);
        });
      }
    }
  }

  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void measure (Gtk.Orientation orientation,
                                int             for_size,
                                out int         minimum,
                                out int         natural,
                                out int         minimum_baseline,
                                out int         natural_baseline) {

    int media_size;
    int other_media_size;
    if (this._media == null || this._media.height == -1) {
      media_size = 0;
      other_media_size = 0;
    } else {
      if (orientation == Gtk.Orientation.HORIZONTAL) {
        media_size = this._media.width;
        other_media_size = this._media.height;
      } else {
        media_size = this._media.height;
        other_media_size = this._media.width;
      }
    }

    if (orientation == Gtk.Orientation.HORIZONTAL) {
      if (for_size == -1) {
        minimum = int.min (media_size, MIN_WIDTH);
        natural = media_size;
      } else {
        double height_ratio = (double)for_size / (double)other_media_size;
        int width = int.min (media_size, (int)(media_size* height_ratio));
        minimum = int.min (media_size, MIN_WIDTH);
        natural = width;
      }
    } else {
      if (for_size == -1) {
        minimum = int.min (media_size, MAX_HEIGHT);
        natural = media_size;
      } else {
        double width_ratio = (double)for_size / (double) other_media_size;
        int height = int.min (media_size, (int)(media_size * width_ratio));
        if (restrict_height) {
          minimum = int.min (other_media_size, MAX_HEIGHT);
          natural = minimum;
        } else {
          minimum = height;
          natural = height;
        }
      }
    }

    minimum_baseline = -1;
    natural_baseline = -1;
  }

  private void gesture_pressed_cb (int    n_press,
                                   double x,
                                   double y) {
    Gdk.EventSequence sequence = this.press_gesture.get_current_sequence ();
    Gdk.Event event = this.press_gesture.get_last_event (sequence);
    uint button = this.press_gesture.get_current_button ();

    if (this._media == null)
      return;

    this.press_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
    if (event.triggers_context_menu ()) {
      if (this.menu == null) {
        this.menu = new Gtk.Menu.from_model (menu_model);
        this.menu.attach_to_widget (this, null);
      }
      menu.show ();
      menu.popup (null, null, null, button, Gtk.get_current_event_time ());
    }
  }

  private void gesture_released_cb (int    n_press,
                                    double x,
                                    double y) {
    Gdk.EventSequence sequence = this.press_gesture.get_current_sequence ();
    Gdk.Event event = this.press_gesture.get_last_event (sequence);
    uint button = this.press_gesture.get_current_button ();

    if (this._media == null || event == null)
      return;

    if (button == Gdk.BUTTON_PRIMARY) {
      this.press_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
      double px = x / (double)this.get_width ();
      double py = y / (double)this.get_height ();
      this.clicked (this, px, py);
    }
  }

  public override bool key_press_event (Gdk.Event event) {
    uint keyval;
    event.get_keyval (out keyval);
    if (keyval == Gdk.Key.Return ||
        keyval == Gdk.Key.KP_Enter) {
      this.clicked (this, 0.5, 0.5);
      return Gdk.EVENT_STOP;
    }

    return Gdk.EVENT_PROPAGATE;
  }
}
