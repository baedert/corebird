/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2017 Timm Bäder
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

class FavImageRow : Gtk.ListBoxRow {
  private const int THUMB_WIDTH  = 80;
  private const int THUMB_HEIGHT = 50;

  private Gtk.Box box;
  private Gtk.Image image;
  private Gtk.Label label;
  private string file_path;

  public FavImageRow(string path, string display_name) {
    this.file_path = path;
    box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    box.margin = 6;
    image = new Gtk.Image ();
    label = new Gtk.Label (display_name);

    image.set_size_request (THUMB_WIDTH, THUMB_HEIGHT);
    image.show ();
    box.add (image);
    label.hexpand = true;
    label.xalign = 0;
    label.halign = Gtk.Align.START;
    label.ellipsize = Pango.EllipsizeMode.END;
    label.show ();
    box.add (label);

    this.add (box);

    load_image.begin ();
  }

  public unowned string get_image_path () {
    return file_path;
  }

  private async void load_image () {
    try {
      var in_stream = GLib.File.new_for_path (file_path).read ();
      var pixbuf = yield new Gdk.Pixbuf.from_stream_at_scale_async (in_stream, THUMB_WIDTH, THUMB_HEIGHT, true);
      in_stream.close ();

      this.image.set_from_pixbuf (pixbuf);
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }
}
