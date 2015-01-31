




void all () {

  var history = new BundleHistory (5);
  history.push (1, null);
  history.push (2, null);
  history.push (3, null);
  history.push (4, null);
  history.push (5, null);
  assert (history.current == 5);

  history.back ();
  assert (history.current == 4);

  history.back ();
  assert (history.current == 3);

  history.forward ();
  assert (history.current == 4);

  history.push (10, null);
  assert (history.current == 10);

  history.forward ();
  assert (history.current == 10);

  history.forward ();
  assert (history.current == 10);
}



void end () {
  var history = new BundleHistory (5);
  assert (history.at_end ());

  history.push (1, null);
  assert (history.at_end ());

  history.push (2, null);
  assert (history.at_end ());

  history.back ();
  assert (!history.at_end ());

}

void equals () {
  var bundle1 = new Bundle ();
  bundle1.put_string ("a", "1");
  bundle1.put_string ("b", "3");

  var bundle2 = new Bundle ();
  bundle2.put_string ("b", "3");
  bundle2.put_string ("a", "1");

  assert (bundle1.equals (bundle2));
  assert (!bundle1.equals (null));

  var bundle3 = new Bundle ();
  assert (!bundle3.equals (bundle1));
}


int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/bundlehistory/all", all);
  GLib.Test.add_func ("/bundlehistory/end", end);
  GLib.Test.add_func ("/bundlehistory/equals", equals);
  return GLib.Test.run ();
}
