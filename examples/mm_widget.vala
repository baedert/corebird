


void main (string[] args) {
  Gtk.init (ref args);
  var window = new Gtk.Window ();
  var widget = new MultiMediaWidget (2);
  var m1 = new Gdk.Pixbuf.from_file ("examples/media2.jpg");
  var m2 = new Gdk.Pixbuf.from_file ("examples/media2.jpg");

  widget.set_media (0, m1);
  widget.set_media (1, m2);

  window.add (widget);
  window.show_all ();
  Gtk.main ();
}
