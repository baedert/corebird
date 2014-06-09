




public class MultiMediaWidget : Gtk.Widget {
  private static const int HEIGHT = 150;
  public int media_count { public get; private set; default = 0;}
  private Gdk.Pixbuf[] medias;


  public MultiMediaWidget (int media_count) {
    this.media_count = media_count;
    this.medias = new Gdk.Pixbuf[media_count];
  }
  construct {
    set_has_window (false);
  }

  public void set_media (int index, Gdk.Pixbuf pixbuf) {
    assert (index < media_count);
    medias[index] = pixbuf;
  }

  /* Widget Implementation {{{ */
  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void get_preferred_height_for_width (int width,
                                                   out int min_height,
                                                   out int nat_height) {
    min_height = HEIGHT;
    nat_height = HEIGHT;
  }

  public override void get_preferred_width (out int min_width,
                                            out int nat_width) {
    min_width = media_count * 30;
    nat_width = media_count * 30;
  }

  public override bool draw (Cairo.Context ct) {
    int widget_width = get_allocated_width ();
    int widget_height = get_allocated_height ();

    ct.set_source_rgb (1, 0, 0);
    ct.rectangle (0, 0, widget_width, widget_height);
    ct.fill ();


    float media_width = (float)widget_width / media_count;

    double media_x = 0;
    for (int i = 0; i < media_count; i ++) {
      double scale = (double)media_width / medias[i].get_width ();
      ct.save ();
      ct.rectangle (media_x * scale, 0, medias[i].get_width (), medias[i].get_height ());
      ct.scale (scale, 1);
      Gdk.cairo_set_source_pixbuf (ct, medias[i], media_x, 0);
      ct.fill ();
      ct.restore ();
      media_x += medias[i].get_width ();
    }
    return true;
  }

  /* }}} */


}
