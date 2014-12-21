



void main (string[] args) {
  Gtk.init (ref args);

  Utils.load_custom_css ();
  var window = new Gtk.Window ();

  var aib = new AddImageButton ();
  aib.add_clicked.connect (() => {
    Gdk.Pixbuf? pixbuf = null;
    try {
      pixbuf = new Gdk.Pixbuf.from_file ("examples/media1.jpg");
    } catch (GLib.Error e) {
      error (e.message);
    }

    int width = 500;
    var thumb = Utils.slice_pixbuf (pixbuf, width, MultiMediaWidget.HEIGHT);
    aib.image = thumb;
    aib.start_progress ();
    GLib.Timeout.add (1500, () => {
      aib.set_error ("Image could not be uploaded: foobar bla bla bla bla bla bla bla bla bla");
      return false;
    });
  });

  aib.remove_clicked.connect (() => {
    aib.image = null;
  });

  window.add (aib);
  window.resize (500, 50);
  window.show_all ();
  Gtk.main ();
}
