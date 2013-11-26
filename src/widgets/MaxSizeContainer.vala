






class MaxSizeContainer : Gtk.Bin {
  public int max_size { get; set; default = 0; }

  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void get_preferred_height_for_width (int width,
                                                       out int min_height,
                                                       out int nat_height) {
    int child_height;
    get_child ().get_preferred_height_for_width (width, out child_height, null);


    if (max_size >= child_height) {
      base.get_preferred_height_for_width (width, out min_height, out nat_height);
    } else {
      nat_height = max_size;
      min_height = max_size;
    }

    message ("Min: %d, Nat: %d", min_height, nat_height);
  }

  public override void size_allocate (Gtk.Allocation alloc) {
    if (get_child () == null || !get_child ().visible)
      return;


    Gtk.Allocation child_alloc = {};
    child_alloc.x = alloc.x;
    child_alloc.width = alloc.width;

    if (max_size >= alloc.height) {
      // We don't cut away anything
      child_alloc.y = alloc.y;
      child_alloc.height = alloc.height;
    } else {
      child_alloc.y = alloc.y;// - (max_size - alloc.height);
      child_alloc.height = max_size;
    }

//    message ("x: %d, y: %d, w: %d, h: %d\n--------------",
//             child_alloc.x, child_alloc.y, child_alloc.width, child_alloc.height);

    base.size_allocate (child_alloc);
    if (get_child () != null && get_child ().visible) {
      get_child ().size_allocate (child_alloc);
      if (this.get_realized ())
        get_child ().show ();
    }

    if (this.get_realized ()) {
      if (get_child () != null)
        get_child ().set_child_visible (true);
    }
  }
}
