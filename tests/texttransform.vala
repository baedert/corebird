
void normal () {
  var entities = new GLib.SList<TextEntity?> ();
  string source_text = "foo bar foo";

  string result = TextTransform.transform (source_text,
                                           entities,
                                           0);

  assert (result == source_text);
}



void simple () {
  var entities = new GLib.SList<TextEntity?> ();
  entities.prepend (TextEntity () {
                    from = 4,
                    to   = 6,
                    display_text = "display_text",
                    tooltip_text = "tooltip_text",
                    target       = "target_text"
                  });

  string source_text = "foo bar foo";
  string result = TextTransform.transform (source_text,
                                           entities,
                                           0);

  // Not the best asserts, but oh well
  assert (result.contains ("display_text"));
  assert (result.contains ("tooltip_text"));
  assert (result.contains ("target_text"));
}

void url_at_end () {
  var entities = new GLib.SList<TextEntity?> ();
  entities.prepend (TextEntity () {
                    from = 8,
                    to   = 9,
                    display_text = "display_text",
                    tooltip_text = "tooltip_text",
                    target       = "target_text"
                   });

  string source_text = "foo bar foo";
  string result = TextTransform.transform (source_text,
                                           entities,
                                           0);

  // Not the best asserts, but oh well
  assert (result.contains ("display_text"));
  assert (result.contains ("tooltip_text"));
  assert (result.contains ("target_text"));
}


void utf8 () {
  var entities = new GLib.SList<TextEntity?> ();
  entities.prepend (TextEntity () {
                    from = 2,
                    to   = 6,
                    display_text = "#foo",
                    tooltip_text = "#foo",
                    target       = null
                  });

  string source_text = "× #foo";
  string result = TextTransform.transform (source_text,
                                           entities,
                                           TransformFlags.REMOVE_MEDIA_LINKS);
  assert (result.has_prefix ("× "));
}


void expand_links () {
  /* TransformFlags.EXPAND_LINKS means:
      - If target != null, use the target instead of the display_text
      - if target == null, use the display_text
      - but in any case, don't add any pango markup tags
  */
  var entities = new GLib.SList<TextEntity?> ();
  entities.prepend (TextEntity () {
                    from = 2,
                    to   = 6,
                    display_text = "displayfoobar",
                    tooltip_text = "#foo",
                    target       = "target_url"
                  });

  string source_text = "× #foo";
  string result = TextTransform.transform (source_text,
                                           entities,
                                           TransformFlags.EXPAND_LINKS);
  message (result);
  assert (result.has_prefix ("× "));
  assert (!result.contains ("displayfoobar"));
  assert (result.contains ("target_url"));
}

void multiple_links () {
  var entities = new GLib.SList<TextEntity?> ();
  entities.prepend (TextEntity () {
    from = 0,
    to = 22,
    display_text = "mirgehendirurlsaus.com",
    target = "http://mirgehendirurlsaus.com",
    tooltip_text = "http://mirgehendirurlsaus.com"
  });
  entities.prepend (TextEntity () {
    from = 26,
    to   = 48,
    display_text = "foobar.com",
    target = "http://foobar.com",
    tooltip_text = "http://foobar.com"
  });
  entities.prepend (TextEntity () {
    from = 52,
    to   = 74,
    display_text = "hahaaha.com",
    target = "http://hahaaha.com",
    tooltip_text = "http://hahaaha.com"
  });
  entities.prepend (TextEntity () {
    from = 77,
    to   = 99,
    display_text = "huehue.org",
    target = "http://huehue.org",
    tooltip_text = "http://huehue.org"
  });
  entities.sort ((a, b) => {
    if (a.from < b.from)
      return -1;
    return 1;
   });


  string text = "http://t.co/O5uZwJg31k    http://t.co/BsKkxv8UG4    http://t.co/W8qs846ude   http://t.co/x4bKoCusvQ";

  string result = TextTransform.transform (text,
                                           entities,
                                           0);


  string spec = """<span underline="none"><a href="http://mirgehendirurlsaus.com" title="http://mirgehendirurlsaus.com">mirgehendirurlsaus.com</a></span>    <span underline="none"><a href="http://foobar.com" title="http://foobar.com">foobar.com</a></span>    <span underline="none"><a href="http://hahaaha.com" title="http://hahaaha.com">hahaaha.com</a></span>   <span underline="none"><a href="http://huehue.org" title="http://huehue.org">huehue.org</a></span>""";

  stdout.printf ("'" + spec + "'\n");
  stdout.printf ("'" + result + "'\n");
  assert (result == spec);
}

int main (string[] args) {
  Intl.setlocale (LocaleCategory.ALL, "");
  GLib.Test.init (ref args);
  Settings.init ();
  GLib.Test.add_func ("/tt/normal", normal);
  GLib.Test.add_func ("/tt/simple", simple);
  GLib.Test.add_func ("/tt/url-at-end", url_at_end);
  GLib.Test.add_func ("/tt/utf8", utf8);
  GLib.Test.add_func ("/tt/expand-links", expand_links);
  GLib.Test.add_func ("/tt/multiple-links", multiple_links);


  return GLib.Test.run ();
}
