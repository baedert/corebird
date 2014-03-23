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
    }
  }

  public async void two_step_load(Tweet t, string first_url, string regex_str,
                                          int match_index) {
    var msg     = new Soup.Message("GET", first_url);
    session.queue_message(msg, (_s, _msg) => {
    string back = (string)_msg.response_body.data;
      try{
        var regex = new GLib.Regex(regex_str, 0);
        MatchInfo info;
        regex.match(back, 0, out info);
        string real_url = info.fetch(match_index);
        if(real_url != null)
          load_inline_media.begin(t, real_url);
      } catch (GLib.RegexError e) {
        critical("Regex Error(%s): %s", regex_str, e.message);
      }
    });

  }

  public async void load_inline_media (Tweet t, string url) { //{{{
    GLib.SourceFunc callback = load_inline_media.callback;
    // First, check if the media already exists...
    string path = get_media_path (t, url);
    string thumb_path = get_thumb_path (t, url);
    if(FileUtils.test(path, FileTest.EXISTS)) {
      /* If the media already exists, the thumbnail also exists.
         If not, fuck you.*/
      try {
        var thumb = new Gdk.Pixbuf.from_file(thumb_path);
        fire_media_added(t, path, thumb, thumb_path);
        return;
      } catch (GLib.Error e) {
        critical (e.message);
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
      if (_msg.status_code == Soup.Status.CANCELLED) {
        callback ();
        return;
      }

      try {
        var ms  = new MemoryInputStream.from_data(_msg.response_body.data, null);
        string ext = Utils.get_file_type(url);
        if(ext.length == 0)
          ext = "png";
        ext = ext.down();

        int qm_index;
        if ((qm_index = ext.index_of_char ('?')) != -1) {
          ext = ext.substring (0, qm_index);
        }

        if (ext == "jpg")
          ext = "jpeg";

        var media_out_stream = File.new_for_path (path).create (FileCreateFlags.REPLACE_DESTINATION);
        var thumb_out_stream = File.new_for_path (thumb_path).create (FileCreateFlags.REPLACE_DESTINATION);

        media_out_stream.write_all (_msg.response_body.data, null, null);
        if(ext == "gif"){
          load_animation.begin (t, ms, media_out_stream, thumb_out_stream, path, thumb_path, () => {
            callback ();
          });
        } else {
          load_normal_media.begin (t, ms, media_out_stream, thumb_out_stream, path, thumb_path, () => {
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
                                     OutputStream out_stream,
                                     OutputStream thumb_out_stream,
                                     string path, string thumb_path) {
    Gdk.PixbufAnimation anim;
    try {
      anim = yield new Gdk.PixbufAnimation.from_stream_async (in_stream, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }
    var pic = anim.get_static_image ();
    var thumb = slice_pixbuf (pic);
    yield Utils.write_pixbuf_async (thumb, thumb_out_stream, "png");
    fire_media_added (t, path, thumb, thumb_path);
  }

  private async void load_normal_media (Tweet t,
                                        MemoryInputStream in_stream,
                                        OutputStream out_stream,
                                        OutputStream thumb_out_stream,
                                        string path, string thumb_path) {
    Gdk.Pixbuf pic = null;
    try {
      pic = yield new Gdk.Pixbuf.from_stream_async (in_stream, null);
    } catch (GLib.Error e) {
      warning ("%s(%s)", e.message, path);
      return;
    }
    var thumb = slice_pixbuf (pic);
    yield Utils.write_pixbuf_async (thumb, thumb_out_stream, "png");
    fire_media_added (t, path, thumb, thumb_path);
  }

  /**
   * Slices the given pixbuf to a smaller thumbnail image.
   *
   * @param pic The Gdk.Pixbuf to use as base image
   *
   * @return The created thumbnail
   */
  private Gdk.Pixbuf slice_pixbuf (Gdk.Pixbuf pic) {
    int x, y, w, h;
    calc_thumb_rect (pic.get_width (), pic.get_height (), out x, out y, out w, out h);
    var big_thumb = new Gdk.Pixbuf (Gdk.Colorspace.RGB, true, 8, w, h);
    pic.copy_area (x, y, w, h, big_thumb, 0, 0);
    var thumb = big_thumb.scale_simple (THUMB_SIZE, THUMB_SIZE, Gdk.InterpType.TILES);
    return thumb;
  }


  private void fire_media_added(Tweet t, string path, Gdk.Pixbuf thumb,
                                string thumb_path) {
    t.media = path;
    t.media_thumb = thumb_path;
    t.inline_media = thumb;
    t.inline_media_added(thumb);
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

  /**
   * Calculates the region of the image the thumbnail should be composed of.
   *
   * @param img_width  The width of the original image
   * @param img_height The height of the original image
   *
   */
  private void calc_thumb_rect (int img_width, int img_height,
                                out int x, out int y, out int width, out int height) {
    float ratio = img_width / (float)img_height;
    if (ratio >= 0.9 && ratio <= 1.1) {
      // it's more or less squared, so...
      x = y = 0;
      width = img_width;
      height = img_height;
    } else if (ratio > 1.1) {
      // The image is pretty wide but not really high
      x = (img_width/2) - (img_height/2);
      y = 0;
      width = height = img_height;
    } else {
      x = 0;
      y = (img_height/2) - (img_width/2);
      width = height = img_width;
    }
  }
}
