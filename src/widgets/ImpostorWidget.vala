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
  private new Cairo.Surface? surface = null;


  public ImpostorWidget () {
    this.halign = Gtk.Align.FILL;
    this.valign = Gtk.Align.FILL;
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    if (this.surface == null)
      return;

    var texture = Cb.Utils.surface_to_texture (surface,
                                               this.get_scale_factor ());
    Graphene.Rect bounds = {};
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    bounds.size.width = get_allocated_width ();
    bounds.size.height = get_allocated_height ();
    snapshot.append_texture (texture, bounds, "Clone Texture");
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
