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
  private Gst.Element? app_src = null;
  private Gst.Element sink;
#endif
  private GLib.Cancellable cancellable;
  private Gtk.Label error_label = new Gtk.Label ("");
  private Gtk.Widget area;
  private uint64 seek_pos = 0;
  private uint8[] video_data;
  private size_t  available_data;

  private SurfaceProgress image;



  public MediaVideoWidget (Media media) {
    this.cancellable = new GLib.Cancellable ();
    assert (media.surface != null);
    var image_surface = (Cairo.ImageSurface) media.surface;
    this.set_size_request (image_surface.get_width (), image_surface.get_height ());
#if VIDEO
    if (media.type == MediaType.VINE)
      fetch_real_url.begin (media.url, "<meta property=\"twitter:player:stream\" content=\"(.*?)\"");
    else if (media.type == MediaType.ANIMATED_GIF)
      fetch_real_url.begin (media.url, "<source video-src=\"(.*?)\" type=\"video/mp4\"");
    else if (media.type == MediaType.TWITTER_VIDEO)
      download_video.begin (media.url);
    else if (media.type == MediaType.INSTAGRAM_VIDEO)
      download_video.begin (media.url);
    else
      critical ("Unknown video media type: %d", media.type);
#endif

    // set up error label
    error_label.margin = 20;
    error_label.wrap = true;
    error_label.selectable = true;

    image = new SurfaceProgress ();
    image.surface = media.surface;

    this.add_named (image, "thumbnail");
    this.add_named (error_label, "error");

    this.visible_child = image;

    this.button_press_event.connect (button_press_event_cb);
    this.key_press_event.connect (key_press_event_cb);
  }

#if VIDEO
  private void need_data_cb (uint size) {

    if (this.video_data == null) {
      debug ("No content length set!");
      return;
    }

    if (available_data < this.video_data.length) {
      debug ("not all data here yet");
      return;
    }

    if (this.seek_pos + size > this.available_data)
      size = (uint)(this.available_data - this.seek_pos);

    if (size <= 0) {
      debug ("seek_pos + size > available_data");
      return;
    }

    var buffer = new Gst.Buffer ();
    var mem = new Gst.Memory.wrapped (Gst.MemoryFlags.READONLY,
                                      this.video_data,
                                      (size_t)this.seek_pos,
                                      (size_t)size,
                                      null,
                                      null);


    buffer.append_memory (mem);

    Gst.FlowReturn ret;
    GLib.Signal.emit_by_name (this.app_src, "push-buffer", buffer, out ret);

    this.seek_pos += size;
  }

  private void seek_data_cb (uint64 pos) {
    this.seek_pos = pos;
  }

  private void source_setup_cb (Gst.Element source,
                                Gst.Element playbin) {
    assert (source != null);
    app_src = source;
    app_src.set ("stream-type", 2); // 2 = random access
    GLib.Signal.connect_swapped (app_src, "need-data", (GLib.Callback)need_data_cb, this);
    GLib.Signal.connect_swapped (app_src, "seek-data", (GLib.Callback)seek_data_cb, this);
  }

#endif

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

    var bus = this.src.get_bus ();
    bus.add_watch (GLib.Priority.DEFAULT, watch_cb);
    bus.message.connect ((msg) => {
      string debug;
      GLib.Error error;
      msg.parse_error (out error, out debug);
      message (debug);
    });

    this.src.set ("video-sink", this.sink);
    this.src.set ("uri", "appsrc://");
    GLib.Signal.connect_swapped (this.src, "source-setup", (GLib.Callback)source_setup_cb, this);

    this.src.set_state (Gst.State.PAUSED);
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
    if (msg.type == Gst.MessageType.EOS) {
      // LOOP
      this.src.seek (1, Gst.Format.BYTES, Gst.SeekFlags.FLUSH,
                     Gst.SeekType.SET, 0,
                     Gst.SeekType.NONE, -1);
    } else if (msg.type == Gst.MessageType.ERROR) {
      GLib.Error error;
      string debug;
      msg.parse_error (out error, out debug);
      message (debug);
    } else if (msg.type == Gst.MessageType.ASYNC_DONE) {
      this.visible_child_name = "video";
    }
    return true;
  }
#endif

  private async void fetch_real_url (string first_url, string regex_str) { // {{{
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
        } else
          download_video.begin (real_url);
      } catch (GLib.RegexError e) {
        warning ("Regex error: %s", e.message);
        show_error ("Regex error: %s".printf (e.message));
      }
      fetch_real_url.callback ();
    });
    yield;
  } // }}}


  private async void download_video (string url) {
    var msg = new Soup.Message ("GET", url);
    cancellable.cancelled.connect (() => {
      SOUP_SESSION.cancel_message (msg, Soup.Status.CANCELLED);
    });

    msg.got_headers.connect (() => {
      this.video_data = new uint8[msg.response_headers.get_content_length ()];
      this.available_data = 0;
#if VIDEO
      assert (app_src != null);
      app_src.set ("size", this.video_data.length);
#endif
    });

    msg.got_chunk.connect ((buffer) => {
      for (int i = 0; i < buffer.length; i ++) {
        video_data[available_data + i] = buffer.data[i];
      }

      available_data += buffer.length;

      double progress = (double)this.available_data / (double)this.video_data.length;
      this.image.progress = progress;

    });
    SOUP_SESSION.queue_message (msg, (s, _msg) => {
      if (_msg.status_code != Soup.Status.OK) {
        if (_msg.status_code != Soup.Status.CANCELLED) {
          warning ("Status Code %u", _msg.status_code);
          show_error ("%u %s".printf (_msg.status_code, Soup.Status.get_phrase (_msg.status_code)));
        }
        download_video.callback ();
        return;
      }

#if VIDEO
      Gst.FlowReturn ret;
      GLib.Signal.emit_by_name (this.app_src, "end-of-stream", out ret);
      this.src.set_state (Gst.State.PLAYING);
#endif
      this.image.progress = 1.0;
      download_video.callback ();
    });
    yield;
  }

}
