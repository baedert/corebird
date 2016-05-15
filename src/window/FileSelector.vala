/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2016 Timm Bäder
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

class FileSelector : Gtk.Window {
  private uint _max_file_size = Twitter.MAX_BYTES_PER_IMAGE;
  public uint max_file_size {
    get { return _max_file_size; }
    set { this._max_file_size = value; }
  }

  public signal void file_selected (string path, Gdk.Pixbuf? image);
  private Gdk.Pixbuf? image = null;

  private Gtk.FileChooserWidget file_chooser;
  private Gtk.Box main_box;
  /* Preview Widget */
  private Gtk.Box   preview_box;
  private Gtk.Image preview_image;
  private Gtk.Label preview_label;
  /* Select Buttons */
  private Gtk.Button select_button;
  private Gtk.Button cancel_button;

  public FileSelector () {
    this.title = _("Select Image");
    this.type_hint = Gdk.WindowTypeHint.DIALOG;
    this.file_chooser = new Gtk.FileChooserWidget (Gtk.FileChooserAction.OPEN);
    this.preview_image = new Gtk.Image ();
    this.preview_label = new Gtk.Label ("");
    preview_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
    preview_label.max_width_chars = 20;
    this.preview_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
    preview_box.valign = Gtk.Align.CENTER;
    preview_box.margin_end = 12;
    preview_box.add (preview_image);
    preview_box.add (preview_label);
    file_chooser.set_preview_widget (preview_box);

    var filter = new Gtk.FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    filter.add_mime_type ("image/gif");
    file_chooser.set_filter (filter);
    file_chooser.update_preview.connect (update_preview_cb);
    file_chooser.selection_changed.connect (selection_changed_cb);
    file_chooser.file_activated.connect (file_activated_cb);
    file_chooser.current_folder_changed.connect (folder_changed_cb);
    file_chooser.use_preview_label = false;
    file_chooser.vexpand = true;


    this.main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
    main_box.add (file_chooser);

    var button_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
    this.select_button = new Gtk.Button.with_label (_("Open"));
    select_button.clicked.connect (select_clicked_cb);
    select_button.receives_default = true;
    select_button.can_default = true;
    select_button.get_style_context ().add_class ("suggested-action");
    button_size_group.add_widget (select_button);

    this.cancel_button = new Gtk.Button.with_label (_("Cancel"));
    cancel_button.clicked.connect (cancel_clicked_cb);
    button_size_group.add_widget (cancel_button);


    if (Gtk.Settings.get_default ().gtk_dialogs_use_header) {
      /* Use CSDs */
      var titlebar = new Gtk.HeaderBar ();
      titlebar.title = _("Select Image");
      titlebar.pack_start (cancel_button);
      titlebar.pack_end (select_button);
      this.set_titlebar (titlebar);
    } else {
      var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
      button_box.margin_end = 6;
      button_box.margin_bottom = 6;
      button_box.halign = Gtk.Align.END;
      cancel_button.halign = Gtk.Align.END;
      button_box.add (cancel_button);
      select_button.halign = Gtk.Align.END;
      button_box.add (select_button);
      main_box.add (button_box);
    }

    this.add (main_box);

    /* select_button needs to be anchored */
    select_button.grab_default ();

    /* gtkfilechooserdialog.c chooses 600px width here, but we need
       to account for the width of the preview image */
    this.set_default_size (800, 400);
  }

  private void selection_changed_cb () {
    string? uri = file_chooser.get_uri ();
    if (uri == null)
      return;

    GLib.File file = GLib.File.new_for_uri (uri);
    GLib.FileInfo info;
    try {
      info = file.query_info (GLib.FileAttribute.STANDARD_TYPE + "," +
                              GLib.FileAttribute.STANDARD_SIZE, 0);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }
    if (info.get_file_type () == GLib.FileType.REGULAR) {
      int64 size = info.get_size ();
      select_button.sensitive = size < this._max_file_size;
    } else {
      select_button.sensitive = true;
    }
  }

  /* TODO: Make this async; the current impl sucks with bigger images. */
  private void update_preview_cb () {
    string? uri = file_chooser.get_uri ();
    if (uri == null)
      return;

    GLib.File file = GLib.File.new_for_uri (uri);
    GLib.FileInfo info;
    try {
      info = file.query_info (GLib.FileAttribute.STANDARD_TYPE + "," +
                              GLib.FileAttribute.STANDARD_SIZE, 0);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }

    if (info.get_size () > this._max_file_size) {
      preview_image.clear ();
      preview_image.hide ();
      preview_label.label = _("Max file size exceeded\n(3MB)");
      preview_label.justify = Gtk.Justification.CENTER;
      preview_box.show_all ();
      return;
    }

    if (uri.has_prefix ("file://")) {
      preview_label.label = file.get_basename ();
      try {
        int final_size = 130;
        var p = new Gdk.Pixbuf.from_file (file.get_path ());
        int w = p.get_width ();
        int h = p.get_height ();
        if (w > h) {
          double ratio = final_size / (double) w;
          w = final_size;
          h = (int)(h * ratio);
        } else {
          double ratio = final_size / (double) h;
          w = (int)(w * ratio);
          h = final_size;
        }
        this.image = p;
        var scaled = p.scale_simple (w, h, Gdk.InterpType.BILINEAR);
        preview_image.set_from_pixbuf (scaled);
        preview_box.show_all ();
      } catch (GLib.Error e) {
        preview_box.hide ();
      }
    } else {
      preview_box.hide ();
    }
  }

  private void folder_changed_cb () {
    string? uri = file_chooser.get_uri ();
    if (uri == null) {
      preview_box.hide ();
      select_button.sensitive = false;
    }
  }

  private void cancel_clicked_cb () {
    this.close ();
  }

  private void select_clicked_cb () {
    this.choose_file ();
  }

  private void file_activated_cb () {
    this.choose_file ();
  }

  private void choose_file () {
    string? uri = file_chooser.get_uri ();
    if (uri == null)
      return;

    GLib.File file = GLib.File.new_for_uri (uri);
    GLib.FileInfo info;
    try {
      info = file.query_info (GLib.FileAttribute.STANDARD_TYPE + "," +
                              GLib.FileAttribute.STANDARD_SIZE, 0);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }

    /* Via double-click, we can still end up here with a file that is too large */
    if (info.get_size () > this._max_file_size) {
      return;
    }

    if (info.get_file_type () == GLib.FileType.DIRECTORY) {
      /* Go into the directory */
      file_chooser.set_current_folder (file.get_path ());
    } else if (info.get_file_type () == GLib.FileType.REGULAR) {
      this.file_selected (file.get_path (), this.image);
    }
  }
}
