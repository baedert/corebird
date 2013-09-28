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
  private static int max_media_per_upload;
  private static int characters_reserved_per_media;
  public static int short_url_length         { public get; private set; default = 22;}
  public static int short_url_length_https   { public get; private set; default = 23;}
  private static int photo_size_limit;
  public static Gdk.Pixbuf no_avatar;
  public static Gdk.Pixbuf no_banner;
  public static Gdk.Pixbuf verified_icon;
  public static HashMap<string, Gdk.Pixbuf> avatars;


  public static void init(){
    try{
      Twitter.no_avatar     = new Gdk.Pixbuf.from_file(
                                     DATADIR+"/no_avatar.png");
      Twitter.no_banner     = new Gdk.Pixbuf.from_file(
                                     DATADIR+"/no_banner.png");
      Twitter.verified_icon = new Gdk.Pixbuf.from_file(
                                     DATADIR+"/verified.png");
    }catch(GLib.Error e){
      error("Error while loading assets: %s", e.message);
    }

    Twitter.avatars = new HashMap<string, Gdk.Pixbuf>();
  }

  /**
   * Updates the config
   */
/*  public static async void update_config(){
    // Check when the last update was
    var now = new GLib.DateTime.now_local();
    Corebird.db.exec (
      "SELECT `update_config`, `characters_reserved_per_media`,
     `max_media_per_upload`, `photo_size_limit`, `short_url_length`,
      `short_url_length_https` FROM `common`;", (n_cols, vals) => {
      int64 last_update = int64.parse (vals[0]);
      var then = new GLib.DateTime.from_unix_local(last_update);

      var diff = then.difference(now);
      if (diff < GLib.TimeSpan.DAY * 7){
        Twitter.characters_reserved_per_media = int.parse (vals[1]);
        Twitter.max_media_per_upload          = int.parse (vals[2]);
        Twitter.photo_size_limit              = int.parse (vals[3]);
        Twitter.short_url_length              = int.parse (vals[4]);
        Twitter.short_url_length_https        = int.parse (vals[5]);

      }
      return -1; //stop
    });

    var call = Twi_tter.proxy.new_call();
    call.set_method("GET");
    call.set_function("1.1/help/configuration.json");
    call.invoke_async.begin(null, (obj, res) => {
      try{
        call.invoke_async.end(res);
      } catch (GLib.Error e){
        warning("Error while refreshing config: %s", e.message);
      }
      string back = call.get_payload();
      Json.Parser parser = new Json.Parser();
      try{
        parser.load_from_data(back);
      }catch(GLib.Error e){
        warning("Error while parsing Json: %s\nData:%s", e.message, back);
        return;
      }

      var root = parser.get_root().get_object();
      Twitter.characters_reserved_per_media =
        (int)root.get_int_member("characters_reserved_per_media");
      Twitter.max_media_per_upload   = (int)root.get_int_member("max_media_per_upload");
      Twitter.photo_size_limit       = (int)root.get_int_member("photo_size_limit");
      Twitter.short_url_length       = (int)root.get_int_member("short_url_length");
      Twitter.short_url_length_https = (int)root.get_int_member("short_url_length_https");


      message("Updated the twitter configuration");
    });
  } */

  public static int get_characters_reserved_by_media(){
    return characters_reserved_per_media;
  }
  public static int get_max_media_per_upload(){
    return max_media_per_upload;
  }
  public static int get_photo_size_limit(){
    return photo_size_limit;
  }
}
