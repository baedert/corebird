


void test_tweet () {

assert(false);
}

int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/general/tweets", test_tweet);



  return GLib.Test.run ();
}
