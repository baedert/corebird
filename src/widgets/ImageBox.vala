/*  This file is part of corebird.
 *
 *  Foobar is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Foobar is distributed in the hope that it will be useful,
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
	public bool use_ratio{get; set; default=true;}

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

	public void set_background(string path){
		string banner_css = "*{
		background-image: url('%s');
		background-size: 100% 100%;
		background-repeat: no-repeat;
		}".printf(path);

		try{
			CssProvider prov = new CssProvider();
			prov.load_from_data(banner_css, -1);
			this.get_style_context().add_provider(prov,
		                       	         STYLE_PROVIDER_PRIORITY_APPLICATION);
		} catch (GLib.Error e){
			warning(e.message);
		}
	}
}
