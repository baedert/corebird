/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2015 Ricardo Borges Junior
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

/* Stores the country and the WOEID of a location */
public class Place{
  public string country {public get; public set;}
  public int32 woeid {public get; public set;}
}

public class Location : GLib.Object{
  private Gee.HashMap<string, Place> locations = new Gee.HashMap<string, Place>();
  public string name {public get; public set;}
  public int32 woeid {public get; public set;}
  public string country {public get; public set;}


  private static GLib.Once<Location> _instance;
  /* Location singleton */
  public static unowned Location instance () {
    return _instance.once (() => { return new Location (); });
  }

  public void set_locations (Json.Array locations_nodes){    
    foreach (var location_node in locations_nodes.get_elements()) {
      Place  place = new Place();
      var location = location_node.get_object();
      place.country = location.get_string_member ("country");
      place.woeid = (int32) location.get_int_member ("woeid");
      this.locations.set(location.get_string_member ("name"), place);
    }
  }

  public Gee.HashMap<string, Place> get_locations (){
    return this.locations;
  }

  public int32 lookup(string place_name){
    Place place = this.locations.get(place_name);
    return place.woeid;
  }
}
