



int main (string[] args) {
  GLib.Test.init (ref args);

  GLib.Environ.set_variable (null, "GSETTINGS_BACKEND", "memory", true);


  //GLib.Test.add_func ("/tweet-length/http-link", http_link);
  return GLib.Test.run ();
}


// Tweet data {{{

const string TWEET1_DATA = """




""";



// }}}
