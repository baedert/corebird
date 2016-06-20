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
  private static const int PLAY_ICON_SIZE = 32;
  private static const int MAX_HEIGHT     = 200;
  /* We use MIN_ constants in case the media has not yet been loaded */
  private static const int MIN_HEIGHT     = 40;
  private static const int MIN_WIDTH      = 40;
  private Gdk.Window? event_window = null;
  private unowned Cb.Media? _media;
  private static Cairo.Surface[] play_icons;
  public unowned Cb.Media? media {
    get {
      return _media;
    }
    set {
      _media = value;
      if (value != null) {
        if (!media.loaded) {
          _media.progress.connect (media_progress_cb);
        } else {
          this.media_alpha = 1.0;
        }
      }
      if (value != null && (value.type == Cb.MediaType.IMAGE ||
                            value.type == Cb.MediaType.GIF)) {
        menu_model.append (_("Copy URL"), "media.copy-url");
      }
    }
  }
  public unowned Gtk.Window window;
  private GLib.Menu menu_model;
  private Gtk.Menu? menu = null;
  private GLib.SimpleActionGroup actions;
  private const GLib.ActionEntry[] action_entries = {
    {"copy-url",        copy_url_activated},
    {"open-in-browser", open_in_browser_activated}
  };
  private Pango.Layout layout;
  private Gtk.GestureMultiPress press_gesture;
  private bool restrict_height = false;
  private int64 fade_start_time;
  private double media_alpha = 0.0;


  public signal void clicked (MediaButton source);

  static construct {
    try {
      play_icons = {
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/play.png"), 1, null),
        Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/play@2.png"), 2, null),
      };
    } catch (GLib.Error e) {
      critical (e.message);
    }
  }

  construct {
    this.set_has_window (false);
    this.set_can_focus (true);
  }

  public MediaButton (Cb.Media? media, bool restrict_height = false) {
    this.media = media;
    this.restrict_height = restrict_height;
    this.get_style_context ().add_class ("inline-media");
    this.get_style_context ().add_class ("dim-label");
    actions = new GLib.SimpleActionGroup ();
    actions.add_action_entries (action_entries, this);
    this.insert_action_group ("media", actions);

    this.menu_model = new GLib.Menu ();
    menu_model.append (_("Open in Browser"), "media.open-in-browser");

    this.layout = this.create_pango_layout ("0%");
    this.press_gesture = new Gtk.GestureMultiPress (this);
    this.press_gesture.set_exclusive (true);
    this.press_gesture.set_button (0);
    this.press_gesture.pressed.connect (gesture_pressed_cb);
  }

  private void media_progress_cb () {
    this.queue_draw ();

    if (this._media.percent_loaded >= 100) {
      if (!_media.invalid && _media.surface != null) {
        this.start_fade ();
      }

      this.queue_resize ();
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
    assert (this.media.surface != null);

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

    width  = this.get_allocated_width ();
    height = this.get_allocated_height ();
    double scale_x = (double)width / this._media.width;
    double scale_y = (double)height / this._media.height;

    scale = double.min (double.min (scale_x, scale_y), 1.0);

    width  = (int)(this._media.width  * scale);
    height = (int)(this._media.height * scale);
  }

  public override bool draw (Cairo.Context ct) {
    int widget_width = get_allocated_width ();
    int widget_height = get_allocated_height ();


    /* Draw thumbnail */
    if (_media != null && _media.surface != null && _media.loaded) {


      int draw_width, draw_height;
      double scale;
      this.get_draw_size (out draw_width, out draw_height, out scale);

      int draw_x = (widget_width / 2) - (draw_width / 2);

      ct.save ();
      ct.rectangle (0, 0, widget_width, widget_height);
      ct.scale (scale, scale);
      ct.set_source_surface (media.surface, draw_x / scale, 0);
      ct.paint_with_alpha (this.media_alpha);
      ct.restore ();
      ct.new_path ();

      /* Draw play indicator */
      if (_media.is_video ()) {
        int x = (widget_width  / 2) - (PLAY_ICON_SIZE / 2);
        int y = (widget_height / 2) - (PLAY_ICON_SIZE / 2);

        ct.save ();
        ct.rectangle (x, y, PLAY_ICON_SIZE, PLAY_ICON_SIZE);
        ct.set_source_surface (play_icons[this.get_scale_factor () - 1], x, y);
        ct.paint_with_alpha (this.media_alpha);
        ct.restore ();
        ct.new_path ();
      }

      var sc = this.get_style_context ();
      sc.render_background (ct, draw_x, 0, draw_width, draw_height);
      sc.render_frame      (ct, draw_x, 0, draw_width, draw_height);

      if (this.has_visible_focus ()) {
        sc.render_focus (ct, draw_x + 2, 2, draw_width - 4, draw_height - 4);
      }

    } else {
      var sc = this.get_style_context ();
      double layout_x, layout_y;
      int layout_w, layout_h;
      layout.set_text ("%d%%".printf (_media.percent_loaded), -1);
      layout.get_size (out layout_w, out layout_h);
      layout_x = (widget_width / 2.0) - (layout_w / Pango.SCALE / 2.0);
      layout_y = (widget_height / 2.0) - (layout_h / Pango.SCALE / 2.0);
      sc.render_layout (ct, layout_x, layout_y, layout);
    }


    return Gdk.EVENT_PROPAGATE;
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

  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void get_preferred_height (out int minimum,
                                             out int natural) {
    int media_height;
    if (this._media == null || this._media.height == -1) {
      media_height = 1;
    } else {
      media_height = this._media.height;
    }

    minimum = int.min (media_height, MAX_HEIGHT);

    natural = media_height;
  }

  public override void get_preferred_height_for_width (int width,
                                                       out int minimum,
                                                       out int natural) {
    int media_width;
    int media_height;

    if (this._media == null || this._media.width == -1 || this._media.height == -1) {
      media_width = MIN_WIDTH;
      media_height = MAX_HEIGHT;
    } else {
      media_width = this._media.width;
      media_height = this._media.height;
    }

    double width_ratio = (double)width / (double) media_width;
    int height = int.min (media_height, (int)(media_height * width_ratio));
    if (restrict_height) {
      minimum = int.min (media_height, MAX_HEIGHT);
      natural = minimum;
    } else {
      minimum = height;
      natural = height;
    }

  }

  public override void get_preferred_width_for_height (int height,
                                                       out int minimum,
                                                       out int natural) {
    int media_width;
    int media_height;

    if (this._media == null || this._media.width == -1 || this._media.height == -1) {
      media_width = MIN_WIDTH;
      media_height = MAX_HEIGHT;
    } else {
      media_width = this._media.width;
      media_height = this._media.height;
    }

    double height_ratio = (double)height / (double)media_height;
    int width = int.min (media_width, (int)(media_width * height_ratio));
    minimum = int.min (media_width, MIN_WIDTH);
    natural = width;
  }

  public override void get_preferred_width (out int minimum,
                                            out int natural) {
    int media_width;
    if (this._media == null || this._media.width == -1) {
      media_width = 1;
    } else {
      media_width = this._media.width;
    }

    minimum = int.min (media_width, MIN_WIDTH);
    natural = media_width;
  }

  public override void realize () {
    this.set_realized (true);
    int draw_width;
    int draw_height;
    double scale;

    this.get_draw_size (out draw_width, out draw_height, out scale);

    Gdk.WindowAttr attr = {};
    attr.x = 0;
    attr.y = 0;
    attr.width = draw_width;
    attr.height = draw_height;
    attr.window_type = Gdk.WindowType.CHILD;
    attr.visual = this.get_visual ();
    attr.wclass = Gdk.WindowWindowClass.INPUT_ONLY;
    attr.event_mask = this.get_events () |
                      Gdk.EventMask.BUTTON_PRESS_MASK |
                      Gdk.EventMask.BUTTON_RELEASE_MASK |
                      Gdk.EventMask.TOUCH_MASK |
                      Gdk.EventMask.ENTER_NOTIFY_MASK |
                      Gdk.EventMask.LEAVE_NOTIFY_MASK;

    Gdk.WindowAttributesType attr_mask = Gdk.WindowAttributesType.X |
                                         Gdk.WindowAttributesType.Y;
    Gdk.Window window = this.get_parent_window ();
    this.set_window (window);
    window.ref ();

    this.event_window = new Gdk.Window (window, attr, attr_mask);
    this.register_window (this.event_window);
  }

  public override void unrealize () {
    if (this.event_window != null) {
      this.unregister_window (this.event_window);
      this.event_window.destroy ();
      this.event_window = null;
    }
    base.unrealize ();
  }

  public override void map () {
    base.map ();

    if (this.event_window != null)
      this.event_window.show ();
  }

  public override void unmap () {

    if (this.event_window != null)
      this.event_window.hide ();

    base.unmap ();
  }

  public override void size_allocate (Gtk.Allocation alloc) {
    base.size_allocate (alloc);

    int draw_width;
    int draw_height;
    double scale;

    if (this.get_realized ()) {
      this.get_draw_size (out draw_width, out draw_height, out scale);
      int draw_x = (alloc.width / 2) - (draw_width / 2);
      this.event_window.move_resize (alloc.x + draw_x,     alloc.y,
                                     draw_width, draw_height);
    }
  }

  public override bool enter_notify_event (Gdk.EventCrossing evt) {
    if (evt.window == this.event_window &&
        evt.detail != Gdk.NotifyType.INFERIOR) {
      this.set_state_flags (this.get_state_flags () | Gtk.StateFlags.PRELIGHT,
                            true);
    }

    return Gdk.EVENT_PROPAGATE;
  }

  public override bool leave_notify_event (Gdk.EventCrossing evt) {
    if (evt.window == this.event_window &&
        evt.detail != Gdk.NotifyType.INFERIOR) {
      this.set_state_flags (this.get_state_flags () & ~Gtk.StateFlags.PRELIGHT,
                            true);
    }

    return Gdk.EVENT_PROPAGATE;
  }

  private void gesture_pressed_cb (int    n_press,
                                   double x,
                                   double y) {

    Gdk.EventSequence sequence = this.press_gesture.get_current_sequence ();
    Gdk.Event event = this.press_gesture.get_last_event (sequence);
    uint button = this.press_gesture.get_current_button ();

    if (this._media == null)
      return;

    if (button == Gdk.BUTTON_PRIMARY) {
      this.press_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
      this.clicked (this);
    } else if (event.triggers_context_menu ()) {
      this.press_gesture.set_state (Gtk.EventSequenceState.CLAIMED);

      if (this.menu == null) {
        this.menu = new Gtk.Menu.from_model (menu_model);
        this.menu.attach_to_widget (this, null);
      }
      menu.show_all ();
      menu.popup (null, null, null, button, Gtk.get_current_event_time ());
    } else {
      this.press_gesture.set_state (Gtk.EventSequenceState.DENIED);
    }
  }

  public override bool key_press_event (Gdk.EventKey event) {
    if (event.keyval == Gdk.Key.Return ||
        event.keyval == Gdk.Key.KP_Enter) {
      this.clicked (this);
      return Gdk.EVENT_STOP;
    }

    return Gdk.EVENT_PROPAGATE;
  }
}



