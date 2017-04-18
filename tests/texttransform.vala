
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


void no_quoted_link () {
  var t = new Cb.Tweet ();
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

  string result = t.get_trimmed_text (Settings.get_text_transform_flags ());

  assert (!result.contains ("1337"));
  assert (result.length > 0);
}

void new_reply () {
  /*
   * This tests a the 'new reply' behavior, see
   * https://dev.twitter.com/overview/api/upcoming-changes-to-tweets
   */
  var t = new Cb.Tweet ();
  var parser = new Json.Parser ();
  try {
    parser.load_from_data (REPLY_TWEET_DATA);
    t.load_from_json (parser.get_root (), 1337, new GLib.DateTime.now_local ());
  } catch (GLib.Error e) {
    assert (false);
  }

  assert (t.source_tweet.display_range_start == 115);

  message ("Entities:");
  foreach (var e in t.source_tweet.entities) {
    message ("'%s': %u, %u", e.display_text, e.from, e.to);
  }

  var text = t.get_trimmed_text (Cb.TransformFlags.EXPAND_LINKS);
  message (text);

  /* Should not contain any mention */
  assert (!text.contains ("@"));

  /* One of the entities is a URL, the expanded link should point to
   * eventbrite.com, not t.co */
  assert (!text.contains ("t.co"));
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
  GLib.Test.add_func ("/tt/new-reply", new_reply);

  return GLib.Test.run ();
}

// {{{
const string REPLY_TWEET_DATA = """
{
  "created_at" : "Mon Apr 17 15:16:18 +0000 2017",
  "id" : 853990508326252550,
  "id_str" : "853990508326252550",
  "full_text" : "@jjdesmond @_UBRAS_ @franalsworth @4Apes @katy4apes @theAliceRoberts @JaneGoodallUK @Jane_Goodall @JaneGoodallInst And here's the link for tickets again ... https://t.co/a9lOVMouNK",
  "truncated" : false,
  "display_text_range" : [
    115,
    180
  ],
  "entities" : {
    "hashtags" : [
    ],
    "symbols" : [
    ],
    "user_mentions" : [
      {
        "screen_name" : "jjdesmond",
        "name" : "Jimmy Jenny Desmond",
        "id" : 21278482,
        "id_str" : "21278482",
        "indices" : [
          0,
          10
        ]
      },
      {
        "screen_name" : "_UBRAS_",
        "name" : "Roots and Shoots UOB",
        "id" : 803329927974096896,
        "id_str" : "803329927974096896",
        "indices" : [
          11,
          19
        ]
      },
      {
        "screen_name" : "franalsworth",
        "name" : "Fran",
        "id" : 776983919287754752,
        "id_str" : "776983919287754752",
        "indices" : [
          20,
          33
        ]
      },
      {
        "screen_name" : "4Apes",
        "name" : "Ian Redmond",
        "id" : 155889035,
        "id_str" : "155889035",
        "indices" : [
          34,
          40
        ]
      },
      {
        "screen_name" : "katy4apes",
        "name" : "Katy Jedamzik",
        "id" : 159608654,
        "id_str" : "159608654",
        "indices" : [
          41,
          51
        ]
      },
      {
        "screen_name" : "theAliceRoberts",
        "name" : "Prof Alice Roberts",
        "id" : 260211154,
        "id_str" : "260211154",
        "indices" : [
          52,
          68
        ]
      },
      {
        "screen_name" : "JaneGoodallUK",
        "name" : "Roots & Shoots UK",
        "id" : 423423823,
        "id_str" : "423423823",
        "indices" : [
          69,
          83
        ]
      },
      {
        "screen_name" : "Jane_Goodall",
        "name" : "Jane Goodall",
        "id" : 235157216,
        "id_str" : "235157216",
        "indices" : [
          84,
          97
        ]
      },
      {
        "screen_name" : "JaneGoodallInst",
        "name" : "JaneGoodallInstitute",
        "id" : 39822897,
        "id_str" : "39822897",
        "indices" : [
          98,
          114
        ]
      }
    ],
    "urls" : [
      {
        "url" : "https://t.co/a9lOVMouNK",
        "expanded_url" : "https://www.eventbrite.com/e/working-with-apes-tickets-33089771397",
        "display_url" : "eventbrite.com/e/working-with…",
        "indices" : [
          157,
          180
        ]
      }
    ]
  },
  "source" : "<a href=\"http://twitter.com/download/iphone\" rel=\"nofollow\">Twitter for iPhone</a>",
  "in_reply_to_status_id" : 853925036696141824,
  "in_reply_to_status_id_str" : "853925036696141824",
  "in_reply_to_user_id" : 21278482,
  "in_reply_to_user_id_str" : "21278482",
  "in_reply_to_screen_name" : "jjdesmond",
  "user" : {
    "id" : 415472140,
    "id_str" : "415472140",
    "name" : "Ben Garrod",
    "screen_name" : "Ben_garrod",
    "location" : "Bristol&Norfolk",
    "description" : "Monkey-chaser, TV-talker, bone geek and Teaching Fellow at @AngliaRuskin https://t.co/FXbftdxxTJ",
    "url" : "https://t.co/1B9SDHfWoF",
    "entities" : {
      "url" : {
        "urls" : [
          {
            "url" : "https://t.co/1B9SDHfWoF",
            "expanded_url" : "http://www.josarsby.com/ben-garrod",
            "display_url" : "josarsby.com/ben-garrod",
            "indices" : [
              0,
              23
            ]
          }
        ]
      },
      "description" : {
        "urls" : [
          {
            "url" : "https://t.co/FXbftdxxTJ",
            "expanded_url" : "http://www.anglia.ac.uk/science-and-technology/about/life-sciences/our-staff/ben-garrod",
            "display_url" : "anglia.ac.uk/science-and-te…",
            "indices" : [
              73,
              96
            ]
          }
        ]
      }
    },
    "protected" : false,
    "followers_count" : 6526,
    "friends_count" : 1016,
    "listed_count" : 128,
    "created_at" : "Fri Nov 18 11:30:48 +0000 2011",
    "favourites_count" : 25292,
    "utc_offset" : 3600,
    "time_zone" : "London",
    "geo_enabled" : true,
    "verified" : true,
    "statuses_count" : 17224,
    "lang" : "en",
    "contributors_enabled" : false,
    "is_translator" : false,
    "is_translation_enabled" : false,
    "profile_background_color" : "C0DEED",
    "profile_background_image_url" : "http://pbs.twimg.com/profile_background_images/590945579024257024/2F1itaGz.jpg",
    "profile_background_image_url_https" : "https://pbs.twimg.com/profile_background_images/590945579024257024/2F1itaGz.jpg",
    "profile_background_tile" : false,
    "profile_image_url" : "http://pbs.twimg.com/profile_images/615498558385557505/cwSloac3_normal.jpg",
    "profile_image_url_https" : "https://pbs.twimg.com/profile_images/615498558385557505/cwSloac3_normal.jpg",
    "profile_banner_url" : "https://pbs.twimg.com/profile_banners/415472140/1477223840",
    "profile_link_color" : "0084B4",
    "profile_sidebar_border_color" : "FFFFFF",
    "profile_sidebar_fill_color" : "DDEEF6",
    "profile_text_color" : "333333",
    "profile_use_background_image" : false,
    "has_extended_profile" : false,
    "default_profile" : false,
    "default_profile_image" : false,
    "following" : false,
    "follow_request_sent" : false,
    "notifications" : false,
    "translator_type" : "none"
  },
  "geo" : null,
  "coordinates" : null,
  "place" : null,
  "contributors" : null,
  "is_quote_status" : false,
  "retweet_count" : 6,
  "favorite_count" : 7,
  "favorited" : false,
  "retweeted" : false,
  "possibly_sensitive" : false,
  "lang" : "en"
}

""";

// }}}
