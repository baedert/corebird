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

public class Twitter : GLib.Object {
  private static Twitter twitter;

  public static new Twitter get () {
    if (twitter == null)
      twitter = new Twitter ();

    return twitter;
  }

  public Twitter () {}

  public delegate void AvatarDownloadedFunc (Cairo.Surface avatar);
  [Signal (detailed = true)]
  private signal void avatar_downloaded (Cairo.Surface avatar);

  public static int short_url_length         { public get; private set; default = 22;}
  public static int short_url_length_https   { public get; private set; default = 23;}
  public static int max_media_per_upload     { public get; private set; default = 4; }
  public static Cairo.Surface no_avatar;
  public static Gdk.Pixbuf no_banner; // XXX Use surface.
  public Gee.HashMap<string, Cairo.Surface?> avatars;
  public Gee.HashMap<Cairo.Surface, uint> avatar_refcounts;

  public void init () {
    try {
      Twitter.no_avatar = Gdk.cairo_surface_create_from_pixbuf (
                               new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/assets/no_avatar.png"),
                               1,
                               null);
      Twitter.no_banner = new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/assets/no_banner.png");
    } catch (GLib.Error e) {
      error ("Error while loading assets: %s", e.message);
    }

    avatars = new Gee.HashMap<string, Cairo.Surface?> ();
    avatar_refcounts = new Gee.HashMap<Cairo.Surface, uint> ();
  }

  public static void ref_avatar (Cairo.Surface surface) {
    uint cur = twitter.avatar_refcounts.get (surface);
    twitter.avatar_refcounts.unset (surface);
    twitter.avatar_refcounts.set (surface, cur + 1);
  }

  public static void unref_avatar (Cairo.Surface surface) {
    uint cur = twitter.avatar_refcounts.get (surface);
    uint next = cur - 1;
    twitter.avatar_refcounts.unset (surface);

    if (next > 0)
      twitter.avatar_refcounts.set (surface, next);
    else {
      var iter = twitter.avatars.map_iterator ();

      string? path = null;
      while (iter.next ()) {
        if (iter.get_value () == surface) {
          path = iter.get_key ();
          break;
        }
      }

      if (path != null)
        twitter.avatars.unset (path);
    }
  }


  /**
   * Get the avatar with the given url. If the avatar exists on the
   * hard drive already, it is loaded and returned immediately. If
   * the avatar is in memory already, that version is returned.
   * If the avatar is neither on disk nor in memory, it will be downladed
   * first and set via the supplied `func`.
   *
   * Example usage:
   *
   * Gdk.Pixbuf? a = get_avatar("http://foo", (avatar) => {
   *   a = avatar;
   * });
   * (a may be null here)
   *
   * @param url The url of the avatar to return
   * @param func The AvatarDownloadedFunc to call once the avatar has been
   *             downloaded successfully.
   *
   * @return The requested avatar if it was already downloaded/in ram, or null
   *         if it has to be downloaded first, in which case the AvatarDownloadedFunc
   *         will be called after that's finished.
   */
  public Cairo.Surface? get_avatar (string url, owned AvatarDownloadedFunc? func = null, int size = 48) { // {{{
    Cairo.Surface? a = avatars.get (url);
    bool has_key = avatars.has_key (url);

    if (a != null) {
      return a;
    }

    // Someone is already downloading the avatar
    if (has_key) {
      // wait until the avatar has finished downloading
      ulong handler_id = 0;
      handler_id = this.avatar_downloaded[url].connect ((ava) => {
        func (ava);
        this.disconnect (handler_id);
      });
    } else {
      // download the avatar
      avatars.set (url, null);
      TweetUtils.download_avatar.begin (url, size, (obj, res) => {
        Gdk.Pixbuf? avatar = null;
        try {
          avatar = TweetUtils.download_avatar.end (res);
        } catch (GLib.Error e) {
          warning (e.message + " for " + url);
          func (no_avatar);
          this.avatars.set (url, no_avatar);
          return;
        }
        var s = Gdk.cairo_surface_create_from_pixbuf (avatar, 1, null);
        func (s);
        // signal all the other waiters in the queue
        avatar_downloaded[url](s);
        this.avatars.set (url, s);
        this.avatar_refcounts.set (s, 0);
      });
    }


    // Return null for now, set the actual value in the callback
    return null;
  } // }}}

  //TODO: Add method to update config
}
