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


namespace InlineMediaDownloader {
  public const int THUMB_SIZE = 40;
  private Soup.Session session;

  public async void try_load_media (Tweet t, string url) {
    if (!Settings.show_inline_media ()) {
      return;
    }

    if (session == null)
      session = new Soup.Session ();
    /*
        TODO: Support For:
        * yfrog
        * lockerz.com
        * say.ly
          * <img src="contentImage" src="(.*?)"
        * moby.tv

        * Youtube (Preview image with video indicator. Click on the video
                   opens/streams it in some video player)
        * vine! (thumbnails supported)

    */

    if(url.has_prefix("http://instagr.am") ||
       url.has_prefix("http://instagram.com/p/")) {
      yield two_step_load (t, url, "<meta property=\"og:image\" content=\"(.*?)\"", 1);
    } else if (url.has_prefix("http://i.imgur.com")) {
      yield load_inline_media (t, url);
    } else if (url.has_prefix("http://d.pr/i/") || url.has_prefix("http://ow.ly/i/") ||
               url.has_prefix("https://vine.co/v/") || url.has_prefix("http://tmblr.co/")) {
      yield two_step_load (t, url, "<meta property=\"og:image\" content=\"(.*?)\"", 1);
    } else if (url.has_prefix("http://pbs.twimg.com/media/")) {
      yield load_inline_media (t, url);
    } else if (url.has_prefix("http://twitpic.com/")) {
      yield two_step_load (t, url,
                          "<meta name=\"twitter:image\" value=\"(.*?)\"", 1);
    } else {
      //debug ("Not downloadable media: %s", url);
    }
  }

  public async void two_step_load (Tweet t, string first_url, string regex_str,
                                   int match_index) {
    var msg = new Soup.Message ("GET", first_url);
    session.queue_message (msg, (_s, _msg) => {
      string back = (string)_msg.response_body.data;
      try {
        var regex = new GLib.Regex (regex_str, 0);
        MatchInfo info;
        regex.match (back, 0, out info);
        string real_url = info.fetch (match_index);
        if(real_url != null)
          load_inline_media.begin (t, real_url);
      } catch (GLib.RegexError e) {
        critical ("Regex Error(%s): %s", regex_str, e.message);
      }
    });
  }

  public async void load_inline_media (Tweet t, string url) { //{{{
    GLib.SourceFunc callback = load_inline_media.callback;
    // First, check if the media already exists...
    string path = get_media_path (t, url);
    string thumb_path = get_thumb_path (t, url);
    string ext = Utils.get_file_type(url);
    {
      if(ext.length == 0)
        ext = "png";

      ext = ext.down();
      int qm_index;
      if ((qm_index = ext.index_of_char ('?')) != -1) {
        ext = ext.substring (0, qm_index);
      }

      if (ext == "jpg")
        ext = "jpeg";
    }

    GLib.OutputStream thumb_out_stream = null;
    GLib.OutputStream media_out_stream = null;

    bool main_file_exists = false;
    try {
      media_out_stream = File.new_for_path (path).create (FileCreateFlags.NONE);
    } catch (GLib.Error e) {
      if (e is GLib.IOError.EXISTS)
        main_file_exists = true;
      else {
        warning (e.message);
        return;
      }
    }

    try {
      thumb_out_stream = File.new_for_path (thumb_path).create (FileCreateFlags.NONE);
      // If we came to this point, the above operation did not throw a GError, so
      // the thumbnail does not exist, right?
      if (main_file_exists) {
        var in_stream = GLib.File.new_for_path (path).read ();
        yield load_normal_media (t, in_stream, thumb_out_stream, path, thumb_path, url);
        return;
      }
    } catch (GLib.Error e) {
      if (e is GLib.IOError.EXISTS) {
        if (main_file_exists) {
          try {
            var thumb = new Gdk.Pixbuf.from_file (thumb_path);
            fire_media_added (t, path, thumb, thumb_path, url);
          } catch (GLib.Error e) {
            critical (e.message);
          }
          return;
        } else  {
          // We just delete the old thumbnail and proceed
          GLib.FileUtils.remove (thumb_path);
          try {
            thumb_out_stream = File.new_for_path (thumb_path).create (FileCreateFlags.NONE);
          } catch (GLib.Error e) {
            critical (e.message);
            return;
          }
        }
      } else {
        warning (e.message);
        return;
      }
    }


    var msg = new Soup.Message("GET", url);
    msg.got_headers.connect (() => {
      int64 content_length = msg.response_headers.get_content_length ();
      double mb = content_length / 1024.0 / 1024.0;
      double max = Settings.max_media_size ();
      if (mb > max) {
        debug ("Image %s won't be downloaded,  %fMB > %fMB", url, mb, max);
        session.cancel_message (msg, Soup.Status.CANCELLED);
      }
    });


    session.queue_message(msg, (s, _msg) => {
      if (_msg.status_code != Soup.Status.OK) {
        callback ();
        return;
      }

      try {
        var ms  = new MemoryInputStream.from_data(_msg.response_body.data, null);
        media_out_stream.write_all (_msg.response_body.data, null, null);
        if(ext == "gif"){
          load_animation.begin (t, ms, thumb_out_stream, path, thumb_path, url, () => {
            callback ();
          });
        } else {
          load_normal_media.begin (t, ms, thumb_out_stream, path, thumb_path, url, () => {
            callback ();
          });
        }
        yield;
      } catch (GLib.Error e) {
        critical (e.message + " for MEDIA " + url);
        callback ();
      }
    });
    yield;
  } //}}}

  private async void load_animation (Tweet t,
                                     MemoryInputStream in_stream,
                                     OutputStream thumb_out_stream,
                                     string path, string thumb_path, string url) {
    Gdk.PixbufAnimation anim;
    try {
      anim = yield new Gdk.PixbufAnimation.from_stream_async (in_stream, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }
    var pic = anim.get_static_image ();
    var thumb = Utils.slice_pixbuf (pic, THUMB_SIZE);
    yield Utils.write_pixbuf_async (thumb, thumb_out_stream, "png");
    fire_media_added (t, path, thumb, thumb_path, url);
  }

  private async void load_normal_media (Tweet t,
                                        GLib.InputStream in_stream,
                                        OutputStream thumb_out_stream,
                                        string path, string thumb_path, string url) {
    Gdk.Pixbuf pic = null;
    try {
      pic = yield new Gdk.Pixbuf.from_stream_async (in_stream, null);
    } catch (GLib.Error e) {
      warning ("%s(%s)", e.message, path);
      return;
    }
    var thumb = Utils.slice_pixbuf (pic, THUMB_SIZE);
    yield Utils.write_pixbuf_async (thumb, thumb_out_stream, "png");
    fire_media_added (t, path, thumb, thumb_path, url);
  }

  private void fire_media_added(Tweet t, string path, Gdk.Pixbuf thumb,
                                string thumb_path, string media_url) {
    t.media = path;
    t.media_thumb = thumb_path;
    t.inline_media = thumb;
    t.inline_media_added(thumb);
    t.original_media_url = media_url;
  }

  public string get_media_path (Tweet t, string url) {
    string ext = Utils.get_file_type (url);
    ext = ext.down();
    if(ext.length == 0)
      ext = "png";

    return Dirs.cache (@"assets/media/$(t.id)_$(t.user_id).$(ext)");
  }

  private string get_thumb_path (Tweet t, string url) {
    return Dirs.cache (@"assets/media/thumbs/$(t.id)_$(t.user_id).png");
  }

}
