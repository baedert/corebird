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


string canonicalize_url (string *url) {
  string *ret = url;

  if (ret->has_prefix ("http://"))
    ret = ret + 7;
  else if (ret->has_prefix ("https://"))
    ret = ret + 8;

  if (ret->has_prefix ("www."))
    ret = ret + 4;

  return ret;
}


bool is_media_candidate (string _url) {
  if (Settings.max_media_size () < 0.001)
    return false;

  string url = canonicalize_url (_url);

  return url.has_prefix ("instagr.am") ||
         url.has_prefix ("instagram.com/p/") ||
         (url.has_prefix ("i.imgur.com") && !url.has_suffix ("gifv")) ||
         url.has_prefix ("d.pr/i/") ||
         url.has_prefix ("ow.ly/i/") ||
         url.has_prefix ("flickr.com/photos/") ||
         url.has_prefix ("flic.kr/p/") ||
         url.has_prefix ("flic.kr/s/") ||
#if VIDEO
         url.has_prefix ("vine.co/v/") ||
         url.has_suffix ("/photo/1") ||
         url.has_prefix ("video.twimg.com/ext_tw_video/") ||
#endif
         url.has_prefix ("pbs.twimg.com/media/") ||
         url.has_prefix ("twitpic.com/")
  ;
}



public class InlineMediaDownloader : GLib.Object {
  private static InlineMediaDownloader instance;
  private GLib.GenericArray<unowned string> urls_downloading = new GLib.GenericArray<unowned string> ();
  [Signal (detailed = true)]
  private signal void downloading ();

  private InlineMediaDownloader () {}

  private bool downloading_url (string url) {
    for (int i = 0; i < this.urls_downloading.length; i ++) {
      if (urls_downloading.get (i) == url)
        return true;
    }

    return false;
  }

  public static new InlineMediaDownloader get () {
    if (GLib.unlikely (instance == null))
      instance = new InlineMediaDownloader ();

    return instance;
  }


  public async void load_media (MiniTweet t, Media media) {
    yield load_inline_media (t, media);
  }

  public void load_all_media (MiniTweet t, Media[] medias) {
    foreach (Media m in medias) {
      load_media.begin (t, m);
    }
  }

  private static void mark_invalid (Media m, InputStream? in_stream = null) {
    m.invalid = true;
    m.loaded = true;
    m.finished_loading ();

    if (in_stream != null) {
      try { in_stream.close (); } catch (GLib.Error e) { warning (e.message); }
    }
  }

  private async void load_instagram_url (Media media) {
    /* For instagram, we need to get the html data,
       then check if the og:medium tag says it's a video, then set the
       media type and extract the according target url */
    var msg = new Soup.Message ("GET", media.url);
    SOUP_SESSION.queue_message (msg, (_s, _msg) => {
      if (msg.status_code != Soup.Status.OK) {
        warning ("Message status: %s on %s", msg.status_code.to_string (), media.url);
        mark_invalid (media);
        return;
      }
      unowned string back = (string)_msg.response_body.data;
      try {
        MatchInfo info;
        var regex = new GLib.Regex ("<meta name=\"medium\" content=\"video\" />", 0);
        regex.match (back, 0, out info);

        if (info.get_match_count () > 0) {
          // This is a video!
          media.type = MediaType.INSTAGRAM_VIDEO;
          regex = new GLib.Regex ("<meta property=\"og:video\" content=\"(.*?)\"", 0);
          regex.match (back, 0, out info);
          media.url = info.fetch (1);
        }

        regex = new GLib.Regex ("<meta property=\"og:image\" content=\"(.*?)\"", 0);
        regex.match (back, 0, out info);
        media.thumb_url = info.fetch (1);

        load_instagram_url.callback ();
      } catch (GLib.RegexError e) {
        critical ("Regex error: %s", e.message);
        load_instagram_url.callback ();
      }
    });
    yield;
  }

  // TODO: All those load functions could use some structure...

  private async void load_twitter_video (Media media) {
    /* These can contain a gif or a video.. */
    var msg = new Soup.Message ("GET", media.url);
    SOUP_SESSION.queue_message (msg, (_s, _msg) => {
      if (msg.status_code != Soup.Status.OK) {
        warning ("Message status: %s on %s", msg.status_code.to_string (), media.url);
        mark_invalid (media);
        return;
      }
      unowned string back = (string)_msg.response_body.data;
      try {
        MatchInfo info;
        var regex = new GLib.Regex ("<img src=\"(.*?)\" class=\"animated-gif-thumbnail", 0);
        regex.match (back, 0, out info);

        if (info.get_match_count () > 0) {
          assert (media.type == MediaType.ANIMATED_GIF);
          media.url = info.fetch (1);
          load_twitter_video.callback ();
          return;
        } else {
          /* It's not a gif, so let's see if it's a video... */
          regex = new GLib.Regex ("<source video-src=\"(.*?)\"", 0);
          regex.match (back, 0, out info);
          media.url = info.fetch (1);
          media.type = MediaType.TWITTER_VIDEO;
        }

        regex = new GLib.Regex ("poster=\"(.*?)\"", 0);
        regex.match (back, 0, out info);
        media.thumb_url = info.fetch (1);

        load_twitter_video.callback ();
      } catch (GLib.RegexError e) {
        critical ("Regex error: %s", e.message);
        load_twitter_video.callback ();
      }
    });
    yield;
  }

  private async void load_real_url (MiniTweet  t,
                                    Media  media,
                                    string regex_str1,
                                    int    match_index1,
                                    bool   check_video = false) {
    var msg = new Soup.Message ("GET", media.url);
    SOUP_SESSION.queue_message (msg, (_s, _msg) => {
      if (msg.status_code != Soup.Status.OK) {
        warning ("Message status: %s on %s", msg.status_code.to_string (), media.url);
        mark_invalid (media);
        return;
      }
      string? back = (string)_msg.response_body.data;
      if (back == null) {
        warning ("Url '%s' returned null", media.url);
        mark_invalid (media);
        return;
      }

      try {
        var regex = new GLib.Regex (regex_str1, 0);
        MatchInfo info;
        regex.match (back, 0, out info);
        string real_url = info.fetch (match_index1);
        media.thumb_url = real_url;

        load_real_url.callback ();
      } catch (GLib.RegexError e) {
        critical ("Regex Error(%s): %s", regex_str1, e.message);
      }
    });
    yield;
  }

  private async void load_inline_media (MiniTweet t, Media media) {
    GLib.SourceFunc callback = load_inline_media.callback;

    if (this.downloading_url (media.url)) {
      ulong id = 0;
      id = this.downloading[media.url].connect (() => {
        this.disconnect (id);
        load_inline_media.begin (t, media, () => { callback (); });
      });
      yield;
    }

    /* We are not downloading the image ATM... */
    string url = canonicalize_url (media.url);
    if (url.has_prefix ("instagr.am") ||
        url.has_prefix ("instagram.com/p/")) {
      yield load_instagram_url (media);
    } else if (url.has_prefix ("ow.ly/i/") ||
               url.has_prefix ("flickr.com/photos/") ||
               url.has_prefix ("flic.kr/p/") ||
               url.has_prefix ("flic.kr/s/")){
      yield load_real_url (t, media, "<meta property=\"og:image\" content=\"(.*?)\"", 1);
    } else if (url.has_prefix("twitpic.com/")) {
      yield load_real_url (t, media,
                          "<meta name=\"twitter:image\" value=\"(.*?)\"", 1);
    } else if (url.has_prefix ("vine.co/v/")) {
      yield load_real_url (t, media, "<meta property=\"og:image\" content=\"(.*?)\"", 1);
    } else if (url.has_suffix ("/photo/1")) {
      yield load_twitter_video (media);
    } else if (url.has_prefix ("d.pr/i/")) {
      yield load_real_url (t, media,
                          "<meta property=\"og:image\"\\s+content=\"(.*?)\"", 1);
    }

    if (media.url == null ||
        media.thumb_url == null) {
      mark_invalid (media);
      return;
    }


    /* We check this here again, since loading e.g. instragram videos might
       change both the media type and the media url. */
    if (this.downloading_url (media.url)) {
      ulong id = 0;
      id = this.downloading[media.url].connect (() => {
        this.disconnect (id);
        load_inline_media.begin (t, media, () => { callback (); });
      });
      yield;
    }

    var msg = new Soup.Message ("GET", media.thumb_url);
    msg.got_headers.connect (() => {
      int64 content_length = msg.response_headers.get_content_length ();
      double mb = content_length / 1024.0 / 1024.0;
      double max = Settings.max_media_size ();
      if (mb > max) {
        debug ("Image %s won't be downloaded,  %fMB > %fMB", media.thumb_url, mb, max);
        mark_invalid (media);
        SOUP_SESSION.cancel_message (msg, Soup.Status.CANCELLED);
      } else {
        media.length = content_length;
      }
    });

    msg.got_chunk.connect ((buf) => {
      double percent = (double) buf.length / (double) media.length;
      media.percent_loaded += percent;
    });

    assert (!this.downloading_url (media.url));
    this.urls_downloading.add (media.url);

    SOUP_SESSION.queue_message(msg, (s, _msg) => {
      if (_msg.status_code != Soup.Status.OK) {
        debug ("Request on '%s' returned '%s'", _msg.uri.to_string (false),
               Soup.Status.get_phrase (_msg.status_code));
        mark_invalid (media);
        urls_downloading.remove_fast (media.url);
        callback ();
        return;
      }

      var ms = new MemoryInputStream.from_data (_msg.response_body.data, GLib.g_free);
      load_animation.begin (t, ms, media, () => {
        this.urls_downloading.remove_fast (media.url);
        callback ();
        this.downloading[media.url]();
      });
      yield;
    });
    yield;
  }

  private async void load_animation (MiniTweet         t,
                                     GLib.InputStream  in_stream,
                                     Media             media) {
    Gdk.PixbufAnimation anim;
    try {
      anim = yield new Gdk.PixbufAnimation.from_stream_async (in_stream, null);
    } catch (GLib.Error e) {
      warning ("%s: %s", media.url, e.message);
      mark_invalid (media, in_stream);
      return;
    }
    var pic = anim.get_static_image ();
    if (!anim.is_static_image ())
      media.animation = anim;

    media.surface = (Cairo.ImageSurface)Gdk.cairo_surface_create_from_pixbuf (pic, 1, null);
    media.width = media.surface.get_width ();
    media.height = media.surface.get_height ();
    media.loaded = true;
    media.finished_loading ();
    try {
      in_stream.close ();
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }
}
