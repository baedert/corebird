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
  private Gee.ArrayList<AddImageButton2> buttons;
  private Gee.ArrayList<Gtk.Button>      close_buttons;

  public int n_images {
    get {
      return this.buttons.size;
    }
  }

  construct {
    this.buttons = new Gee.ArrayList<AddImageButton2> ();
    this.close_buttons = new Gee.ArrayList<Gtk.Button> ();
    this.set_has_window (false);
  }

  private void remove_clicked_cb (Gtk.Button source) {
    int index = this.close_buttons.index_of (source);
    assert (index >= 0);
    message ("remove clicked");

    this.buttons.remove_at (index);
    this.close_buttons.remove_at (index);
    this.queue_draw ();
  }

  // GtkContainer API {{{
  public override void forall_internal (bool include_internals, Gtk.Callback cb) {
    assert (buttons.size == close_buttons.size);
    for (int i = 0, p = buttons.size; i < p; i ++) {
      cb (buttons.get (i));
      cb (close_buttons.get (i));
    }
  }

  public override void add (Gtk.Widget widget) {
    widget.set_parent (this);
    widget.set_parent_window (this.get_window ());
    this.buttons.add ((AddImageButton2)widget);
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
    int index = 0;
    if (widget is AddImageButton2)
      this.buttons.remove ((AddImageButton2)widget);
    else
      this.close_buttons.remove ((Gtk.Button)widget);
  }
  // }}}

  // GtkWidget API {{{
  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void size_allocate (Gtk.Allocation allocation) {
    Gtk.Allocation child_allocation = {};
    this.set_allocation (allocation);

    if (this.buttons.size == 0) return;

    child_allocation.x = allocation.x;
    child_allocation.y = allocation.y;
    child_allocation.width = allocation.width / buttons.size;
    child_allocation.height = allocation.height;

    Gtk.Allocation close_allocation = {};
    close_allocation.y = allocation.y;
    for (int i = 0, p = this.buttons.size; i < p; i ++) {
      Gtk.Widget btn = this.buttons.get (i);
      btn.size_allocate (child_allocation);

      int draw_width, draw_height;
      ((AddImageButton2)btn).get_draw_size (out draw_width, out draw_height, null);

      int m, n;
      btn = this.close_buttons.get (i);
      btn.get_preferred_width (out close_allocation.width, out n);
      btn.get_preferred_height (out close_allocation.height, out n);
      close_allocation.x = child_allocation.x + draw_width - close_allocation.width;
      btn.size_allocate (close_allocation);


      child_allocation.x += child_allocation.width;
    }
  }

  public override void get_preferred_height_for_width (int width,
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

    minimum = min;
    natural = nat;
  }

  public override bool draw (Cairo.Context ct) {
    for (int i = 0, p = this.buttons.size; i < p; i ++) {
      Gtk.Widget btn = this.buttons.get (i);
      this.propagate_draw (btn, ct);

      btn = this.close_buttons.get (i);
      this.propagate_draw (btn, ct);
    }

    return Gdk.EVENT_PROPAGATE;
  }
  // }}}

  public void load_image (string path) {
    Cairo.ImageSurface surface = (Cairo.ImageSurface) load_surface (path);

    var button = new AddImageButton2 ();
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

  }
}
