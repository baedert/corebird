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

[GtkTemplate (ui = "/org/baedert/corebird/ui/image-crop-dialog.ui")]
public class ImageCropDialog : Gtk.Dialog {
  [GtkChild]
  private Gtk.Stack stack;
  [GtkChild]
  private Gtk.FileChooserWidget file_chooser;
  [GtkChild]
  private CropWidget crop_widget;
  [GtkChild]
  private Gtk.Button back_button;
  [GtkChild]
  private Gtk.Button next_button;


  public ImageCropDialog () {
    Gtk.FileFilter filter = new Gtk.FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    file_chooser.set_filter (filter);
  }


  [GtkCallback]
  private void back_button_clicked_cb () {
    stack.visible_child = file_chooser;
  }

  [GtkCallback]
  private void next_button_clicked_cb () {

    /* Prepare crop widget with selected image */
    string selected_file = file_chooser.get_filename ();

    crop_widget.load_file_async.begin (selected_file, null, () => {
      stack.visible_child = crop_widget;
    });


  }
}
