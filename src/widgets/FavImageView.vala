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


class FavImageView : Gtk.Box {
  private Gtk.ScrolledWindow scrolled_window;
  private Gtk.FlowBox fav_image_list;
  private Gtk.Button new_fav_image_button;

  private bool gifs_enabled = true;

  public signal void image_selected (string image_path);

  construct {
    this.orientation = Gtk.Orientation.VERTICAL;

    this.scrolled_window = new Gtk.ScrolledWindow (null, null);
    this.fav_image_list = new Gtk.FlowBox ();
    fav_image_list.homogeneous = true;
    scrolled_window.set_vexpand (true);
    scrolled_window.add (this.fav_image_list);
    this.add (scrolled_window);

    this.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
    this.new_fav_image_button = new Gtk.Button.from_icon_name ("list-add-symbolic");
    new_fav_image_button.set_halign (Gtk.Align.START);
    new_fav_image_button.set_margin_start (6);
    new_fav_image_button.set_margin_top (6);
    new_fav_image_button.set_margin_bottom (6);
    new_fav_image_button.clicked.connect (new_fav_image_button_clicked_cb);
    this.add (new_fav_image_button);


    fav_image_list.set_selection_mode (Gtk.SelectionMode.NONE);
    fav_image_list.get_style_context ().add_class ("view");
    fav_image_list.get_style_context ().add_class ("fav-image-box");
    fav_image_list.child_activated.connect (fav_image_list_child_activated_cb);
    //fav_image_list.drag_data_received.connect (fav_image_list_drag_data_received_cb);

    warning ("Fix DND stuff");
    //var image_target_list = new Gtk.TargetList (null);
    //image_target_list.add_text_targets (0);

    //Gtk.drag_dest_set (this,
                       //Gtk.DestDefaults.ALL,
                       //null,
                       //Gdk.DragAction.COPY);
    //Gtk.drag_dest_set_target_list (this, image_target_list);

    /* Fuck it */
    this.show ();
  }

  public void load_images () {
    if (fav_image_list.get_children ().length () > 0)
      return;

    const int MAX_IMAGES = 50;
    string fav_image_dir = Dirs.config ("image-favorites/");
    try {
      var dir = File.new_for_path (fav_image_dir);
      var iter = dir.enumerate_children ("standard::display-name,standard::content-type",
                                         GLib.FileQueryInfoFlags.NONE);

      int i = 0;
      FileInfo? info = null;
      while ((info = iter.next_file ()) != null) {
        var content_type = info.get_content_type ();

        if (content_type == "image/jpeg" ||
            content_type == "image/png" ||
            content_type == "image/gif") {
          var file = dir.get_child (info.get_name ());
          var row = new FavImageRow (file.get_path ());

          if (content_type == "image/gif") {
            row.is_gif = true;
            row.set_sensitive (gifs_enabled);
          }

          row.show ();
          fav_image_list.add (row);

          i ++;
          if (i >= MAX_IMAGES)
            break;
        }
      }
    } catch (GLib.Error e) {
      warning (e.message);
    }

  }

  private void fav_image_list_child_activated_cb (Gtk.FlowBoxChild _child) {
    FavImageRow child = (FavImageRow) _child;

    if (!child.sensitive)
      return;

    this.image_selected (child.get_image_path ());
  }

  private void fav_image_list_drag_data_received_cb (Gdk.DragContext   context,
                                                     int               x,
                                                     int               y,
                                                     Gtk.SelectionData selection_data,
                                                     uint              info,
                                                     uint              time) {
    if (info == 0) {
      /* Text */
      string?text = selection_data.get_text ().strip ();
      if (text.has_prefix ("file://")) {
        var file = GLib.File.new_for_uri (text);
        if (!file.query_exists ()) {
          debug ("File '%s' does not exist.", text);
          return;
        }

        try {
          var file_info = file.query_info ("standard::content-type", GLib.FileQueryInfoFlags.NONE);
          var row = new FavImageRow (GLib.File.new_for_uri (text).get_path ());

          if (file_info.get_content_type () == "image/gif") {
            row.is_gif = true;
            row.set_sensitive (gifs_enabled);
          }

          row.show ();
          fav_image_list.add (row);
        } catch (GLib.Error e) {
          warning (e.message);
        }
      } else {
        debug ("Can't handle '%s'", text);
      }
    } else {
      warning ("Unknown drag data info %u", info);
    }
  }

  private void new_fav_image_button_clicked_cb () {
    var filechooser = new Gtk.FileChooserNative (_("Select Image"),
                                                 this.get_toplevel () as Gtk.Window,
                                                 Gtk.FileChooserAction.OPEN,
                                                 _("Open"),
                                                 _("Cancel"));
    var filter = new Gtk.FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    filter.add_mime_type ("image/gif");
    filechooser.set_filter (filter);

    if (filechooser.run () == Gtk.ResponseType.ACCEPT) {
      try {
        // First, take the selected file and copy it into the image-favorites folder
        var file = GLib.File.new_for_path (filechooser.get_filename ());
        var file_info = file.query_info ("standard::name,standard::content-type", GLib.FileQueryInfoFlags.NONE);
        var dest_dir = GLib.File.new_for_path (Dirs.config ("image-favorites"));

        // Explicitly check whether the destination file already exists, and rename
        // it if it does */
        var dest_file = dest_dir.get_child (file_info.get_name ());
        if (GLib.FileUtils.test (dest_file.get_path (), GLib.FileTest.EXISTS)) {
          debug ("File '%s' already exists", dest_file.get_path ());
          dest_file = dest_dir.get_child ("%s_%s".printf (GLib.get_monotonic_time ().to_string (),
                                                          file_info.get_name ()));
          debug ("New name: '%s'", dest_file.get_path ());
        }

        file.copy (dest_file, GLib.FileCopyFlags.NONE);

        var row = new FavImageRow (dest_file.get_path ());
        if (file_info.get_content_type () == "image/gif") {
          row.is_gif = true;
          row.set_sensitive (gifs_enabled);
        }

        row.show ();
        fav_image_list.add (row);

      } catch (GLib.Error e) {
        warning (e.message);
      }
    }
  }

  public void set_gifs_enabled (bool enabled) {
    if (enabled == this.gifs_enabled)
      return;

    this.gifs_enabled = enabled;

    foreach (Gtk.Widget w in fav_image_list.get_children ()) {
      var child = (FavImageRow)w;

      if (child.get_image_path ().down ().has_suffix (".gif")) {
        child.set_sensitive (this.gifs_enabled);
      }
    }
  }
}
