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

class VideoDialog : Gtk.Window {
#if VINE
  private Gst.Element src;
  private Gst.Element sink;
  private uint *xid;
#endif
  private Gtk.DrawingArea drawing_area = new Gtk.DrawingArea ();


  public VideoDialog (Gtk.Window parent, Media media) {
    this.set_decorated (false);
    this.set_modal (true);
    this.set_transient_for (parent);
    this.set_type_hint (Gdk.WindowTypeHint.DIALOG);
    drawing_area.realize.connect (realize_cb);
#if VINE
    this.src  = Gst.ElementFactory.make ("playbin", "video");
    this.sink = Gst.ElementFactory.make ("xvimagesink", "sink");
    this.src.set ("video-sink", sink, null);
    var bus = src.get_bus ();
    bus.set_sync_handler (bus_sync_handler);
    bus.add_watch (GLib.Priority.DEFAULT, watch_cb);
    if (media.type == MediaType.VINE)
      fetch_real_url.begin (media.url, "<meta property=\"twitter:player:stream\" content=\"(.*?)\"");
    else if (media.type == MediaType.ANIMATED_GIF)
      fetch_real_url.begin (media.url, "<source src=\"(.*?)\" type=\"video/mp4\"");
    else
      critical ("Unknown video media type: %d", media.type);
#endif
    drawing_area.set_size_request (435, 435);
    this.add (drawing_area);
    this.button_press_event.connect (button_press_event_cb);
    this.key_press_event.connect (key_press_event_cb);
  }


  private bool button_press_event_cb (Gdk.EventButton evt) {
    stop ();
    return true;
  }

  private bool key_press_event_cb (Gdk.EventKey evt) {
    stop ();
    return true;
  }

  private void stop () {
#if VINE
    src.set_state (Gst.State.NULL);
#endif
    this.destroy ();
  }

#if VINE
  private Gst.BusSyncReply bus_sync_handler (Gst.Bus bus, Gst.Message msg) {
    if (!Gst.Video.is_video_overlay_prepare_window_handle_message (msg))
      return Gst.BusSyncReply.PASS;

    Gst.Video.Overlay overlay = (Gst.Video.Overlay)msg.src;
    overlay.set_window_handle (xid);

    return Gst.BusSyncReply.DROP;
  }


  private bool watch_cb (Gst.Bus bus, Gst.Message msg) {
  if (msg.type == Gst.MessageType.EOS) {
      // LOOP
      src.seek (1.0, Gst.Format.TIME, Gst.SeekFlags.FLUSH,
                Gst.SeekType.SET, 0,
                Gst.SeekType.NONE, -1);
    }
    return true;
  }
#endif



  private void realize_cb () {
#if VINE
    this.xid = (uint *)Gdk.X11Window.get_xid (drawing_area.get_window ());
#endif
  }

  private async void fetch_real_url (string first_url, string regex_str) { // {{{
    var session = new Soup.Session ();
    var msg = new Soup.Message ("GET", first_url);
    session.queue_message (msg, (s, _msg) => {
      string back = (string)_msg.response_body.data;
      try {
        var regex = new GLib.Regex (regex_str, 0);
        MatchInfo info;
        regex.match (back, 0, out info);
        string real_url = info.fetch (1);
        real_set_url (real_url);

#if VINE
        src.set_state (Gst.State.PLAYING);
#endif

      } catch (GLib.RegexError e) {
        warning ("Regex error: %s", e.message);
      }
      fetch_real_url.callback ();
    });
    yield;
  } // }}}

  private void real_set_url (string url) {
#if VINE
    this.src.set ("uri", url, null);
#endif
  }
}
