




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
  var bundle1 = new Cb.Bundle ();
  bundle1.put_string (0, "1");
  bundle1.put_string (1, "3");

  var bundle2 = new Cb.Bundle ();
  bundle2.put_string (1, "3");
  bundle2.put_string (0, "1");

  assert (bundle1.equals (bundle2));
  assert (!bundle1.equals (null));

  var bundle3 = new Cb.Bundle ();
  assert (!bundle3.equals (bundle1));
}

void remove_current () {
  var history = new BundleHistory (5);

  var bundle1 = new Cb.Bundle ();
  bundle1.put_string (0, "a");
  bundle1.put_string (1, "b");
  history.push (1, bundle1);

  var bundle2 = new Cb.Bundle ();
  bundle2.put_string (3, "c");
  bundle2.put_string (4, "d");
  history.push (2, bundle2);

  // push advances
  assert (history.at_end());
  assert (history.current_bundle == bundle2);
  assert (history.current == 2);


  // remove_current deletes the current bundle but doesn't
  // to back
  history.remove_current ();
  assert (history.current_bundle == null);
  assert (history.current == -1);

  // This should bring us to bundle1
  history.back ();
  assert (history.current_bundle == bundle1);
  assert (history.current == 1);


  history.remove_current ();
  assert (history.current_bundle == null);
  assert (history.current == -1);

  history.back ();
  assert (history.at_start ());

  // Shouldn't do anything significant even if at_start() == true
  history.remove_current ();
  history.remove_current ();


  // Empty!
  assert (history.at_end ());
  assert (history.at_start ());

  var bundle3 = new Cb.Bundle ();
  bundle3.put_string (0, "_");
  var bundle4 = new Cb.Bundle ();
  bundle4.put_string (7, "__");
  var bundle5 = new Cb.Bundle ();
  bundle5.put_string (10, "___");

  history.push (3, bundle3);
  history.push (4, bundle4);
  history.push (5, bundle5);

  assert (history.current == 5);
  history.back ();
  assert (history.current == 4);

  history.remove_current ();
  assert (history.current == 5); // everything after 4 was moved one to the front
  assert (history.current_bundle == bundle5);
  assert (history.at_end ());

}

int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/bundlehistory/all", all);
  GLib.Test.add_func ("/bundlehistory/end", end);
  GLib.Test.add_func ("/bundlehistory/equals", equals);
  GLib.Test.add_func ("/bundlehistory/remove-current", remove_current);

  return GLib.Test.run ();
}
