
void simple () {
  var text = "abc";
  var length = Cb.TweetCounter.count_chars (text);

  message ("Length: %d", length);
  assert (length == 3);
}

void simple_utf8 () {
  var text = "¥¥²³¤";
  var length = Cb.TweetCounter.count_chars (text);

  assert (length == 5);
}

void simple_http () {
  var text = "http://verylongdomainthisisneversoshort.com";
  var length = Cb.TweetCounter.count_chars (text);

  assert (length == Twitter.short_url_length);
}

int main (string[] args) {
  GLib.Test.init (ref args);

  GLib.Test.add_func ("/tweetcounter/simple", simple);
  GLib.Test.add_func ("/tweetcounter/simple-utf8", simple_utf8);
  GLib.Test.add_func ("/tweetcounter/simple-http", simple_http);

  return GLib.Test.run ();
}
