




void all () {

  var history = new BundleHistory (5);
  history.push (1);
  history.push (2);
  history.push (3);
  history.push (4);
  history.push (5);
  assert (history.current == 5);

  history.back ();
  assert (history.current == 4);

  history.back ();
  assert (history.current == 3);

  history.forward ();
  assert (history.current == 4);

  history.push (10);
  assert (history.current == 10);

  history.forward ();
  assert (history.current == 10);

  history.forward ();
  assert (history.current == 10);
}





int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/bundlehistory/all", all);
  return GLib.Test.run ();
}
