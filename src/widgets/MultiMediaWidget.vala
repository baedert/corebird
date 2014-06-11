




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

  public void set_media (int index, Media media) {
    assert (index < media_count);
    medias[index] = media.thumbnail;
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

    //ct.save ();
    //ct.set_source_rgb (1, 0, 0);
    //ct.rectangle (10, 10, widget_width - 20, widget_height - 20);
    //ct.fill ();
    //ct.restore ();

    //ct.save ();
    //ct.set_source_rgb (0, 0, 0);
    //ct.move_to (widget_width / 2.0f, 0);
    //ct.line_to (widget_width / 2.0f, widget_height);
    //ct.stroke();
    //ct.restore();


    float media_width = (float)widget_width / media_count;

    //double media_x = 0;
    for (int i = 0; i < media_count; i ++) {
      double scale = (double)media_width / medias[i].get_width ();
      ct.save ();
      ct.translate (media_width * i, 0);
      ct.rectangle (0, 0, media_width, widget_height);
      ct.scale (scale, 1);
      //if (i > 0)
      Gdk.cairo_set_source_pixbuf (ct, medias[i],0, 0);

      ct.fill ();
      ct.restore ();
      //media_x += medias[i].get_width ();
    }
    return true;
  }

  /* }}} */


}
