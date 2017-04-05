
void simple () {
  var text = "abc";
  var length = Cb.TweetCounter.count_chars (text);

  assert (length == 3);
}

void empty () {
  assert (Cb.TweetCounter.count_chars ("") == 0);
}

void splits_only () {
  assert (Cb.TweetCounter.count_chars ("... / ... {}") == 3 + 1 + 1 + 1 + 3 + 1 + 2);
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

void simple_https () {
  var text = "https://verylongdomainthisisneversoshort.com";
  var length = Cb.TweetCounter.count_chars (text);

  assert (length == Twitter.short_url_length);
}

void link_punctuation () {
  var text = "foobar(http://abc.com)";
  var length = TweetUtils.calc_tweet_length (text);

  assert (length == 6 + 1 + Twitter.short_url_length + 1);
}

void link_punctuation2 () {
  var text = "...http://foobar.com";
  var length = Cb.TweetCounter.count_chars (text);

  message ("Length: %d", length);
  assert (length == 3 + Twitter.short_url_length);
}

void wikipedia_link () {
  var text = "https://en.wikipedia.org/wiki/Glob_(programming)#DOS_COMMAND.COM_and_Windows_cmd.exe";
  var length = Cb.TweetCounter.count_chars (text);

  assert (length == Twitter.short_url_length);
}


int main (string[] args) {
  GLib.Test.init (ref args);

  GLib.Test.add_func ("/tweetcounter/simple", simple);
  GLib.Test.add_func ("/tweetcounter/empty", empty);
  GLib.Test.add_func ("/tweetcounter/splits-only", splits_only);
  GLib.Test.add_func ("/tweetcounter/simple-utf8", simple_utf8);
  GLib.Test.add_func ("/tweetcounter/simple-http", simple_http);
  GLib.Test.add_func ("/tweetcounter/simple-https", simple_https);
  GLib.Test.add_func ("/tweetcounter/link-punctuation", link_punctuation);
  GLib.Test.add_func ("/tweetcounter/link-punctuation2", link_punctuation2);
  GLib.Test.add_func ("/tweetcounter/wikipedia-link", wikipedia_link);

  return GLib.Test.run ();
}
