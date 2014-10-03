



void main (string[] args) {
  Gtk.init (ref args);
  var window = new Gtk.Window ();
  var list_box = new Gtk.ListBox ();
  list_box.selection_mode = Gtk.SelectionMode.NONE;

  var lle = new ListListEntry ();
  lle.name = "Test List";
  lle.description = "Some test description that is very long, much too long for the row width";
  lle.creator_screen_name = "baedert";
  lle.mode = "public";
  list_box.add (lle);


  window.add (list_box);
  window.show_all ();
  Gtk.main ();
}
