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

class ComposeImageManager : Gtk.Container {
  private static const int BUTTON_DELTA = 10;
  private static const int BUTTON_SPACING = 12;
  private Gee.ArrayList<AddImageButton> buttons;
  private Gee.ArrayList<Gtk.Button>      close_buttons;

  public int n_images {
    get {
      return this.buttons.size;
    }
  }

  public signal void image_removed ();

  construct {
    this.buttons = new Gee.ArrayList<AddImageButton> ();
    this.close_buttons = new Gee.ArrayList<Gtk.Button> ();
    this.set_has_window (false);
  }

  private void remove_clicked_cb (Gtk.Button source) {
    int index = this.close_buttons.index_of (source);
    assert (index >= 0);

    this.close_buttons.get (index).hide ();


    AddImageButton aib = (AddImageButton) this.buttons.get (index);
    aib.deleted.connect (() => {
      this.buttons.remove_at (index);
      this.close_buttons.remove_at (index);
      this.image_removed ();
      this.queue_draw ();
    });

    aib.start_remove ();
  }

  // GtkContainer API {{{
  public override void forall_internal (bool include_internals, Gtk.Callback cb) {
    assert (buttons.size == close_buttons.size);
    for (int i = 0; i < this.buttons.size;) {
      int size_before = this.buttons.size;
      cb (buttons.get (i));
      cb (close_buttons.get (i));

      i += this.buttons.size - size_before + 1;
    }
  }

  public override void add (Gtk.Widget widget) {
    widget.set_parent (this);
    widget.set_parent_window (this.get_window ());
    this.buttons.add ((AddImageButton)widget);
    var btn = new Gtk.Button.from_icon_name ("window-close-symbolic");
    btn.set_parent (this);
    btn.get_style_context ().add_class ("image-button");
    btn.get_style_context ().add_class ("close-button");
    btn.clicked.connect (remove_clicked_cb);
    btn.show ();
    this.close_buttons.add (btn);
  }

  public override void remove (Gtk.Widget widget) {
    widget.unparent ();
    if (widget is AddImageButton)
      this.buttons.remove ((AddImageButton)widget);
    else
      this.close_buttons.remove ((Gtk.Button)widget);
  }
  // }}}

  // GtkWidget API {{{
  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void size_allocate (Gtk.Allocation allocation) {
    base.size_allocate (allocation);
    Gtk.Allocation child_allocation = {};

    if (this.buttons.size == 0) return;


    int default_button_width = (allocation.width - (buttons.size * BUTTON_SPACING)) /
                               buttons.size;

    child_allocation.x = allocation.x;
    child_allocation.y = allocation.y + BUTTON_DELTA;
    child_allocation.height = int.max (allocation.height - BUTTON_DELTA, 0);

    Gtk.Allocation close_allocation = {};
    close_allocation.y = allocation.y;
    for (int i = 0, p = this.buttons.size; i < p; i ++) {
      int min, nat;

      AddImageButton aib = this.buttons.get (i);
      aib.get_preferred_width_for_height (child_allocation.height, out min, out nat);

      child_allocation.width = int.min (default_button_width, nat);
      aib.size_allocate (child_allocation);


      int n;
      Gtk.Widget btn = this.close_buttons.get (i);
      btn.get_preferred_width (out close_allocation.width, out n);
      btn.get_preferred_height (out close_allocation.height, out n);
      close_allocation.x = child_allocation.x + child_allocation.width
                           - close_allocation.width + BUTTON_DELTA;

      btn.size_allocate (close_allocation);

      child_allocation.x += child_allocation.width + BUTTON_SPACING;
    }
  }

  public override void get_preferred_height_for_width (int     width,
                                                       out int minimum,
                                                       out int natural) {
    int min = 0;
    int nat = 0;
    foreach (var btn in this.buttons) {
      int m, n;
      btn.get_preferred_height_for_width (width, out m, out n);
      min = int.max (m, min);
      nat = int.max (n, nat);
    }

    minimum = min;
    natural = nat;
  }

  public override void get_preferred_width (out int minimum,
                                            out int natural) {
    int min = 0;
    int nat = 0;
    foreach (var btn in this.buttons) {
      int m, n;
      btn.get_preferred_width (out m, out n);
      min += m;
      nat += n;
    }

    minimum = min + (buttons.size * BUTTON_SPACING);
    natural = nat + (buttons.size * BUTTON_SPACING);
  }

  public override bool draw (Cairo.Context ct) {
    for (int i = 0, p = this.buttons.size; i < p; i ++) {
      Gtk.Widget btn = this.buttons.get (i);
      this.propagate_draw (btn, ct);
    }

    for (int i = 0, p = this.close_buttons.size; i < p; i ++) {
      var btn = this.close_buttons.get (i);
      this.propagate_draw (btn, ct);
    }

    return Gdk.EVENT_PROPAGATE;
  }
  // }}}

  public void load_image (string path, Gdk.Pixbuf? image) {
    Cairo.ImageSurface surface;
    if (image == null)
      surface = (Cairo.ImageSurface) load_surface (path);
    else
      surface = (Cairo.ImageSurface) Gdk.cairo_surface_create_from_pixbuf (image,
                                                                           this.get_scale_factor (),
                                                                           this.get_window ());

    var button = new AddImageButton ();
    button.surface = surface;
    button.image_path = path;

    button.hexpand = false;
    button.halign = Gtk.Align.START;
    button.show ();
    this.add (button);
  }

  public string[] get_image_paths () {
    var paths = new string[this.buttons.size];

    int i = 0;
    foreach (var btn in this.buttons) {
      paths[i] = btn.image_path;
      i ++;
    }

    return paths;
  }

  public void start_progress (string image_path) {
    foreach (var btn in this.buttons) {
      if (btn.image_path == image_path) {
        btn.get_style_context ().add_class ("image-progress");
        break;
      }
    }
  }

  public void end_progress (string image_path, string? error_message) {
    foreach (var btn in this.buttons) {
      if (btn.image_path == image_path) {
        btn.get_style_context ().remove_class ("image-progress");

        if (error_message == null) {
          btn.get_style_context ().add_class ("image-success");
        } else {
          warning ("%s: %s", image_path, error_message);
          btn.get_style_context ().add_class ("image-error");
        }
        break;
      }
    }
  }
}
