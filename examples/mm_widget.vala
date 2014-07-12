


void main (string[] args) {
  Gtk.init (ref args);
  var window = new Gtk.Window ();
  var widget = new MultiMediaWidget (3);


  //try {
    //var m1 = new Media ();
    //m1.path = "examples/media1.jpg";
    //m1.loaded = true;
    //m1.thumbnail = new Gdk.Pixbuf.from_file ("examples/media1.jpg");
    //widget.set_media (0, m1);

    //var m2 = new Media ();
    //m2.path = "examples/media2.jpg";
    //m2.loaded = true;
    //m2.thumbnail = new Gdk.Pixbuf.from_file ("examples/media2.jpg");
    //widget.set_media (1, m2);

    //var m3 = new Media ();
    //m3.path = "examples/media3.jpg";
    //m3.loaded = true;
    //m3.thumbnail = new Gdk.Pixbuf.from_file ("examples/media3.jpg");
    //widget.set_media (2, m3);
  //} catch (GLib.Error e) {
    //critical (e.message);
  //}

  window.add (widget);
  window.resize (500, 500);
  window.show_all ();
  Gtk.main ();
}
