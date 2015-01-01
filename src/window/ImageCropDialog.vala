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
  [GtkChild]
  private Gtk.Label error_label;

  public signal void image_cropped (Gdk.Pixbuf result);

  public int min_width;
  public int min_height;


  public ImageCropDialog (double aspect_ratio) {
    GLib.Object (use_header_bar: Gtk.Settings.get_default ().gtk_dialogs_use_header ? 1 : 0);
    Gtk.FileFilter filter = new Gtk.FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    file_chooser.set_filter (filter);
    crop_widget.desired_aspect_ratio = aspect_ratio;
  }


  public override void response (int response_id) {
    if (response_id == Gtk.ResponseType.CANCEL) {
      this.destroy ();
    } else if (response_id == Gtk.ResponseType.OK) {
      next.begin ();
    } else if (response_id == 1) {
      // back
      stack.visible_child = file_chooser;
      back_button.sensitive = false;
      next_button.label = _("Next");
      selection_changed_cb ();
    }
  }

  [GtkCallback]
  private void selection_changed_cb () {
    string? selected_file = file_chooser.get_filename ();

    if (selected_file == null)
      return;

    GLib.File f = GLib.File.new_for_path (selected_file);
    GLib.FileType file_type = f.query_file_type (GLib.FileQueryInfoFlags.NONE, null);
    if (file_type == GLib.FileType.DIRECTORY)
      next_button.sensitive = false;
    else
      next_button.sensitive = true;
  }

  [GtkCallback]
  private async void next () {

    if (stack.visible_child == file_chooser) {
      /* Prepare crop widget with selected image */
      string selected_file = file_chooser.get_filename ();

      stack.visible_child = crop_widget;
      /* Load the file now, check for min size etc. */
      Gdk.Pixbuf? image = null;
      try {
        image = new Gdk.Pixbuf.from_file (selected_file);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }

      if (image.get_width () >= min_width &&
          image.get_height () >= min_height) {
        crop_widget.set_image (image);
        next_button.label = _("Save");
        next_button.sensitive = true;
        back_button.sensitive = true;
      } else {
        string error_str = "";
        error_str += _("Image does not meet minimum size requirements:") + "\n";
        error_str += ngettext ("Minimum width: %d pixel", "Minimum width: %d pixels", min_width)
                     .printf (min_width) + "\n";
        error_str += ngettext ("Minimum height: %d pixel", "Minimum height: %d pixels", min_height)
                     .printf (min_height);
        error_label.label = error_str;
        stack.visible_child = error_label;
        back_button.sensitive = true;
        next_button.sensitive = false;
      }


    } else {
      /* Crop the widget and save it... */
      image_cropped (crop_widget.get_cropped_image ());
      this.destroy ();
    }
  }

  public void set_min_size (int min_width) {
    crop_widget.set_min_size (min_width);
  }
}
