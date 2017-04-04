
void simple () {
  var text = "abc";
  var length = Cb.TweetCounter.count_chars (text);

  assert (length == 3);
}

void simple_utf8 () {
  var text = "¥¥²³¤";
  var length = Cb.TweetCounter.count_chars (text);

  assert (length == 5);
}

int main (string[] args) {
  GLib.Test.init (ref args);

  GLib.Test.add_func ("/tweetcounter/simple", simple);
  GLib.Test.add_func ("/tweetcounter/simple-utf8", simple_utf8);

  return GLib.Test.run ();
}
