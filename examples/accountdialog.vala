


void main (string[] args) {
  Gtk.init ();

  Utils.load_custom_css ();
  Settings.init ();
  var acc = new Account (1337, "Some Screen Name", "Some Name");
  var dialog = new AccountDialog (acc);
  dialog.show ();


  Gtk.main ();
}
