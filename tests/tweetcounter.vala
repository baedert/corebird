
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

void trailing_whitespace () {
  assert (Cb.TweetCounter.count_chars ("a    ") == 5);
}

void leading_whitespace () {
  assert (Cb.TweetCounter.count_chars ("    a") == 5);
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
  var length = Cb.TweetCounter.count_chars (text);

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

void not_a_link () {
  var text = "https://foobar.c";
  var length = Cb.TweetCounter.count_chars (text);

  message ("Text length: %d", length);
  assert (length == 16);
}

void link_parens () {
  // A link and a paren
  assert (Cb.TweetCounter.count_chars ("https://foobar.com)") == Twitter.short_url_length + 1);

  // A link and 2 parens
  assert (Cb.TweetCounter.count_chars ("http://foobar.com()") == Twitter.short_url_length + 2);

  // A link, a hash and some text
  assert (Cb.TweetCounter.count_chars ("http://foobar.com#anchor") == Twitter.short_url_length + 7);

  // A link and a chunk of text at the end
  assert (Cb.TweetCounter.count_chars ("http://foobar.com(bla)") == Twitter.short_url_length + 5);

  // Just a link. Yes, really.
  assert (Cb.TweetCounter.count_chars ("http://foobar.com/bla(bla)") == Twitter.short_url_length);

  // Also a link and nothing more
  assert (Cb.TweetCounter.count_chars ("http://foobar.com/(bla)") == Twitter.short_url_length);

  // Link and a paren
  assert (Cb.TweetCounter.count_chars ("https://foobar.com/bla)") == Twitter.short_url_length + 1);

  // Parens even nest
  assert (Cb.TweetCounter.count_chars ("https://foobar.com/bla((bla))") == Twitter.short_url_length);

  // Parens have to match, otherwise the entire chunk at the end is ignored
  assert (Cb.TweetCounter.count_chars ("https://foobar.com/bla((bla)") == Twitter.short_url_length + 6);

  assert (Cb.TweetCounter.count_chars ("https://foobar.com/bla)a(bla)") == Twitter.short_url_length + 7);
}

void link_subdomain_tlds () {
  assert (Cb.TweetCounter.count_chars ("https://foobar.com.c") == 25);
}

void not_a_link2 () {
  message ("Length: %d", Cb.TweetCounter.count_chars ("https:/foobar.com.c"));
  assert (Cb.TweetCounter.count_chars ("https:/foobar.com.c") == 19);
}

void empty_link () {
  assert (Cb.TweetCounter.count_chars ("https://") == 8);
}

void no_tld () {
  assert (Cb.TweetCounter.count_chars ("https://a") == 9);
}

void plus () {
  assert (Cb.TweetCounter.count_chars ("https://google.com/+") == Twitter.short_url_length);
}

void port () {
  assert (Cb.TweetCounter.count_chars ("https://google.com:1337/+") == Twitter.short_url_length);
}

void wrong_unicode_links () {
  assert (Cb.TweetCounter.count_chars ("https://google.com/€") == Twitter.short_url_length + 1);
}


//void link_tld () {
  //message ("-----------------------------------------------------------------");
  //var text = "google.com";
  //var length = Cb.TweetCounter.count_chars (text);

  //assert (length == Twitter.short_url_length);
//}

int main (string[] args) {
  GLib.Test.init (ref args);

  GLib.Test.add_func ("/tweetcounter/simple", simple);
  GLib.Test.add_func ("/tweetcounter/empty", empty);
  GLib.Test.add_func ("/tweetcounter/splits-only", splits_only);
  GLib.Test.add_func ("/tweetcounter/trailing-whitespace", trailing_whitespace);
  GLib.Test.add_func ("/tweetcounter/leading-whitespace", leading_whitespace);
  GLib.Test.add_func ("/tweetcounter/simple-utf8", simple_utf8);

  GLib.Test.add_func ("/tweetcounter/simple-http", simple_http);
  GLib.Test.add_func ("/tweetcounter/link-parens", link_parens);
  GLib.Test.add_func ("/tweetcounter/link-subdomain-tlds", link_subdomain_tlds);
  GLib.Test.add_func ("/tweetcounter/simple-https", simple_https);
  GLib.Test.add_func ("/tweetcounter/link-punctuation", link_punctuation);
  GLib.Test.add_func ("/tweetcounter/link-punctuation2", link_punctuation2);
  GLib.Test.add_func ("/tweetcounter/wikipedia-link", wikipedia_link);

  GLib.Test.add_func ("/tweetcounter/not-a-link", not_a_link);
  GLib.Test.add_func ("/tweetcounter/not-a-link2", not_a_link2);
  GLib.Test.add_func ("/tweetcounter/empty-link", empty_link);
  GLib.Test.add_func ("/tweetcounter/no-tld", no_tld);
  GLib.Test.add_func ("/tweetcounter/plus", plus);
  GLib.Test.add_func ("/tweetcounter/port", port);
  GLib.Test.add_func ("/tweetcounter/wrong-unicode-links", wrong_unicode_links);

  //GLib.Test.add_func ("/tweetcounter/link-tld", link_tld);

  return GLib.Test.run ();
}
