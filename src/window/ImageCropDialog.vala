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
  private CropWidget crop_widget;
  [GtkChild]
  private Gtk.Button save_button;
  [GtkChild]
  private Gtk.Label error_label;

  public signal void image_cropped (Gdk.Pixbuf result);

  public int min_width;
  public int min_height;


  public ImageCropDialog (double aspect_ratio) {
    GLib.Object (use_header_bar: Gtk.Settings.get_default ().gtk_dialogs_use_header ? 1 : 0);
    crop_widget.desired_aspect_ratio = aspect_ratio;
  }

  [GtkCallback]
  private void save_button_clicked_cb () {
    /* Crop the widget and save it... */
    image_cropped (crop_widget.get_cropped_image ());
    this.destroy ();
  }

  [GtkCallback]
  private void select_image_button_clicked_cb () {
    var filechooser = new Gtk.FileChooserDialog (_("Select Banner Image"),
                                                 this,
                                                 Gtk.FileChooserAction.OPEN,
                                                 _("Cancel"),
                                                 Gtk.ResponseType.CANCEL,
                                                 _("Open"),
                                                 Gtk.ResponseType.ACCEPT);
    filechooser.select_multiple = false;
    filechooser.modal = true;

    filechooser.response.connect ((id) => {
      if (id == Gtk.ResponseType.ACCEPT) {
        string selected_file = filechooser.get_filename ();
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
          save_button.sensitive = true;
        } else {
          string error_str = "";
          error_str += _("Image does not meet minimum size requirements:") + "\n";
          error_str += ngettext ("Minimum width: %d pixel", "Minimum width: %d pixels", min_width)
                       .printf (min_width) + "\n";
          error_str += ngettext ("Minimum height: %d pixel", "Minimum height: %d pixels", min_height)
                       .printf (min_height);
          error_label.label = error_str;
          stack.visible_child = error_label;
          save_button.sensitive = false;
        }
      }
      filechooser.destroy ();
    });

    var filter = new Gtk.FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    filechooser.set_filter (filter);

    filechooser.show_all ();

  }

  public void set_min_size (int min_width) {
    crop_widget.set_min_size (min_width);
  }
}
