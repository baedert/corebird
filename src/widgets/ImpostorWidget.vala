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

class ImpostorWidget : Gtk.Image {
  private new Cairo.Surface surface;


  public ImpostorWidget () {
    this.halign = Gtk.Align.FILL;
    this.valign = Gtk.Align.FILL;
  }



  public override bool draw (Cairo.Context ct) {
    if (this.surface == null)
      return false;

    ct.set_source_surface (this.surface, 0, 0);
    ct.rectangle (0, 0, this.get_allocated_width (), this.get_allocated_height ());
    ct.fill ();
    return false;
  }


  public void clone (Gtk.Widget widget) {
    int widget_width  = widget.get_allocated_width ();
    int widget_height = widget.get_allocated_height ();

    this.surface = widget.get_window ().create_similar_surface (Cairo.Content.COLOR_ALPHA,
                                                                widget_width,
                                                                widget_height);
    var ct = new Cairo.Context (surface);
    widget.draw (ct);
  }
}
