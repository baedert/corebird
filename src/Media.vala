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

  UNKNOWN
}

public class Media {
  public int64 id;
  public string path;
  public string thumb_path;
  public string url;
  public MediaType type;
  public Gdk.Pixbuf thumbnail = null;
  /** If this media if fully downloaded and thumb is available */
  public bool loaded = false;

  public signal void finished_loading ();

  public static MediaType type_from_string (string s) {
    if (s == "photo")
      return MediaType.IMAGE;

    return MediaType.UNKNOWN;
  }
}
