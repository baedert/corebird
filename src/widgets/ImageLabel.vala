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

/**
 * Displays an icon on the left/right side of the
 * specified text. Helps to reduce the complexity of layouts.
 */
class ImageLabel : Label {
  /** The icon to display */
  public Gdk.Pixbuf icon {get; set;}
  /** The gap between icon and text */
  public int gap{get; set; default = 2;}
  public Gtk.PositionType icon_pos = Gtk.PositionType.LEFT;


  public ImageLabel(string text){
    this.label = text;
  }

  public override bool draw(Cairo.Context c){
    StyleContext context = this.get_style_context();
    if(icon_pos == PositionType.LEFT){
      context.render_icon(c, icon, 0, 0);
      c.translate(icon.width + gap, 0);
      base.draw(c);
    } else {
      base.draw(c);
      c.translate(base.get_allocated_width() - icon.width, 0);
      context.render_icon(c, icon, 0, 0);
    }


    return false;
  }

    public override void size_allocate (Allocation allocation) {
      allocation.width += icon.width + gap;
      base.size_allocate (allocation);
  }
}
