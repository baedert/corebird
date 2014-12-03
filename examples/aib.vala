



void main (string[] args) {
  Gtk.init (ref args);

  /* Load CSS */
  var provider = new Gtk.CssProvider ();
  try {
    provider.load_from_path ("/usr/share/corebird/ui/style.css");
  } catch (GLib.Error e) {
    error (e.message);
  }
  Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (),
                                            provider,
                                            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

  var window = new Gtk.Window ();

  var aib = new AddImageButton ();
  aib.clicked.connect (() => {
    Gdk.Pixbuf? pixbuf = null;
    try {
      pixbuf = new Gdk.Pixbuf.from_file ("examples/media1.jpg");
    } catch (GLib.Error e) {
      error (e.message);
    }

    int width = 500;
    var thumb = Utils.slice_pixbuf (pixbuf, width, MultiMediaWidget.HEIGHT);
    aib.image = thumb;

  });

  window.add (aib);
  window.resize (500, 50);
  window.show_all ();
  Gtk.main ();
}
