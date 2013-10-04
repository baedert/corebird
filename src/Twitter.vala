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
//  private static int max_media_per_upload;
//  private static int characters_reserved_per_media;
  public static int short_url_length         { public get; private set; default = 22;}
  public static int short_url_length_https   { public get; private set; default = 23;}
//  private static int photo_size_limit;
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

  //TODO: Add method to update config
}
