
void normal () {
  var entities = new Cb.TextEntity[0];
  string source_text = "foo bar foo";

  string result = Cb.TextTransform.text (source_text,
                                         entities,
                                         0,
                                         0,
                                         0);

  assert (result == source_text);
}


void simple () {
  var entities = new Cb.TextEntity[1];
  entities[0] = Cb.TextEntity () {
    from = 4,
    to   = 6,
    display_text = "display_text",
    tooltip_text = "tooltip_text",
    target       = "target_text"
  };

  string source_text = "foo bar foo";
  string result = Cb.TextTransform.text (source_text,
                                         entities,
                                         0,
                                         0,
                                         0);

  // Not the best asserts, but oh well
  assert (result.contains ("display_text"));
  assert (result.contains ("tooltip_text"));
  assert (result.contains ("target_text"));
}

void url_at_end () {
  var entities = new Cb.TextEntity[1];
  entities[0] = Cb.TextEntity () {
    from = 8,
    to   = 9,
    display_text = "display_text",
    tooltip_text = "tooltip_text",
    target       = "target_text"
  };

  string source_text = "foo bar foo";
  string result = Cb.TextTransform.text (source_text,
                                         entities,
                                         0,
                                         0,
                                         0);

  // Not the best asserts, but oh well
  assert (result.contains ("display_text"));
  assert (result.contains ("tooltip_text"));
  assert (result.contains ("target_text"));
}


void utf8 () {
  var entities = new Cb.TextEntity[1];
  entities[0] = Cb.TextEntity () {
    from = 2,
    to   = 6,
    display_text = "#foo",
    tooltip_text = "#foo",
    target       = null
  };

  string source_text = "× #foo";
  string result = Cb.TextTransform.text (source_text,
                                         entities,
                                         Cb.TransformFlags.REMOVE_MEDIA_LINKS,
                                         0, 0);
  assert (result.has_prefix ("× "));
}


void expand_links () {
  var entities = new Cb.TextEntity[1];
  entities[0] = Cb.TextEntity () {
    from = 2,
    to   = 6,
    display_text = "displayfoobar",
    tooltip_text = "#foo",
    target       = "target_url"
  };

  string source_text = "× #foo";
  string result = Cb.TextTransform.text (source_text,
                                         entities,
                                         Cb.TransformFlags.EXPAND_LINKS,
                                         0, 0);

  assert (result.has_prefix ("× "));
  assert (!result.contains ("displayfoobar"));
  assert (result.contains ("target_url"));
}

void multiple_links () {
  var entities = new Cb.TextEntity[4];
  entities[0] = Cb.TextEntity () {
    from = 0,
    to = 22,
    display_text = "mirgehendirurlsaus.com",
    target = "http://mirgehendirurlsaus.com",
    tooltip_text = "http://mirgehendirurlsaus.com"
  };
  entities[1] = Cb.TextEntity () {
    from = 26,
    to   = 48,
    display_text = "foobar.com",
    target = "http://foobar.com",
    tooltip_text = "http://foobar.com"
  };
  entities[2] = Cb.TextEntity () {
    from = 52,
    to   = 74,
    display_text = "hahaaha.com",
    target = "http://hahaaha.com",
    tooltip_text = "http://hahaaha.com"
  };
  entities[3] = Cb.TextEntity () {
    from = 77,
    to   = 99,
    display_text = "huehue.org",
    target = "http://huehue.org",
    tooltip_text = "http://huehue.org"
  };

  string text = "http://t.co/O5uZwJg31k    http://t.co/BsKkxv8UG4    http://t.co/W8qs846ude   http://t.co/x4bKoCusvQ";

  string result = Cb.TextTransform.text (text,
                                         entities,
                                         0, 0, 0);


  string spec = """<span underline="none"><a href="http://mirgehendirurlsaus.com" title="http://mirgehendirurlsaus.com">mirgehendirurlsaus.com</a></span>    <span underline="none"><a href="http://foobar.com" title="http://foobar.com">foobar.com</a></span>    <span underline="none"><a href="http://hahaaha.com" title="http://hahaaha.com">hahaaha.com</a></span>   <span underline="none"><a href="http://huehue.org" title="http://huehue.org">huehue.org</a></span>""";

  assert (result == spec);
}


void remove_only_trailing_hashtags () {
  string text = "Hey, #totally inappropriate @baedert! #baedertworship öä #thefeels   ";

  var entities = new Cb.TextEntity[4];

  entities[0] = Cb.TextEntity () {
    from = 5,
    to = 13,
    display_text = "#totally",
    target = "foobar"
  };

  entities[1] = Cb.TextEntity () {
    from = 28,
    to = 36,
    display_text = "@baedert",
    target = "blubb"
  };

  entities[2] = Cb.TextEntity () {
    from = 38,
    to = 53,
    display_text = "#baedertwhorship",
    target = "bla"
  };

  entities[3] = Cb.TextEntity () {
    from = 57,
    to = 66,
    display_text = "#thefeels",
    target = "foobar"
  };

  string result = Cb.TextTransform.text (text,
                                         entities,
                                         Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS,
                                         0, 0);
  message (result);

  assert (result.contains (">@baedert<")); // Mention should still be a link
  assert (result.contains (">#totally<"));
  assert (!result.contains ("#baedertworship"));
  assert (!result.contains ("#thefeels"));
}

void remove_multiple_trailing_hashtags () {
  string text = "Hey, #totally inappropriate @baedert! #baedertworship #thefeels #foobar";

  var entities = new Cb.TextEntity[5];

  entities[0] = Cb.TextEntity () {
    from = 5,
    to = 13,
    display_text = "#totally",
    target = "foobar"
  };

  entities[1] = Cb.TextEntity () {
    from = 28,
    to = 36,
    display_text = "@baedert",
    target = "blubb"
  };

  entities[2] = Cb.TextEntity () {
    from = 38,
    to = 53,
    display_text = "#baedertwhorship",
    target = "bla"
  };

  entities[3] = Cb.TextEntity () {
    from = 54,
    to = 63,
    display_text = "#thefeels",
    target = "foobar"
  };

  entities[4] = Cb.TextEntity () {
    from = 64,
    to = 71,
    display_text = "#foobar",
    target = "bla"
  };

  string result = Cb.TextTransform.text (text,
                                         entities,
                                         Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS, 0, 0);

  assert (result.contains (">@baedert<")); // Mention should still be a link
  assert (result.contains (">#totally<"));
  assert (!result.contains ("#baedertworship"));
  assert (!result.contains ("#thefeels"));
  assert (!result.contains ("#foobar"));
}


void trailing_hashtags_mention_before () {
  string text = "Hey, #totally inappropriate! #baedertworship @baedert #foobar";

  var entities = new Cb.TextEntity[4];

  entities[0] = Cb.TextEntity () {
    from = 5,
    to = 13,
    display_text = "#totally",
    target = "foobar"
  };

  entities[1] = Cb.TextEntity () {
    from = 29,
    to = 44,
    display_text = "#baedertworship",
    target = "bla"
  };

  entities[2] = Cb.TextEntity () {
    from = 45,
    to = 53,
    display_text = "@baedert",
    target = "foobar"
  };

  entities[3] = Cb.TextEntity () {
    from = 54,
    to = 61,
    display_text = "#foobar",
    target = "bla"
  };

  string result = Cb.TextTransform.text (text,
                                         entities,
                                         Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS, 0, 0);

  assert (result.contains (">@baedert<")); // Mention should still be a link
  assert (result.contains (">#totally<"));
  assert (result.contains (">#baedertworship<"));
  assert (!result.contains ("#foobar"));
}


void whitespace_hashtags () {
  string text = "Hey, #totally inappropriate @baedert! #baedertworship #thefeels #foobar";

  var entities = new Cb.TextEntity[5];

  entities[0] = Cb.TextEntity () {
    from = 5,
    to = 13,
    display_text = "#totally",
    target = "foobar"
  };

  entities[1] = Cb.TextEntity () {
    from = 28,
    to = 36,
    display_text = "@baedert",
    target = "blubb"
  };

  entities[2] = Cb.TextEntity () {
    from = 38,
    to = 53,
    display_text = "#baedertwhorship",
    target = "bla"
  };

  entities[3] = Cb.TextEntity () {
    from = 54,
    to = 63,
    display_text = "#thefeels",
    target = "foobar"
  };

  entities[4] = Cb.TextEntity () {
    from = 64,
    to = 71,
    display_text = "#foobar",
    target = "bla"
  };

  string result = Cb.TextTransform.text (text,
                                         entities,
                                         Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS, 0, 0);

  assert (result.contains (">@baedert<")); // Mention should still be a link
  assert (result.contains (">#totally<"));
  assert (!result.contains ("#baedertworship"));
  assert (!result.contains ("#thefeels"));
  assert (!result.contains ("#foobar"));
  assert (!result.contains ("   ")); // 3 spaces between the 3 hashtags
}

void trailing_hashtags_link_after () {
  string text = "Hey, #totally inappropriate @baedert! #baedertworship https://foobar.com";

  var entities = new Cb.TextEntity[4];

  entities[0] = Cb.TextEntity () {
    from = 5,
    to = 13,
    display_text = "#totally",
    target = "foobar"
  };

  entities[1] = Cb.TextEntity () {
    from = 28,
    to = 36,
    display_text = "@baedert",
    target = "blubb"
  };

  entities[2] = Cb.TextEntity () {
    from = 38,
    to = 53,
    display_text = "#baedertwhorship",
    target = "bla"
  };

  entities[3] = Cb.TextEntity () {
    from = 54,
    to = 72,
    display_text = "BLA BLA BLA",
    target = "https://foobar.com"
  };

  string result = Cb.TextTransform.text (text,
                                         entities,
                                         Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS,
                                         0, 0);

  assert (result.contains (">@baedert<")); // Mention should still be a link
  assert (result.contains (">#totally<"));
  assert (!result.contains ("#baedertworship"));
}


void no_quoted_link () {
  Tweet t = new Tweet ();
  t.quoted_tweet = Cb.MiniTweet ();
  t.quoted_tweet.id = 1337;

  t.source_tweet = Cb.MiniTweet ();
  t.source_tweet.text = "Foobar Some text after.";
  t.source_tweet.entities = new Cb.TextEntity[1];
  t.source_tweet.entities[0] = Cb.TextEntity () {
    from = 0,
    to   = 6,
    target = "https://twitter.com/bla/status/1337",
    display_text = "sometextwhocares"
  };

  Settings.add_text_transform_flag (Cb.TransformFlags.REMOVE_MEDIA_LINKS);

  string result = t.get_trimmed_text ();

  message (result);

  assert (!result.contains ("1337"));
  assert (result.length > 0);
}

int main (string[] args) {
  GLib.Environment.set_variable ("GSETTINGS_BACKEND", "memory", true);
  Intl.setlocale (LocaleCategory.ALL, "");
  GLib.Test.init (ref args);
  Settings.init ();
  GLib.Test.add_func ("/tt/normal", normal);
  GLib.Test.add_func ("/tt/simple", simple);
  GLib.Test.add_func ("/tt/url-at-end", url_at_end);
  GLib.Test.add_func ("/tt/utf8", utf8);
  GLib.Test.add_func ("/tt/expand-links", expand_links);
  GLib.Test.add_func ("/tt/multiple-links", multiple_links);
  GLib.Test.add_func ("/tt/remove-only-trailing-hashtags", remove_only_trailing_hashtags);
  GLib.Test.add_func ("/tt/remove-multiple-trailing-hashtags", remove_multiple_trailing_hashtags);
  GLib.Test.add_func ("/tt/trailing-hashtags-mention-before", trailing_hashtags_mention_before);
  GLib.Test.add_func ("/tt/whitespace-between-trailing-hashtags", whitespace_hashtags);
  GLib.Test.add_func ("/tt/trailing-hashtags-media-link-after", trailing_hashtags_link_after);
  GLib.Test.add_func ("/tt/no-quoted-link", no_quoted_link);

  return GLib.Test.run ();
}
