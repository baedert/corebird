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
 * A button with the given pixbuf as background.
 */
class PixbufButton : Button {
  private Gdk.Pixbuf bg;


  public PixbufButton(){
    this.border_width = 0;
    get_style_context().add_class("pixbuf-button");
  }

  public override bool draw(Cairo.Context c){
    if(bg != null){
      StyleContext context = this.get_style_context();
      context.render_icon(c, bg, 0, 0);
    }

    // The css-styled background should be transparent.
    base.draw(c);
    return false;
  }

  public void set_bg(Gdk.Pixbuf bg){
    this.bg = bg;
    this.set_size_request(bg.get_width(), bg.get_height());
    this.queue_draw();
  }
}
