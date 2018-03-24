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
  private Gsk.RenderNode? cloned_node = null;


  public ImpostorWidget () {
    this.halign = Gtk.Align.FILL;
    this.valign = Gtk.Align.FILL;
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    if (this.cloned_node != null) {
      snapshot.append_node (this.cloned_node);
    }
  }

  public void clone (Gtk.Widget widget) {
    var snapshot = new Gtk.Snapshot (null, false, null, "Clone of %s", widget.get_name ());
    widget.snapshot (snapshot);
    this.cloned_node = snapshot.to_node ();
  }
}
