
void normal () {
  string t = "ABC";
  assert (TweetUtils.calc_tweet_length (t) == 3);
}

void empty () {
  int l = TweetUtils.calc_tweet_length ("");
  message ("empty length %d", l);
  assert (l == 0);
}

void http_link () {
  string text = "http://foobar.org";
  int l = TweetUtils.calc_tweet_length (text);
  message ("Link length: %d", l);
  assert (l == Twitter.short_url_length);
}

void https_link () {
  string text = "https://foobar.org/thisissolong/itsnotevenfunnyanymore";
  int  l = TweetUtils.calc_tweet_length (text);
  message ("Https link length: %d", l);
  assert (l == Twitter.short_url_length_https);
}


void media () {
  string text = "";
  int l = TweetUtils.calc_tweet_length (text, 1);
  message ("media length: %d", l);
  assert (l == Twitter.characters_reserved_per_media);
}


void media_text () {
  string text = "0123456789 012345678";
  int l = TweetUtils.calc_tweet_length (text, 1);
  message ("media length: %d", l);
  assert (l == Twitter.characters_reserved_per_media + 20);
}



void tld1 () {
  string text = "google.com";
  int l = TweetUtils.calc_tweet_length (text);
  message ("tld1 length: %d", l);
  assert (l == Twitter.short_url_length);
}

void real_text1 () {
  string text = "That @humble Bundle we're doing? Finishes in 1:40hrs so if you still want to get 7 great fantasy games dirt cheap... humblebundle.com/weekly";
  int l = TweetUtils.calc_tweet_length (text);
  message ("real text 1 length: %d", l);
  assert (l == 140); // according to Twitter's web interface
}

void newline_link () {
  string text = "Foo\nhttp://foobar.org";
  int l = TweetUtils.calc_tweet_length (text);
  message ("Length: %d", l);
  assert (l == Twitter.short_url_length + 3 + 1);
}

void whitespace () {
  string text = "Foo     Bar"; // 5 spaces
  int l = TweetUtils.calc_tweet_length (text);
  message ("Length: %d", l);
  assert (l == 11);
}

void utf8 () {
  string text = "€¤²˛×     ××¹áœ http://¤³¤€.com"; // 5 + 5 + 5 + 1 + 22
  message (text);
  int l = TweetUtils.calc_tweet_length (text);
  message ("%d", l);

  assert (l == 5 + 5 + 5 + 1 + Twitter.short_url_length);
}

void unicode1 () {
  string text = "a…";

  int l = TweetUtils.calc_tweet_length (text);
  message ("Length: %d", l);
  assert (l == 2);
}

void trailing_whitespace () {
  string text = "abc ";

  int l = TweetUtils.calc_tweet_length (text);
  message ("Length: %d", l);

  assert (l == 4);
}

void trailing_whitespace2 () {
  string text = "abc    ";

  int l = TweetUtils.calc_tweet_length (text);
  message ("Length: %d", l);

  assert (l == 7);
}

void punctuation_url () {
  string text = "foobar(http://abc.com)";

  int l = TweetUtils.calc_tweet_length (text);
  message ("Length: %d", l);
  assert (l == 6 + 1 + Twitter.short_url_length + 1);
}


void punctuation_url2 () {
  string text = "...http://foobar.com";

  int l = TweetUtils.calc_tweet_length (text);
  message ("Length: %d", l);
  assert (l == 3 + Twitter.short_url_length);
}

int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/tweet-length/normal", normal);
  GLib.Test.add_func ("/tweet-length/empty", empty);
  GLib.Test.add_func ("/tweet-length/http-link", http_link);
  GLib.Test.add_func ("/tweet-length/https-link", https_link);
  GLib.Test.add_func ("/tweet-length/media", media);
  GLib.Test.add_func ("/tweet-length/media-text", media_text);
  GLib.Test.add_func ("/tweet-length/tld1", tld1);
  GLib.Test.add_func ("/tweet-length/real-text1", real_text1);
  GLib.Test.add_func ("/tweet-length/newline-link", newline_link);
  GLib.Test.add_func ("/tweet-length/whitespace", whitespace);
  GLib.Test.add_func ("/tweet-length/utf8", utf8);
  GLib.Test.add_func ("/tweet-length/unicode1", unicode1);
  GLib.Test.add_func ("/tweet-length/trailing-whitespace", trailing_whitespace);
  GLib.Test.add_func ("/tweet-length/trailing-whitespace2", trailing_whitespace2);
  GLib.Test.add_func ("/tweet-length/punctuation-url", punctuation_url);

  // TODO Fails.
  //GLib.Test.add_func ("/tweet-length/punctuation-url2", punctuation_url2);

  return GLib.Test.run ();
}
