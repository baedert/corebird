
void main () {
  Gtk.init ();

  var model = new Cb.ActivityModel ();

  message ("Initial model size: %u", model.get_n_items ());

  model.poll ();

  message ("Model size after first poll: %u", model.get_n_items ());
}
