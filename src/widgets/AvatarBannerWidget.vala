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

public class AvatarBannerWidget : Gtk.Container {
  private static const int MAX_HEIGHT = 250;
  private static const double BANNER_RATIO = 0.5; /* 320/640 */
  public int avatar_size { get; set; default = 48; }

  private unowned Account account;

  private PixbufButton set_banner_button;
  private PixbufButton set_avatar_button;

  public signal void avatar_changed (Gdk.Pixbuf new_avatar);
  public signal void banner_changed (Gdk.Pixbuf new_banner);

  construct {
    this.set_has_window (false);
    get_style_context ().add_class ("avatar");

    /* set_banner_button */
    this.set_banner_button = new PixbufButton ();
    set_banner_button.show_all ();
    set_banner_button.clicked.connect (banner_clicked_cb);
    this.add (set_banner_button);

    /* set_avatar_button */
    this.set_avatar_button = new PixbufButton ();
    set_avatar_button.show_all ();
    set_avatar_button.clicked.connect (avatar_clicked_cb);
    this.add (set_avatar_button);
    Settings.get ().bind ("round-avatars", set_avatar_button, "round",
                          GLib.SettingsBindFlags.DEFAULT);

  }

  public void set_account (Account account) {
    this.account = account;
    load_banner.begin ();
    this.queue_draw ();
    set_avatar_button.set_bg ((Cairo.ImageSurface)account.avatar);
  }

  private async void load_banner () {
    string banner_name = Utils.get_banner_name (account.id);
    string banner_path = Dirs.cache ("assets/banners/" + banner_name);
    /* Try to load the banner */
    try {
      var stream = GLib.File.new_for_path (banner_path).read ();
      set_banner_button.set_pixbuf (yield new Gdk.Pixbuf.from_stream_async (stream, null));
      stream.close();
    } catch (GLib.Error e) {
      if (e is GLib.IOError.NOT_FOUND) {
        /* Banner does not exist locally so we need to fetch it */
        yield fetch_banner (banner_path);
      } else {
        warning (e.message);
      }
    }
  }

  public override bool draw (Cairo.Context ct) {
    this.propagate_draw (set_banner_button, ct);
    this.propagate_draw (set_avatar_button, ct);
    return true;
  }

  private int get_avatar_x () {
    return (get_allocated_width () / 2) - (avatar_size / 2);
  }

  private int get_avatar_y () {
    return get_allocated_height () - avatar_size;
  }


  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void get_preferred_width (out int min,
                                            out int nat) {
    min = avatar_size + 40; // 20px margin on either side
    nat = min;
  }

  public override void get_preferred_height_for_width (int width,
                                                       out int min,
                                                       out int nat) {
    min = nat = int.min (MAX_HEIGHT, (int)(width * BANNER_RATIO) + (avatar_size / 3));
  }

  private async void fetch_banner (string banner_path) {
    if (account.banner_url == null) {
      set_banner_button.set_pixbuf (Twitter.no_banner);
      return;
    }

    yield Utils.download_file_async (account.banner_url, banner_path);
    try {
      this.set_banner_button.set_pixbuf (new Gdk.Pixbuf.from_file (banner_path));
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }

  public override void size_allocate (Gtk.Allocation allocation) {
    base.size_allocate  (allocation);

    Gtk.Requisition child_requisition;
    Gtk.Allocation child_allocation = Gtk.Allocation();

    /* set_banner_button */
    set_banner_button.get_preferred_size (out child_requisition, null);
    child_allocation.x = allocation.x;
    child_allocation.y = allocation.y;
    child_allocation.width = allocation.width;
    child_allocation.height = (int)(allocation.width * BANNER_RATIO);
    set_banner_button.size_allocate (child_allocation);


    /* set_avatar_button */
    set_avatar_button.get_preferred_size (out child_requisition, null);
    child_allocation.x = get_avatar_x () + allocation.x;
    child_allocation.y = get_avatar_y () + allocation.y;
    child_allocation.width = avatar_size;
    child_allocation.height = avatar_size;
    set_avatar_button.size_allocate (child_allocation);
  }

  public override void add (Gtk.Widget w) {
    w.set_parent (this);
  }

  public override void remove (Gtk.Widget w) {
    w.unparent ();
  }

  public override void forall_internal (bool include_internals, Gtk.Callback cb) {
    cb (set_banner_button);
    cb (set_avatar_button);
  }

  private void banner_clicked_cb () {
    ImageCropDialog dialog = new ImageCropDialog (2.0);
    dialog.set_title (_("Select banner"));
    dialog.set_min_size (200);
    dialog.set_modal (true);
    dialog.min_width = 200;
    dialog.min_height = 100;
    dialog.set_transient_for ((Gtk.Window)this.get_toplevel ());
    dialog.image_cropped.connect ((img) => {
      set_banner_button.set_pixbuf (img);
      banner_changed (img);
    });
    dialog.show_all ();
  }

  private void avatar_clicked_cb () {
    ImageCropDialog dialog = new ImageCropDialog (1.0);
    dialog.set_title (_("Select avatar"));
    dialog.set_modal (true);
    dialog.set_transient_for ((Gtk.Window)this.get_toplevel ());
    dialog.image_cropped.connect ((img) => {
      set_avatar_button.set_pixbuf (img);
      avatar_changed (img);
    });
    dialog.show_all ();
  }
}
