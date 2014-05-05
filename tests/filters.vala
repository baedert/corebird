

// {{{

// TODO: Get tweet data. Real text + display text
const string TD1 = """



""";




// }}}

void matches () {
  var f = new Filter ("a+");
  assert (f.matches ("a"));
}

void matches_tweet () {
  var acc = new Account (12345, "foobar", "Foo Bar");
  var filter = new Filter ("a+");
  acc.add_filter (filter);
  var tweet = new Tweet ();
  var parser = new Json.Parser ();
  var now = new GLib.DateTime.now_local ();
  try {
    parser.load_from_data (TD1);
  } catch (GLib.Error e) {
    critical (e.message);
    return;
  }
  tweet.load_from_json (parser.get_root (), now, acc);
}

void same_user () {
  var acc = new Account (12345, "foobar", "Foo Bar");
  var filter = new Filter ("a+");
  acc.add_filter (filter);
  var tweet = new Tweet ();
  var parser = new Json.Parser ();
  var now = new GLib.DateTime.now_local ();
  try {
    parser.load_from_data (TD1);
  } catch (GLib.Error e) {
    critical (e.message);
    return;
  }
  tweet.load_from_json (parser.get_root (), now, acc);
  tweet.user_id = 12345;

  // Should always return false even if the filter(s) would match
  assert (!acc.filter_matches (tweet));
}



void links () {
  var acc = new Account (12345, "foobar", "Foo Bar");
  var filter = new Filter ("t\\.co");
  acc.add_filter (filter);
  var tweet = new Tweet ();
  var parser = new Json.Parser ();
  var now = new GLib.DateTime.now_local ();
  try {
    parser.load_from_data (TD1);
  } catch (GLib.Error e) {
    critical (e.message);
    return;
  }
  tweet.load_from_json (parser.get_root (), now, acc);

  // This should never match since we should be using the
  // 'real' url instead of the t.co shortened one.
  assert (!acc.filter_matches (tweet));
}




int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/filters/matches", matches);
  GLib.Test.add_func ("/filters/matches-tweet", matches_tweet);
  GLib.Test.add_func ("/filters/same-user", same_user);
  GLib.Test.add_func ("/filters/links", links);

  return GLib.Test.run ();
}
