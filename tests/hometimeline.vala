




void favorite () {
  var timeline = new HomeTimeline (0);
  timeline.on_join (0);
}




int main (string[] args) {
  GLib.Test.init (ref args);
  Gtk.init (ref args);
  GLib.Environ.set_variable (null, "GSETTINGS_BACKEND", "memory", true);


  GLib.Test.add_func ("/hometimeline/fav", favorite);
  return GLib.Test.run ();
}


// Tweet data {{{

const string TWEET1_DATA = """




""";



// }}}
