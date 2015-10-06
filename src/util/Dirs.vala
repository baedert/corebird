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


namespace Dirs {
  static string? config_dir = null;
  static string? cache_dir  = null;
  static string? data_dir   = null;


  public void create_dirs () {
    create_folder (cache (""));
    create_folder (cache ("assets"));
    create_folder (cache ("assets/banners/"));
    create_folder (cache ("assets/media/"));
    create_folder (config (""));
    create_folder (config ("accounts/"));
    create_folder (data (""));
    create_folder (data ("logs/"));
  }

  public string cache (string path) {
    if (cache_dir == null) {
      cache_dir = GLib.Environment.get_user_cache_dir () + "/corebird/";
    }
    return cache_dir + path;
  }

  string data (string path) {
    if (data_dir == null) {
      data_dir = GLib.Environment.get_user_data_dir () + "/corebird/";
    }
    return data_dir + path;
  }

  public string config (string path) {
    if (config_dir == null) {
      config_dir = GLib.Environment.get_home_dir () + "/.corebird/";
      if (!GLib.FileUtils.test (config_dir, GLib.FileTest.EXISTS)) {
        config_dir = GLib.Environment.get_user_config_dir () + "/corebird/";
      }
    }
    return config_dir + path;
  }

  private void create_folder (string path) {
    if (FileUtils.test (path, FileTest.EXISTS))
      return;

    try {
      bool success = File.new_for_path (path)
                         .make_directory ();
      if (!success) {
        critical("Couldn't create user folder %s", path);
      }
    } catch (GLib.Error e) {
      critical ("%s(%s)", e.message, path);
    }
  }
}
