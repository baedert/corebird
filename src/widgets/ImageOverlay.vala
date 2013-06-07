/*  This file is part of corebird.
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


class ImageOverlay : Gtk.Image {
	public Gdk.Pixbuf overlay_image {get; set; default = null;}

	public ImageOverlay() {
		this.get_style_context().add_class("image-overlay");
	}



	public override bool draw(Cairo.Context c) {
		Gtk.StyleContext style_context = this.get_style_context();
		Gtk.Border padding = style_context.get_padding(get_state_flags());
		c.translate(0, padding.top);
		base.draw(c);
		if(overlay_image != null)
			style_context.render_icon(c, overlay_image,
			                          get_allocated_width() - 16,
			                          0);

		return false;
	}

	public override void get_preferred_width(out int minimum, out int natural) {
		int m, n;
		base.get_preferred_width(out m, out n);
		Gtk.Border padding = get_style_context().get_padding(get_state_flags());
		minimum = m + padding.left + padding.right;
		natural = n + padding.left + padding.right;
	}

	public override void get_preferred_height(out int minimum, out int natural) {
		int m, n;
		base.get_preferred_height(out m, out n);
		Gtk.Border padding = get_style_context().get_padding(get_state_flags());
		minimum = m + padding.top + padding.bottom;
		natural = n + padding.top + padding.bottom;
	}

}