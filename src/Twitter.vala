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

using Rest;
using Gee;

class Twitter {
  [CCode (has_target = false)]
  public delegate void AvatarDownloadedFunc(Gdk.Pixbuf avatar);
  [Signal (detailed = true)]
  private signal void avatar_downloaded (Gdk.Pixbuf avatar);

  public static int short_url_length         { public get; private set; default = 22;}
  public static int short_url_length_https   { public get; private set; default = 23;}
  public static Gdk.Pixbuf no_avatar;
  public static Gdk.Pixbuf no_banner;
  public static Gdk.Pixbuf verified_icon;
  public static HashMap<string, Gdk.Pixbuf?> avatars;

  public static void init () {
    try {
      Twitter.no_avatar     = new Gdk.Pixbuf.from_file(
                                     DATADIR+"/no_avatar.png");
      Twitter.no_banner     = new Gdk.Pixbuf.from_file(
                                     DATADIR+"/no_banner.png");
      Twitter.verified_icon = new Gdk.Pixbuf.from_file(
                                     DATADIR+"/verified.png");
    } catch (GLib.Error e) {
      error ("Error while loading assets: %s", e.message);
    }

    Twitter.avatars = new HashMap<string, Gdk.Pixbuf> ();
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
   * Gdk.Pixbuf?a = get_avatar("http://foo", (avatar) => {
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
  public Gdk.Pixbuf? get_avatar (string url, owned AvatarDownloadedFunc? func = null) { // {{{
    Gdk.Pixbuf? a = avatars.get (url);
    bool has_key = avatars.has_key (url);

    if (a != null) {
      return a;
    }

    string avatar_name = Utils.get_avatar_name (url);
    string avatar_dest = Utils.user_file ("assets/avatars/" + avatar_name);
    // If the image already exists but is not loaded in ram yet,
    // just load it and return it.
    if (FileUtils.test (avatar_dest, FileTest.EXISTS)) {
      try {
        var p = new Gdk.Pixbuf.from_file (avatar_dest);
        avatars.set (url, p);
        return p;
      } catch (GLib.Error e) {
        critical ("Error while loading avatar `%s`: %s", url, e.message);
      }
    }

    // Someone is already downloading the avatar
    if (has_key) {
      // wait until the avatar has finished downloading
      // i.e. connect to a signal or something...
      this.avatar_downloaded[url].connect((ava) => {
        func (ava);
      });
    } else {
      // download the avatar
      avatars.set (url, null);
      TweetUtils.download_avatar.begin (url, (obj, res) => {
        Gdk.Pixbuf? avatar;
        try {
          avatar = TweetUtils.download_avatar.end (res);
        } catch (GLib.Error e) {
          critical (e.message);
          return;
        }
        func (avatar);
        // signal all the other waiters in the queue
        this.avatar_downloaded[url](avatar);
      });
    }

    // Return null for now, set the actual value in the callback
    return null;
  } // }}}

  //TODO: Add method to update config
}
