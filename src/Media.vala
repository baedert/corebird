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

public enum MediaType {
  IMAGE,
  VINE,
  GIF,
  ANIMATED_GIF,
  TWITTER_VIDEO,

  UNKNOWN
}

public class Media : GLib.Object{
  public int64 id;
  public string path;
  public string url;
  private string? _thumb_url = null;
  public string thumb_url {
    get {
      return _thumb_url ?? url;
    }
    set {
      _thumb_url = value;
    }
  }
  private string _target_url;
  public string target_url {
    get {
      return _target_url ?? url;
    }
    set {
      _target_url = value;
    }
  }
  public int64 length { get; set; default = 0; }
  public double percent_loaded { get; set; default = 0; }
  public MediaType type;
  public Cairo.Surface? thumbnail = null;
  public Cairo.Surface? fullsize_thumbnail = null; /* XXX Remove this after full-media gets merged */
  /** If this media is fully downloaded and thumb is available */
  public bool loaded = false;
  public bool invalid = false;

  public signal void finished_loading ();

  public static MediaType type_from_string (string s) {
    if (s == "photo")
      return MediaType.IMAGE;

    return MediaType.UNKNOWN;
  }

  /**
   * Returns the type of a media based on its URL.
   * Do not call this unless you used InlineMediaDownloader.is_media_candidate
   * before.
   *
   * @param url The url to check
   *
   * @return The media type
   */
  public static MediaType type_from_url (string url) {
    if (url.has_prefix ("https://vine.co/v/"))
      return MediaType.VINE;

    if (url.has_suffix ("/photo/1"))
      return MediaType.ANIMATED_GIF;

    if (url.down ().has_suffix (".gif"))
      return MediaType.GIF;

    return MediaType.IMAGE;
  }

  public inline bool is_video () {
    return this.type == MediaType.ANIMATED_GIF ||
           this.type == MediaType.VINE ||
           this.type == MediaType.TWITTER_VIDEO;
  }
}
