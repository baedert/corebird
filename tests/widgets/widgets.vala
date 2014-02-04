




int main (string[] args) {
  Gtk.init (ref args);
  var window = new Gtk.Window ();
  var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
  var missing_entry = new MissingListEntry (0);
  main_box.pack_start (missing_entry, false, false);

  var btn1 = new Gtk.Button.with_label ("resumed");
  btn1.clicked.connect (() => missing_entry.set_resumed ());
  main_box.pack_end (btn1, false, false);
  var btn2 = new Gtk.Button.with_label ("interrupted");
  btn2.clicked.connect (() => missing_entry.set_interrupted ());
  main_box.pack_end (btn2, false, false);
  var btn3 = new Gtk.Button.with_label ("loading");
  btn3.clicked.connect (() => missing_entry.set_loading ());
  main_box.pack_end (btn3, false, false);
  var btn4 = new Gtk.Button.with_label ("error");
  btn4.clicked.connect (() => missing_entry.set_error ("Sample error message"));
  main_box.pack_end (btn4, false, false);

  window.add (main_box);
  window.show_all ();
  Gtk.main ();
  return 0;
}
