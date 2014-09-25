void main (string[] args) {
  Gtk.init (ref args);


  var d = new ImageCropDialog ();
  d.show ();


  Gtk.main ();
}
