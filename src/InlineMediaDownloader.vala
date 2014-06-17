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
  private Soup.Session session;

  public async void load_media (Tweet t, Media media) {
    if (session == null)
      session = new Soup.Session ();

    yield load_inline_media (t, media);
  }

  public void load_all_media (Tweet t, Media[] medias) {
    foreach (Media m in medias) {
      load_media.begin (t, m);
    }
  }

  public bool is_media_candidate (string url) {
    return url.has_prefix ("http://instagra.am") ||
           url.has_prefix ("http://instagram.com/p/") ||
           url.has_prefix ("http://i.imgur.com") ||
           url.has_prefix ("http://d.pr/i/") ||
           url.has_prefix ("http://ow.ly/i/") ||
#if VINE
           url.has_prefix ("https://vine.co/v/") ||
#endif
           url.has_prefix ("http://pbs.twimg.com/media/") ||
           url.has_prefix ("http://twitpic.com/")
    ;
  }

  // XXX Rename
  private async void two_step_load (Tweet t, Media media,
                                    string regex_str1, int match_index1) {
    var msg = new Soup.Message ("GET", media.url);
    session.queue_message (msg, (_s, _msg) => {
      string back = (string)_msg.response_body.data;
      try {
        var regex = new GLib.Regex (regex_str1, 0);
        MatchInfo info;
        regex.match (back, 0, out info);
        string real_url = info.fetch (match_index1);
        media.thumb_url = real_url;

        two_step_load.callback ();
      } catch (GLib.RegexError e) {
        critical ("Regex Error(%s): %s", regex_str1, e.message);
      }
    });
    yield;
  }

  private async void load_inline_media (Tweet t, Media media) {
    GLib.SourceFunc callback = load_inline_media.callback;

    media.path = get_media_path (t, media);
    media.thumb_path = get_thumb_path (t, media);
    string ext = Utils.get_file_type (media.url);
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
      media_out_stream = File.new_for_path (media.path).create (FileCreateFlags.NONE);
    } catch (GLib.Error e) {
      if (e is GLib.IOError.EXISTS)
        main_file_exists = true;
      else {
        warning (e.message);
        return;
      }
    }

    try {
      thumb_out_stream = File.new_for_path (media.thumb_path).create (FileCreateFlags.NONE);
      // If we came to this point, the above operation did not throw a GError, so
      // the thumbnail does not exist, right?
      if (main_file_exists) {
        var in_stream = GLib.File.new_for_path (media.path).read ();
        yield load_normal_media (t, in_stream, thumb_out_stream, media);
        return;
      }
    } catch (GLib.Error e) {
      if (e is GLib.IOError.EXISTS) {
        if (main_file_exists) {
          try {
            var thumb = new Gdk.Pixbuf.from_file (media.thumb_path);
            media.thumbnail = thumb;
            media.loaded = true;
            media.finished_loading ();
          } catch (GLib.Error e) {
            critical ("%s (error code %d)", e.message, e.code);
          }
          return;
        } else  {
          // We just delete the old thumbnail and proceed
          GLib.FileUtils.remove (media.thumb_path);
          try {
            thumb_out_stream = File.new_for_path (media.thumb_path).create (FileCreateFlags.NONE);
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

    /* If we get to this point, the image was not cached on disk and we
       *really* need to download it. */
    string url = media.url;
    if(url.has_prefix("http://instagr.am") ||
       url.has_prefix("http://instagram.com/p/")) {
      yield two_step_load (t, media, "<meta property=\"og:image\" content=\"(.*?)\"", 1);
    } else if (url.has_prefix("http://ow.ly/i/")) {
      yield two_step_load (t, media, "<meta property=\"og:image\" content=\"(.*?)\"", 1);
    } else if (url.has_prefix("http://twitpic.com/")) {
      yield two_step_load (t, media,
                          "<meta name=\"twitter:image\" value=\"(.*?)\"", 1);
    } else if (url.has_prefix ("https://vine.co/v/")) {
      yield two_step_load (t, media, "<meta property=\"og:image\" content=\"(.*?)\"", 1);
    }


    var msg = new Soup.Message ("GET", media.thumb_url);
    msg.got_headers.connect (() => {
      int64 content_length = msg.response_headers.get_content_length ();
      double mb = content_length / 1024.0 / 1024.0;
      double max = Settings.max_media_size ();
      if (mb > max) {
        debug ("Image %s won't be downloaded,  %fMB > %fMB", media.thumb_url, mb, max);
        media.invalid = true;
        session.cancel_message (msg, Soup.Status.CANCELLED);
      }
    });


    session.queue_message(msg, (s, _msg) => {
      if (_msg.status_code != Soup.Status.OK) {
        callback ();
        return;
      }

      try {
        var ms = new MemoryInputStream.from_data(_msg.response_body.data, null);
        media_out_stream.write_all (_msg.response_body.data, null, null);
        if(ext == "gif"){
          load_animation.begin (t, ms, thumb_out_stream, media, () => {
            callback ();
          });
        } else {
          load_normal_media.begin (t, ms, thumb_out_stream, media, () => {
            callback ();
          });
        }
        yield;
      } catch (GLib.Error e) {
        critical (e.message + " for MEDIA " + media.thumb_url);
        callback ();
      }
    });
    yield;

  }

  private async void load_animation (Tweet t,
                                     GLib.MemoryInputStream in_stream,
                                     GLib.OutputStream thumb_out_stream,
                                     Media media) {
    Gdk.PixbufAnimation anim;
    try {
      anim = yield new Gdk.PixbufAnimation.from_stream_async (in_stream, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }
    var pic = anim.get_static_image ();
    int thumb_width = (int)(600.0 / (float)t.medias.length);
    var thumb = Utils.slice_pixbuf (pic, thumb_width, MultiMediaWidget.HEIGHT);
    yield Utils.write_pixbuf_async (thumb, thumb_out_stream, "png");
    media.thumbnail = thumb;
    media.loaded = true;
    media.finished_loading ();
  }

  private async void load_normal_media (Tweet t,
                                        GLib.InputStream in_stream,
                                        GLib.OutputStream thumb_out_stream,
                                        Media media) {
    Gdk.Pixbuf pic = null;
    try {
      pic = yield new Gdk.Pixbuf.from_stream_async (in_stream, null);
    } catch (GLib.Error e) {
      warning ("%s(%s)", e.message, media.path);
      return;
    }

    int thumb_width = (int)(600.0 / (float)t.medias.length);
    var thumb = Utils.slice_pixbuf (pic, thumb_width, MultiMediaWidget.HEIGHT);
    yield Utils.write_pixbuf_async (thumb, thumb_out_stream, "png");
    media.thumbnail = thumb;
    media.loaded = true;
    media.finished_loading ();
  }

  public string get_media_path (Tweet t, Media media) {
    string ext = Utils.get_file_type (media.thumb_url);
    ext = ext.down();
    if(ext.length == 0)
      ext = "png";

    return Dirs.cache (@"assets/media/$(t.id)_$(t.user_id)_$(media.id).$(ext)");
  }

  public string get_thumb_path (Tweet t, Media media) {
    return Dirs.cache (@"assets/media/thumbs/$(t.id)_$(t.user_id)_$(media.id).png");
  }

}
