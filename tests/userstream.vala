



void main () {
  GLib.MainLoop loop  = new GLib.MainLoop ();
  UserStream stream   = new UserStream ("baedert");
  stream.token        = "118055879-Uct8UjTQmtIPNZwEFE9tgMPV7YUdaEWkVbL88D8p";
  stream.token_secret = "3ncxak11QEUbSKqLylk1lRU4AdmYAoTROk42n0Gmlak";

  stream.start ();




  loop.run ();
}
