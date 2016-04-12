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

  private Twitter () {}
  public static new Twitter get () {
    if (twitter == null)
      twitter = new Twitter ();

    return twitter;
  }


  public delegate void AvatarDownloadedFunc (Cairo.Surface avatar);
  [Signal (detailed = true)]
  private signal void avatar_downloaded (Cairo.Surface avatar);

  public const int MAX_BYTES_PER_IMAGE    = 1024 * 1024 * 3;
  public const int short_url_length       = 23;
  public const int short_url_length_https = 23;
  public const int max_media_per_upload   = 4;
  public const int characters_reserved_per_media = 24;
  public static Cairo.Surface no_avatar;
  public static Gdk.Pixbuf no_banner;
  private AvatarCache avatar_cache;

#if DEBUG
  public void debug () {
    this.avatar_cache.print_debug ();
  }
#endif

  public void init () {
    try {
      Twitter.no_avatar = Gdk.cairo_surface_create_from_pixbuf (
                               new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/no_avatar.png"),
                               1,
                               null);
      Twitter.no_banner = new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/no_banner.png");
    } catch (GLib.Error e) {
      error ("Error while loading assets: %s", e.message);
    }

    this.avatar_cache = new AvatarCache ();
  }

  public void ref_avatar (Cairo.Surface surface) {
    this.avatar_cache.increase_refcount_for_surface (surface);
  }

  public void unref_avatar (Cairo.Surface surface) {
    this.avatar_cache.decrease_refcount_for_surface (surface);
  }

  public bool has_avatar (int64 user_id) {
    return (get_cached_avatar (user_id) != Twitter.no_avatar);
  }

  public Cairo.Surface get_cached_avatar (int64 user_id) {
    bool found;
    Cairo.Surface? surface = this.avatar_cache.get_surface_for_id (user_id, out found);
    if (surface == null)
      return Twitter.no_avatar;
    else
      return surface;
  }

  /* This is a get_avatar version for times where we don't have an at least
     relatively recent avatar_url for the given account.

     This will first query the account details of the given account,
     then use the avatar_url to download the avatar and insert it
     into the avatar cache */
  public async Cairo.Surface? load_avatar_for_user_id (Account account,
                                                       int64   user_id,
                                                       int     size) {
    Cairo.Surface? s;
    bool found = false;

    s = avatar_cache.get_surface_for_id (user_id, out found);

    if (s != null) {
      assert (found);
      return s;
    }

    if (s == null && found) {
      ulong handler_id = 0;
      handler_id = this.avatar_downloaded[user_id.to_string ()].connect ((ava) => {
        s = ava;
        this.disconnect (handler_id);
        this.load_avatar_for_user_id.callback ();
      });
      yield;

      assert (s != null);
      return s;
    }

    this.avatar_cache.add (user_id, null, null);

    // We first need to get the avatar url for the given user id...
    var call = account.proxy.new_call ();
    call.set_function ("1.1/users/show.json");
    call.set_method ("GET");
    call.add_param ("user_id", user_id.to_string ());
    call.add_param ("include_entities", "false");

    Json.Node? root = null;
    try {
      root = yield TweetUtils.load_threaded (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return null;
    }

    if (root == null)
      return null;

    var root_obj = root.get_object ();
    string avatar_url = root_obj.get_string_member ("profile_image_url");

    this.avatar_cache.set_url (user_id, avatar_url);

    s = Twitter.get ().get_avatar (user_id, avatar_url, (a) => {
      s = a;
      load_avatar_for_user_id.callback ();
    }, size, true);

    if (s != null)
      return s;
    else
      yield;

    return s;
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

  public Cairo.Surface? get_avatar (int64  user_id,
                                    string url,
                                    owned AvatarDownloadedFunc? func = null,
                                    int size = 48,
                                    bool force_download = false) {
    assert (user_id > 0);
    bool has_key = false;
    Cairo.Surface? a = this.avatar_cache.get_surface_for_id (user_id, out has_key);

    bool new_url = a == Twitter.no_avatar &&
                        url != this.avatar_cache.get_url_for_id (user_id);

    if (a != null && !new_url) {
      return a;
    }

    if (has_key && !new_url && !force_download) {
      // wait until the avatar has finished downloading
      ulong handler_id = 0;
      handler_id = this.avatar_downloaded[user_id.to_string ()].connect ((ava) => {
        func (ava);
        this.disconnect (handler_id);
      });
    } else {
      // download the avatar
      this.avatar_cache.add (user_id, null, url);
      TweetUtils.download_avatar.begin (url, size, (obj, res) => {
        Gdk.Pixbuf? avatar = null;
        try {
          avatar = TweetUtils.download_avatar.end (res);
        } catch (GLib.Error e) {
          warning (e.message + " for " + url);
          func (no_avatar);
          this.avatar_cache.set_avatar (user_id, no_avatar, url);
          return;
        }

        Cairo.Surface s;
        // E.g. in the 404 case...
        if (avatar == null) {
          s = Twitter.no_avatar;
        } else
          s = Gdk.cairo_surface_create_from_pixbuf (avatar, 1, null);

        // a NULL surface is already in the cache
        this.avatar_cache.set_avatar (user_id, s, url);

        func (s);
        // signal all the other waiters in the queue
        avatar_downloaded[user_id.to_string ()](s);
      });
    }

    // Return null for now, set the actual value in the callback
    return null;
  }
}


/* Maps from int64 to {int, cairo_surface_t, char*} */
public class AvatarCache : GLib.Object {
  private GLib.Array<int64?> ids;
  private GLib.GenericArray<Cairo.Surface?> surfaces;
  private GLib.GenericArray<string> urls;
  private GLib.Array<int?> refcounts;

  public AvatarCache () {
    this.ids       = new GLib.Array<int64?> ();
    this.surfaces  = new GLib.GenericArray<Cairo.Surface?> ();
    this.refcounts = new GLib.Array<int?> ();
    this.urls      = new GLib.GenericArray<string> ();
  }

  private int get_index (int64 id) {
    for (int i = 0; i < this.ids.length; i ++) {
        if (this.ids.data[i] == id) {
        return i;
      }
    }

    return -1;
  }

  public Cairo.Surface? get_surface_for_id (int64 user_id, out bool found) {
    assert (ids.length == surfaces.length &&
            surfaces.length == refcounts.length &&
            refcounts.length == urls.length);

    int index = get_index (user_id);
    if (index != -1) {
      found = true;
      /* the surface can be null anyway here */
      return this.surfaces.data[index];
    }

    found = false;
    return null;
  }

  public string? get_url_for_id (int64 user_id) {
    int index = get_index (user_id);
    if (index != -1) {
      return this.urls[index];
    }

    return null;
  }

  public void add (int64 user_id, Cairo.Surface? surface, string? avatar_url) {

    int index;
    if ((index = get_index (user_id)) != -1) {
      this.surfaces[index] = surface;
      this.urls[index] = avatar_url;
    } else {
      this.ids.append_val (user_id);
      this.surfaces.add (surface);
      this.urls.add (avatar_url);
      this.refcounts.append_val (0);
    }

    assert (ids.length == surfaces.length && surfaces.length == refcounts.length &&
            refcounts.length == urls.length);
  }

  public void set_avatar (int64 id, Cairo.Surface? surface, string url) {
    int index = get_index (id);
    assert (index != -1);

    this.surfaces[index] = surface;
    this.urls[index] = url;
  }

  public void set_url (int64 id, string url) {
    int index = get_index (id);
    assert (index != -1);

    this.urls[index] = url;
  }

  public void increase_refcount_for_surface (Cairo.Surface surface) {
    int index = -1;
    for (int i = 0; i < this.surfaces.length; i ++) {
      if (this.surfaces.data[i] == surface) {
        index = i;
        break;
      }
    }

    if (index != -1) {
      this.refcounts.data[index] = this.refcounts.data[index] + 1;
    } else {
      //warning ("Surface %p not in cache", surface);
    }
  }

  public void decrease_refcount_for_surface (Cairo.Surface surface) {
    int index = -1;
    for (int i = 0; i < this.surfaces.length; i ++) {
      if (this.surfaces.data[i] == surface) {
        index = i;
        break;
      }
    }

    if (index == -1) {
      //warning ("Surface %p not in cache", surface);
      return;
    }

    this.refcounts.data[index] = this.refcounts.data[index] - 1;

    if (this.refcounts.data[index] == 0) {
      debug ("Removing avatar with id %d from cache (Now: %u)", index, this.ids.length - 1);
      this.ids.remove_index_fast (index);
      this.surfaces.remove_index_fast (index);
      this.urls.remove_index_fast (index);
      this.refcounts.remove_index_fast (index);
    }

    assert (ids.length == surfaces.length && surfaces.length == refcounts.length &&
            refcounts.length == urls.length);
  }

#if DEBUG
  public void print_debug () {
    message ("-----------------");
    message ("Cached avatars: %d", this.surfaces.length);
    message ("URLS:");
    for (int i = 0; i < this.urls.length; i ++)
      message ("%d: %s (id %s): %p", i, this.urls[i], this.ids.index (i).to_string (), this.surfaces[i]);

    assert (ids.length == surfaces.length && surfaces.length == refcounts.length &&
            refcounts.length == urls.length);
  }
#endif
}


