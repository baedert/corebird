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

  [Signal (detailed = true)]
  private signal void avatar_downloaded (Gdk.Texture avatar);

  public const int MAX_BYTES_PER_IMAGE    = 1024 * 1024 * 3;
  public const int short_url_length       = 23;
  public const int max_media_per_upload   = 4;
  public static Gdk.Texture no_avatar;
  public static Gdk.Pixbuf no_banner;
  private Cb.AvatarCache avatar_cache;

  public void init () {
    try {
      Twitter.no_avatar = Gdk.Texture.from_resource ("/org/baedert/corebird/data/no_avatar.png");
      Twitter.no_banner = new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/no_banner.png");
    } catch (GLib.Error e) {
      error ("Error while loading assets: %s", e.message);
    }

    this.avatar_cache = new Cb.AvatarCache ();
  }

  public void ref_avatar (Gdk.Texture texture) {
    this.avatar_cache.increase_refcount_for_texture (texture);
  }

  public void unref_avatar (Gdk.Texture texture) {
    this.avatar_cache.decrease_refcount_for_texture (texture);
  }

  public bool has_avatar (int64 user_id) {
    return (get_cached_avatar (user_id) != Twitter.no_avatar);
  }

  public Gdk.Texture get_cached_avatar (int64 user_id) {
    bool found;
    Gdk.Texture? texture = this.avatar_cache.get_texture_for_id (user_id, out found);

    return texture ?? Twitter.no_avatar;
  }

  /* This is a get_avatar version for times where we don't have an at least
     relatively recent avatar_url for the given account.

     This will first query the account details of the given account,
     then use the avatar_url to download the avatar and insert it
     into the avatar cache */
  public async Gdk.Texture? load_avatar_for_user_id (Account account,
                                                     int64   user_id,
                                                     int     size) {
    Gdk.Texture? s;
    bool found = false;

    s = avatar_cache.get_texture_for_id (user_id, out found);

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
      root = yield Cb.Utils.load_threaded_async (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return null;
    }

    if (root == null)
      return null;

    var root_obj = root.get_object ();
    string avatar_url = root_obj.get_string_member ("profile_image_url");

    this.avatar_cache.set_url (user_id, avatar_url);

    s = yield this.get_texture (user_id, avatar_url, size, true);

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
   */
  public async void get_avatar (int64        user_id,
                                string       url,
                                AvatarWidget dest_widget,
                                int          size = 48,
                                bool         force_download = false) {
    dest_widget.texture = yield this.get_texture (user_id, url, size, force_download);
  }

  private async Gdk.Texture? get_texture (int64  user_id,
                                          string url,
                                          int    size = 48,
                                          bool   force_download = false) {
    assert (user_id > 0);
    bool has_key = false;
    Gdk.Texture? a = this.avatar_cache.get_texture_for_id (user_id, out has_key);

    bool new_url = a == Twitter.no_avatar &&
                        url != this.avatar_cache.get_url_for_id (user_id);

    if (a != null && !new_url) {
      return a;
    }

    if (has_key && !new_url && !force_download) {
      // wait until the avatar has finished downloading
      ulong handler_id = 0;
      handler_id = this.avatar_downloaded[user_id.to_string ()].connect ((ava) => {
        this.disconnect (handler_id);
        a = ava;
        get_texture.callback ();
      });
      yield;
      return a;
    } else {
      // download the avatar
      this.avatar_cache.add (user_id, null, url);
      Gdk.Pixbuf? avatar = null;
      try {
        avatar = yield TweetUtils.download_avatar (url, size);
      } catch (GLib.Error e) {
        warning ("%s for %s", e.message, url);
      }

      Gdk.Texture s;
      // E.g. in the 404 case...
      if (avatar == null)
        s = Twitter.no_avatar;
      else
        s = Gdk.Texture.for_pixbuf (avatar);

      // a NULL texture is already in the cache
      this.avatar_cache.set_avatar (user_id, s, url);

      // signal all the other waiters in the queue
      avatar_downloaded[user_id.to_string ()](s);
      return s;
    }
  }

}
