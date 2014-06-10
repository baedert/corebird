


void main (string[] args) {
  Gtk.init (ref args);
  var window = new Gtk.Window ();
  var widget = new MultiMediaWidget (3);
  var m1 = new Gdk.Pixbuf.from_file ("examples/media1.jpg");
  var m2 = new Gdk.Pixbuf.from_file ("examples/media2.jpg");
  var m3 = new Gdk.Pixbuf.from_file ("examples/media3.jpg");

  widget.set_media (0, m1);
  widget.set_media (1, m2);
  widget.set_media (2, m3);

  window.add (widget);
  window.resize (500, 500);
  window.show_all ();
  Gtk.main ();
}
