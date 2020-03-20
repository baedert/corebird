
void empty () {
  var entities = new Cb.TextEntity[0];
  string source_text = "";

  string result = Cb.TextTransform.text (source_text,
                                         entities,
                                         0,
                                         0,
                                         0);

  assert (result == source_text);

  result = Cb.TextTransform.text (source_text,
                                  entities,
                                  Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS,
                                  0,
                                  0);
  assert (result == source_text);
}

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


void trailing_whitespace () {
  var entities = new Cb.TextEntity[1];
  entities[0] = Cb.TextEntity () {
    from = 13,
    to = 18,
    display_text = "#blah",
    target = "#blah"
  };
  string source_text = "foo bar foo\n\n#blah";

  string result = Cb.TextTransform.text (source_text,
                                         entities,
                                         Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS,
                                         0,
                                         0);

  // This is not strictly necessary, but we do it for clearity.
  // Printing this for debugging is much better.
  var p = result.replace("\n", "\\n");
  assert (!p.contains ("#blah"));
  assert (!p.contains ("\\n"));

  entities = new Cb.TextEntity[0];

  source_text = "foo á";
  result = Cb.TextTransform.text (source_text,
                                  entities,
                                  Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS,
                                  0,
                                  0);

  // Quick check that we aren't screwing up the result with a non-ascii character at the end...
  assert (result.has_suffix ("á"));

  source_text = "one two three\n\n#foo #bar";
  entities = new Cb.TextEntity[2];
  entities[0] = Cb.TextEntity () {
    from = 15,
    to = 19,
    display_text = "#foo",
    target = "#foo"
  };
  entities[1] = Cb.TextEntity () {
    from = 20,
    to = 24,
    display_text = "#bar",
    target = "#bar"
  };

  result = Cb.TextTransform.text (source_text,
                                  entities,
                                  Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS,
                                  0,
                                  0);

  p = result.replace ("\n", "\\n");
  assert (!p.contains ("\\n"));

  source_text = "#foo";
  entities = new Cb.TextEntity[1];
  entities[0] = Cb.TextEntity () {
    from = 0,
    to = 4,
    display_text = "#foo",
    target = "#foo"
  };
  result = Cb.TextTransform.text (source_text,
                                  entities,
                                  Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS,
                                  0,
                                  0);
  // This is useless, we the above call just shouldn't cause any errors in valgrind
  assert (result.length == 0);
}

void raw () {
  string text, processed;
  assert (Cb.TextTransform.raw ("") == "");
  assert (Cb.TextTransform.raw ("foo") == "foo");
  assert (Cb.TextTransform.raw ("<p>foo</p>") == "foo");
  assert (Cb.TextTransform.raw ("<span class=\"whocares\">foo</span>") == "foo");

  // Simple newline
  assert (Cb.TextTransform.raw ("a<br>b") == "a\nb");
  assert (Cb.TextTransform.raw ("a<br/>b") == "a\nb");
  assert (Cb.TextTransform.raw ("a<br />b") == "a\nb");

  text = "<p>a<br />b<br />c</p><p>d</p>";
  processed = Cb.TextTransform.raw (text);
  assert (processed == "a\nb\nc\n\nd");

  text = "<p>お嬢どいてくれや</p>";
  processed = Cb.TextTransform.raw (text);
  assert (processed == "お嬢どいてくれや");
}

int main (string[] args) {
  GLib.Environment.set_variable ("GSETTINGS_BACKEND", "memory", true);
  Intl.setlocale (LocaleCategory.ALL, "");
  GLib.Test.init (ref args);
  Settings.init ();
  GLib.Test.add_func ("/tt/empty", empty);
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
  GLib.Test.add_func ("/tt/trailing-whitespace", trailing_whitespace);
  GLib.Test.add_func ("/tt/raw", raw);

  return GLib.Test.run ();
}

