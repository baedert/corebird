




int main (string[] args) {
  Gtk.init (ref args);
  var window = new Gtk.Window ();
  var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
  var missing_entry = new MissingListEntry (0);
  main_box.pack_start (missing_entry, false, false);




  window.add (main_box);
  window.show_all ();
  Gtk.main ();
  return 0;
}
