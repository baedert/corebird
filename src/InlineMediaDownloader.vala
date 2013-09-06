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


class InlineMediaDownloader {
  public static const int THUMB_SIZE = 40;


  public static async void try_load_media(Tweet t, string url) {
    if(!Settings.show_inline_media())
      return;

    /*
      Support For:
        * yfrog
        * lockerz.com
        * say.ly
          * <img src="contentImage" src="(.*?)"
        * moby.tv

        * Youtube (Preview image with video indicator. Click on the video
                   opens/streams it in some video player)
        * vine!

    */

    if(url.has_prefix("http://instagr.am") ||
       url.has_prefix("http://instagram.com/p/")) {
      two_step_load.begin(t, url, "<meta property=\"og:image\" content=\"(.*?)\"", 1);
    } else if (url.has_prefix("http://i.imgur.com")) {
      load_inline_media.begin(t, url);
    } else if (url.has_prefix("http://d.pr/i/") || url.has_prefix("http://ow.ly/i/") ||
               url.has_prefix("https://vine.co/v/")) {
      two_step_load.begin(t, url, "<meta property=\"og:image\" content=\"(.*?)\"",
                          1);
    } else if (url.has_prefix("http://pbs.twimg.com/media/")) {
      load_inline_media.begin(t, url);
    } else if (url.has_prefix("http://twitpic.com/")) {
      two_step_load.begin(t, url,
                          "<meta name=\"twitter:image\" value=\"(.*?)\"", 1);
    }
  }

  private static async void two_step_load(Tweet t, string first_url, string regex_str,
                                          int match_index) {
    var session = new Soup.SessionAsync();
    var msg     = new Soup.Message("GET", first_url);
    session.send_message(msg);
    session.queue_message(msg, (_s, _msg) => {
    string back = (string)_msg.response_body.data;
      try{
        var regex = new GLib.Regex(regex_str, RegexCompileFlags.OPTIMIZE);
        MatchInfo info;
        regex.match(back, 0, out info);
        string real_url = info.fetch(match_index);
        if(real_url != null)
          load_inline_media.begin(t, real_url, session);
      } catch (GLib.RegexError e) {
        critical("Regex Error(%s): %s", regex_str, e.message);
      }
    });

  }

  private static async void load_inline_media(Tweet t, string url,
                                         Soup.Session? sess = null) {

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


    Soup.Session session = sess;
    debug("Directly Downloading %s", url);
    if(session == null)
      session = new Soup.SessionAsync();

    var msg = new Soup.Message("GET", url);

    session.queue_message(msg, (s, _msg) => {
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

        Gdk.Pixbuf thumb = null;
        if(ext == "gif"){
          var file = File.new_for_path(path);
          var fout = file.create(FileCreateFlags.REPLACE_DESTINATION);
          fout.write_all(_msg.response_body.data, null);
          fout.flush();
          var anim = new Gdk.PixbufAnimation.from_file(path);
          thumb = anim.get_static_image().scale_simple(THUMB_SIZE, THUMB_SIZE,
                        Gdk.InterpType.TILES);
        } else {
          var pic = new Gdk.Pixbuf.from_stream(ms);
          pic.save(path, ext);
          int x, y, w, h;
          calc_thumb_rect (pic.get_width (), pic.get_height (), out x, out y, out w, out h);
          var big_thumb = new Gdk.Pixbuf (Gdk.Colorspace.RGB, true, 8, w, h);
          pic.copy_area (x, y, w, h, big_thumb, 0, 0);
          thumb = big_thumb.scale_simple (THUMB_SIZE, THUMB_SIZE, Gdk.InterpType.TILES);
        }

        thumb.save(thumb_path, "png");
        fire_media_added(t, path, thumb, thumb_path);
      } catch (GLib.Error e) {
        critical(e.message + "for MEDIA " + url);
      }
    });
  }

  private static void fire_media_added(Tweet t, string path, Gdk.Pixbuf thumb,
                                       string thumb_path) {
    t.media = path;
    t.media_thumb = thumb_path;
    t.inline_media_added(thumb);
    t.has_inline_media = true;
  }

  private static string get_media_path (Tweet t, string url) {
    string ext = Utils.get_file_type (url);
    ext = ext.down();
    if(ext.length == 0)
      ext = "png";

    return Utils.user_file(@"assets/media/$(t.id)_$(t.user_id).$(ext)");
  }

  private static string get_thumb_path (Tweet t, string url) {
    return Utils.user_file(@"assets/media/thumbs/$(t.id)_$(t.user_id).png");
  }

  /**
   * Calculates the region of the image the thumbnail should be composed of.
   *
   * @param img_width  The width of the original image
   * @param img_height The height of the original image
   *
   */
  private static void calc_thumb_rect (int img_width, int img_height,
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
