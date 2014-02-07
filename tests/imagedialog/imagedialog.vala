







int main (string[] args) {
  Gtk.init (ref args);
  var window = new Gtk.Window ();

  var image_dialog = new ImageDialog (window, "./test.jpg");

  image_dialog.show_all ();
  window.show_all ();
  Gtk.main ();
  return 0;
}
