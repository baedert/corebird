void main (string[] args) {
  Gtk.init (ref args);


  var d = new ImageCropDialog (1.5);
  d.show ();


  Gtk.main ();
}
