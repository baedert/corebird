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

using Gtk;

/**
 * A normal box, but with an image as background.
 */
class ImageBox : Gtk.Box  {
  private static const float RATIO = (160f/320f);
  public bool use_ratio {get; set; default=true;}
  private Gtk.CssProvider css_provider;

  public ImageBox(Orientation orientation, int spacing){
    GLib.Object(orientation: orientation, spacing: spacing);
  }

  public override bool draw(Cairo.Context c){

    Allocation alloc;
    this.get_allocation(out alloc);
    var sc = this.get_style_context();

    //Boxes do not draw any background! YAY
    sc.render_background(c, 0, 0, alloc.width, alloc.height);
    base.draw(c);
    return false;
  }

  public override void get_preferred_height_for_width(int width, out int min_height,
                                                      out int natural_height){

    int min, natural;
    base.get_preferred_height_for_width(width, out min, out natural);

    if(!use_ratio){
      min_height     = min;
      natural_height = natural;
      return;
    }


    int ratio_height = (int)(width * RATIO);

    if(min > ratio_height) {
      min_height = min;
      natural_height = natural;
    } else {
      min_height = (int)(width * RATIO);
      natural_height = (int)(width * RATIO);
    }


  }

  public override SizeRequestMode get_request_mode(){
    return SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public void set_background (string path) {
    string banner_css = "*{
    background-image: url('%s');
    background-size: cover;
    background-repeat: no-repeat;
    }".printf (path);

    var style_context = this.get_style_context ();
    try {

      if (css_provider != null)
        style_context.remove_provider (css_provider);

      css_provider = new Gtk.CssProvider ();
      css_provider.load_from_data(banner_css, -1);
      this.get_style_context().add_provider (css_provider,
                                     STYLE_PROVIDER_PRIORITY_APPLICATION);
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }
}
