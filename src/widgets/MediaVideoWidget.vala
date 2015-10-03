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
  private Gtk.ProgressBar progress_bar = new Gtk.ProgressBar ();
  private int64 file_content_length = -1;
  private int64 current_content_length = 0;
  private GLib.Cancellable cancellable;
  private Gtk.Label error_label = new Gtk.Label ("");
  private Gtk.Widget area;


  public MediaVideoWidget (Media media) {
    this.cancellable = new GLib.Cancellable ();
#if VIDEO
    if (media.type == MediaType.VINE)
      fetch_real_url.begin (media.url, "<meta property=\"twitter:player:stream\" content=\"(.*?)\"");
    else if (media.type == MediaType.ANIMATED_GIF)
      fetch_real_url.begin (media.url, "<source video-src=\"(.*?)\" type=\"video/mp4\"");
    else if (media.type == MediaType.TWITTER_VIDEO)
      download_video.begin (media.url);
    else
      critical ("Unknown video media type: %d", media.type);
#endif
    this.set_size_request (435, 435);

    progress_bar.valign = Gtk.Align.CENTER;
    progress_bar.margin = 20;
    progress_bar.show_text = true;

    // set up error label
    error_label.margin = 20;
    error_label.wrap = true;
    error_label.selectable = true;

    this.add_named (progress_bar, "progress");
    this.add_named (error_label, "error");

    this.visible_child = progress_bar;
    this.button_press_event.connect (button_press_event_cb);
    this.key_press_event.connect (key_press_event_cb);
    this.show_all ();
  }

  public void init () {
    //this.src = Gst.ElementFactory.make ("videotestsrc", "video");
    this.src = Gst.ElementFactory.make ("playbin", "video");
    this.sink = Gst.ElementFactory.make ("gtksink", "gtksink");
    if (sink == null) {
      warning ("Could not create a gtksink. Need gst-plugins-bad >= 1.6");
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
      this.src.seek (1.0, Gst.Format.TIME, Gst.SeekFlags.FLUSH,
                     Gst.SeekType.SET, 0,
                     Gst.SeekType.NONE, -1);
    } else if (msg.type == Gst.MessageType.ERROR) {
      GLib.Error error;
      string debug;
      msg.parse_error (out error, out debug);
      message (debug);
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
      string back = (string)_msg.response_body.data;
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
    msg.got_headers.connect (() => {
      file_content_length = msg.response_headers.get_content_length ();
    });
    cancellable.cancelled.connect (() => {
      SOUP_SESSION.cancel_message (msg, Soup.Status.CANCELLED);
    });
    msg.got_chunk.connect ((buffer) => {
      current_content_length += buffer.length;
      double fraction = (double) current_content_length / (double) file_content_length;
      progress_bar.fraction = fraction;
      progress_bar.text = "%d %%".printf ((int)(fraction * 100));
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
      string b64 = GLib.Base64.encode ((uchar[])msg.response_body.data);
      var sa = "data:;base64," + b64;
      this.src.set ("uri", sa);
      this.visible_child_name = "video";
      this.src.set_state (Gst.State.PLAYING);
#endif
      download_video.callback ();
    });
    yield;
  }

}
