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


class Settings : GLib.Object {
  private static GLib.Settings settings;

  public static void init(){
    settings = new GLib.Settings("org.baedert.corebird");
  }

  public static new GLib.Settings get (){
    return settings;
  }

  /**
   * Returns how many tweets should be stacked before a
   * notification should be created.
   */
  public static int get_tweet_stack_count() {
    int setting_val = settings.get_enum("new-tweets-notify");
    return setting_val;
  }

  /**
  * Check whether the user wants Corebird to always use the dark gtk theme variant.
  */
  public static bool use_dark_theme(){
    return settings.get_boolean("use-dark-theme");
  }

  public static bool notify_new_mentions(){
    return settings.get_boolean("new-mentions-notify");
  }

  public static bool notify_new_dms(){
    return settings.get_boolean("new-dms-notify");
  }

  public static bool notify_new_followers() {
    return settings.get_boolean("new-followers-notify");
  }

  public static int upload_provider(){
    return settings.get_enum("upload-provider");
  }

  public static bool show_inline_media(){
    return settings.get_boolean("show-inline-media");
  }

  public static bool auto_scroll_on_new_tweets () {
    return settings.get_boolean ("auto-scroll-on-new-tweets");
  }

  public static int get_animation_duration() {
    return settings.get_int("animation-duration");
  }

  public static double max_media_size () {
    return settings.get_double ("max-media-size");
  }

  public static bool get_bool (string key) {
    return settings.get_boolean (key);
  }

}
