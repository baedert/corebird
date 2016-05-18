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

public class Settings : GLib.Object {
  private static GLib.Settings settings;

  public static void init(){
    settings = new GLib.Settings("org.baedert.corebird");
  }

  public static new GLib.Settings get () {
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

  public static bool auto_scroll_on_new_tweets () {
    return settings.get_boolean ("auto-scroll-on-new-tweets");
  }

  public static string get_accel (string accel_name) {
    return settings.get_string ("accel-" + accel_name);
  }

  public static double max_media_size () {
    return settings.get_double ("max-media-size");
  }

  public static void toggle_sidebar_visible () {
    settings.set_boolean ("sidebar-visible", !settings.get_boolean ("sidebar-visible"));
  }


  public static string get_consumer_key () {
    return settings.get_string ("consumer-key");
  }

  public static string get_consumer_secret () {
    return settings.get_string ("consumer-secret");
  }

  public static void add_text_transform_flag (TransformFlags flag) {
    settings.set_uint ("text-transform-flags",
                       settings.get_uint ("text-transform-flags") | flag);
  }

  public static void remove_text_transform_flag (TransformFlags flag) {
    settings.set_uint ("text-transform-flags",
                       settings.get_uint ("text-transform-flags") & ~flag);
  }

  public static TransformFlags get_text_transform_flags () {
    return (TransformFlags) settings.get_uint ("text-transform-flags");
  }

  public static bool hide_nsfw_content () {
    return settings.get_boolean ("hide-nsfw-content");
  }
}
