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

class MediaVideoWidget : Gtk.Stack {
#if VIDEO
  private Gst.Element src;
  private Gst.Element sink;
#endif
  private GLib.Cancellable cancellable;
  private Gtk.Label error_label = new Gtk.Label ("");
  private Gtk.Widget area;

  private SurfaceProgress surface_progress;
  private string? media_url = null;

  public MediaVideoWidget (Media media) {
    this.cancellable = new GLib.Cancellable ();
    assert (media.surface != null);
    var image_surface = (Cairo.ImageSurface) media.surface;
    this.set_size_request (image_surface.get_width (), image_surface.get_height ());
#if VIDEO

    message ("Media type: %s", media.type.to_string ());

    this.media_url = media.url;

    switch (media.type) {
      case MediaType.TWITTER_VIDEO:
      case MediaType.INSTAGRAM_VIDEO:
        this.media_url = media.url;
        /* Video will be started in init() */
      break;

      case MediaType.VINE:
        fetch_real_url.begin (media.url, "<meta property=\"twitter:player:stream\" content=\"(.*?)\"");
      break;

      case MediaType.ANIMATED_GIF:
        fetch_real_url.begin (media.url, "<source video-src=\"(.*?)\" type=\"video/mp4\"");
      break;

      default:
        GLib.warn_if_reached ();
      break;
    }
#endif

    // set up error label
    error_label.margin = 20;
    error_label.wrap = true;
    error_label.selectable = true;

    surface_progress = new SurfaceProgress ();
    surface_progress.surface = media.surface;

    this.add_named (surface_progress, "thumbnail");
    this.add_named (error_label, "error");

    this.visible_child = surface_progress;

    this.button_press_event.connect (button_press_event_cb);
    this.key_press_event.connect (key_press_event_cb);
  }

  private void start_video () {
#if VIDEO
    assert (this.media_url != null);
    this.src.set ("uri", this.media_url);
    this.src.set_state (Gst.State.PLAYING);
#endif
  }

  public void init () {
#if VIDEO
    this.src = Gst.ElementFactory.make ("playbin", "video");
    this.sink = Gst.ElementFactory.make ("gtksink", "gtksink");
    if (sink == null) {
      critical ("Could not create a gtksink. Need gst-plugins-bad >= 1.6");
      return;
    }
    this.sink.get ("widget", out area);
    assert (area != null);
    assert (area is Gtk.DrawingArea);
    this.add_named (area, "video");
    this.visible_child_name = "video";

    var bus = this.src.get_bus ();
    bus.add_watch (GLib.Priority.DEFAULT, watch_cb);

    this.src.set ("video-sink", this.sink);

    if (this.media_url != null) {
      /* Set in constructor */
      this.start_video ();
    }

#endif
  }

  private void show_error (string error_message) {
    error_label.label = error_message;
    this.visible_child_name = "error";
  }


  private bool button_press_event_cb (Gdk.EventButton evt) {
    stop ();
    return false;
  }

  private bool key_press_event_cb (Gdk.EventKey evt) {
    stop ();
    return true;
  }

  private void stop () {
    cancellable.cancel ();
#if VIDEO
    src.set_state (Gst.State.NULL);
#endif
  }

  public override void destroy () {
    stop ();
    base.destroy ();
  }

#if VIDEO
  private bool watch_cb (Gst.Bus bus, Gst.Message msg) {
    switch (msg.type) {
      case Gst.MessageType.BUFFERING:
        int percent;
        msg.parse_buffering (out percent);
        this.surface_progress.progress = percent / 100.0;
      break;

      case Gst.MessageType.EOS:
        this.src.seek (1.0, Gst.Format.TIME, Gst.SeekFlags.FLUSH,
                       Gst.SeekType.SET, 0,
                       Gst.SeekType.NONE, (int64)Gst.CLOCK_TIME_NONE);
      break;

      case Gst.MessageType.ASYNC_DONE:
        this.visible_child_name = "video";
      break;

      case Gst.MessageType.ERROR:
        GLib.Error error;
        string debug;
        msg.parse_error (out error, out debug);
        show_error (debug);
        critical (error.message);
      break;
    }

    return true;
  }
#endif

  private async void fetch_real_url (string first_url, string regex_str) {
    var msg = new Soup.Message ("GET", first_url);
    cancellable.cancelled.connect (() => {
      SOUP_SESSION.cancel_message (msg, Soup.Status.CANCELLED);
    });
    SOUP_SESSION.queue_message (msg, (s, _msg) => {
      if (_msg.status_code != Soup.Status.OK) {
        if (_msg.status_code != Soup.Status.CANCELLED) {
          warning ("Status Code %u", _msg.status_code);
          show_error ("%u %s".printf (_msg.status_code, Soup.Status.get_phrase (_msg.status_code)));
        }
        fetch_real_url.callback ();
        return;
      }
      unowned string back = (string)_msg.response_body.data;
      try {
        var regex = new GLib.Regex (regex_str, 0);
        MatchInfo info;
        regex.match (back, 0, out info);
        string? real_url = info.fetch (1);
        if (real_url == null) {
          show_error ("Error: Could not get real URL");
        } else {
          this.media_url = real_url;
          this.start_video ();
        }
      } catch (GLib.RegexError e) {
        warning ("Regex error: %s", e.message);
        show_error ("Regex error: %s".printf (e.message));
      }
      fetch_real_url.callback ();
    });
    yield;
  }

}
