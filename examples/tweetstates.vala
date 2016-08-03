
Cb.Tweet parse_tweet (string input) {
  var parser = new Json.Parser ();
  try {
    parser.load_from_data (input);
  } catch (Error e) {
    error (e.message);
  }

  Cb.Tweet tweet = new Cb.Tweet ();
  tweet.load_from_json (parser.get_root (), new GLib.DateTime.now_local ());

  return tweet;
}

void main (string[] args) {
  Gtk.init (ref args);
  Settings.init ();
  Utils.load_custom_css ();
  Utils.load_custom_icons ();
  Utils.init_soup_session ();
  Twitter.get ().init ();

  var window = new Gtk.Window ();
  window.delete_event.connect (() => {Gtk.main_quit (); return true; });
  var list = new Gtk.ListBox ();
  list.selection_mode = Gtk.SelectionMode.NONE;
  var list2 = new Gtk.ListBox ();
  list2.selection_mode = Gtk.SelectionMode.NONE;
  var list3 = new Gtk.ListBox ();
  list3.selection_mode = Gtk.SelectionMode.NONE;
  var scroller = new Gtk.ScrolledWindow (null, null);
  scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
  var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
  box.homogeneous = true;

  // Ensure types
  new LazyMenuButton ();

  var fake_acount = new Account (1337, "baedert", "Foo Bar Baedert");

  {
    // Normal tweet.
    var tweet = parse_tweet (NORMAL_TWEET);
    var row = new TweetListEntry (tweet, null, fake_acount);
    list.add (row);
  }

  {
    // Retweet
    var tweet = parse_tweet (RETWEET);
    var row = new TweetListEntry (tweet, null, fake_acount);
    list.add (row);
  }

  {
    // Normal, but with media attached
    var tweet = parse_tweet (NORMAL_WITH_MEDIA);
    var row = new TweetListEntry (tweet, null, fake_acount);
    list.add (row);
  }

  {
    // Normal quote
    var tweet = parse_tweet (NORMAL_QUOTE);
    var row = new TweetListEntry (tweet, null, fake_acount);
    list.add (row);
  }

  {
    // Quote with Media
    var tweet = parse_tweet (QUOTE_WITH_MEDIA);
    var row = new TweetListEntry (tweet, null, fake_acount);
    list2.add (row);
  }

  {
    // Retweet with media
    var tweet = parse_tweet (RETWEET_WITH_MEDIA);
    var row = new TweetListEntry (tweet, null, fake_acount);
    list2.add (row);
  }

  {
    // Empty (no text) tweet with media
    var tweet = parse_tweet (EMPTY_TWEET_WITH_MEDIA);
    var row = new TweetListEntry (tweet, null, fake_acount);
    list.add (row);
  }

  {
    // Retweet with media but no text
    var tweet = parse_tweet (EMPTY_RETWEET_WITH_MEDIA);
    var row = new TweetListEntry (tweet, null, fake_acount);
    list3.add (row);
  }

  list.set_size_request  (500, -1);
  list2.set_size_request (500, -1);
  list2.set_size_request (500, -1);

  box.add (list);
  box.add (list2);
  box.add (list3);
  scroller.add (box);
  window.add (scroller);
  window.show_all ();
  window.resize (1500, 900);
  Gtk.main ();
}


const string NORMAL_TWEET =
"""
{
  "created_at" : "Wed Aug 03 04:06:47 +0000 2016",
  "id" : 760688337610997764,
  "id_str" : "760688337610997764",
  "text" : "My dick was already out BEFORE Harambe died.",
  "truncated" : false,
  "entities" : {
    "hashtags" : [
    ],
    "symbols" : [
    ],
    "user_mentions" : [
    ],
    "urls" : [
    ]
  },
  "source" : "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>",
  "in_reply_to_status_id" : null,
  "in_reply_to_status_id_str" : null,
  "in_reply_to_user_id" : null,
  "in_reply_to_user_id_str" : null,
  "in_reply_to_screen_name" : null,
  "user" : {
    "id" : 21369740,
    "id_str" : "21369740",
    "name" : "Rob DenBleyker",
    "screen_name" : "RobDenBleyker",
    "location" : "Dallas",
    "description" : "I'm not Rob Dyrdek. Don't follow me.",
    "url" : "https://t.co/5jh1OQTAOO",
    "entities" : {
      "url" : {
        "urls" : [
          {
            "url" : "https://t.co/5jh1OQTAOO",
            "expanded_url" : "http://www.explosm.net",
            "display_url" : "explosm.net",
            "indices" : [
              0,
              23
            ]
          }
        ]
      },
      "description" : {
        "urls" : [
        ]
      }
    },
    "protected" : false,
    "followers_count" : 126455,
    "friends_count" : 800,
    "listed_count" : 1284,
    "created_at" : "Fri Feb 20 03:26:24 +0000 2009",
    "favourites_count" : 1452,
    "utc_offset" : -18000,
    "time_zone" : "Central Time (US & Canada)",
    "geo_enabled" : true,
    "verified" : false,
    "statuses_count" : 8088,
    "lang" : "en",
    "contributors_enabled" : false,
    "is_translator" : false,
    "is_translation_enabled" : false,
    "profile_background_color" : "49585E",
    "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_tile" : false,
    "profile_image_url" : "http://pbs.twimg.com/profile_images/751256809873281024/-FuDkY2p_normal.jpg",
    "profile_image_url_https" : "https://pbs.twimg.com/profile_images/751256809873281024/-FuDkY2p_normal.jpg",
    "profile_link_color" : "0C90F5",
    "profile_sidebar_border_color" : "C0DEED",
    "profile_sidebar_fill_color" : "DDEEF6",
    "profile_text_color" : "333333",
    "profile_use_background_image" : false,
    "has_extended_profile" : false,
    "default_profile" : false,
    "default_profile_image" : false,
    "following" : true,
    "follow_request_sent" : false,
    "notifications" : false
  },
  "geo" : null,
  "coordinates" : null,
  "place" : null,
  "contributors" : null,
  "is_quote_status" : false,
  "retweet_count" : 111,
  "favorite_count" : 335,
  "favorited" : false,
  "retweeted" : false,
  "lang" : "en"
}
""";

const string RETWEET =
"""
{
  "created_at" : "Tue Aug 02 17:25:04 +0000 2016",
  "id" : 760526843699007488,
  "id_str" : "760526843699007488",
  "text" : "RT @wilw: OH: \"All fucking dentists are in the pocket of big floss!\"",
  "truncated" : false,
  "entities" : {
    "hashtags" : [
    ],
    "symbols" : [
    ],
    "user_mentions" : [
      {
        "screen_name" : "wilw",
        "name" : "Wil Wheaton",
        "id" : 1183041,
        "id_str" : "1183041",
        "indices" : [
          3,
          8
        ]
      }
    ],
    "urls" : [
    ]
  },
  "source" : "<a href=\"http://www.echofon.com/\" rel=\"nofollow\">Echofon</a>",
  "in_reply_to_status_id" : null,
  "in_reply_to_status_id_str" : null,
  "in_reply_to_user_id" : null,
  "in_reply_to_user_id_str" : null,
  "in_reply_to_screen_name" : null,
  "user" : {
    "id" : 18948541,
    "id_str" : "18948541",
    "name" : "Seth MacFarlane",
    "screen_name" : "SethMacFarlane",
    "location" : "Los Angeles",
    "description" : "The Official Twitter Page of Seth MacFarlane - new album No One Ever Tells You available now on iTunes https://t.co/gLePVn5Mho",
    "url" : "https://t.co/o4miqWAHnW",
    "entities" : {
      "url" : {
        "urls" : [
          {
            "url" : "https://t.co/o4miqWAHnW",
            "expanded_url" : "http://www.facebook.com/pages/Seth-MacFarlane/14105972607?ref=ts",
            "display_url" : "facebook.com/pages/Seth-Mac…",
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
            "url" : "https://t.co/gLePVn5Mho",
            "expanded_url" : "http://itun.es/us/Vx9p-",
            "display_url" : "itun.es/us/Vx9p-",
            "indices" : [
              103,
              126
            ]
          }
        ]
      }
    },
    "protected" : false,
    "followers_count" : 10520286,
    "friends_count" : 377,
    "listed_count" : 0,
    "created_at" : "Tue Jan 13 19:04:37 +0000 2009",
    "favourites_count" : 0,
    "utc_offset" : -25200,
    "time_zone" : "Pacific Time (US & Canada)",
    "geo_enabled" : false,
    "verified" : true,
    "statuses_count" : 5847,
    "lang" : "en",
    "contributors_enabled" : false,
    "is_translator" : false,
    "is_translation_enabled" : true,
    "profile_background_color" : "C0DEED",
    "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_tile" : false,
    "profile_image_url" : "http://pbs.twimg.com/profile_images/477598819715395585/g0lGqC_J_normal.jpeg",
    "profile_image_url_https" : "https://pbs.twimg.com/profile_images/477598819715395585/g0lGqC_J_normal.jpeg",
    "profile_link_color" : "0084B4",
    "profile_sidebar_border_color" : "C0DEED",
    "profile_sidebar_fill_color" : "DDEEF6",
    "profile_text_color" : "333333",
    "profile_use_background_image" : true,
    "has_extended_profile" : false,
    "default_profile" : true,
    "default_profile_image" : false,
    "following" : true,
    "follow_request_sent" : false,
    "notifications" : false
  },
  "geo" : null,
  "coordinates" : null,
  "place" : null,
  "contributors" : null,
  "retweeted_status" : {
    "created_at" : "Tue Aug 02 17:18:45 +0000 2016",
    "id" : 760525254489890818,
    "id_str" : "760525254489890818",
    "text" : "OH: \"All fucking dentists are in the pocket of big floss!\"",
    "truncated" : false,
    "entities" : {
      "hashtags" : [
      ],
      "symbols" : [
      ],
      "user_mentions" : [
      ],
      "urls" : [
      ]
    },
    "source" : "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>",
    "in_reply_to_status_id" : null,
    "in_reply_to_status_id_str" : null,
    "in_reply_to_user_id" : null,
    "in_reply_to_user_id_str" : null,
    "in_reply_to_screen_name" : null,
    "user" : {
      "id" : 1183041,
      "id_str" : "1183041",
      "name" : "Wil Wheaton",
      "screen_name" : "wilw",
      "location" : "Los Angeles",
      "description" : "Barrelslayer. Time Lord. Fake geek girl.  On a good day I am charming as fuck.",
      "url" : "http://t.co/UAYYOhbijM",
      "entities" : {
        "url" : {
          "urls" : [
            {
              "url" : "http://t.co/UAYYOhbijM",
              "expanded_url" : "http://wilwheaton.net/2009/02/what-to-expect-if-you-follow-me-on-twitter-or-how-im-going-to-disappoint-you-in-6-quick-steps/",
              "display_url" : "wilwheaton.net/2009/02/what-t…",
              "indices" : [
                0,
                22
              ]
            }
          ]
        },
        "description" : {
          "urls" : [
          ]
        }
      },
      "protected" : false,
      "followers_count" : 3050329,
      "friends_count" : 355,
      "listed_count" : 39190,
      "created_at" : "Wed Mar 14 21:25:33 +0000 2007",
      "favourites_count" : 557,
      "utc_offset" : -25200,
      "time_zone" : "Pacific Time (US & Canada)",
      "geo_enabled" : false,
      "verified" : true,
      "statuses_count" : 65696,
      "lang" : "en",
      "contributors_enabled" : false,
      "is_translator" : false,
      "is_translation_enabled" : false,
      "profile_background_color" : "022330",
      "profile_background_image_url" : "http://pbs.twimg.com/profile_background_images/871683408/62c85b46792dfe6bfd16420b71646cdb.png",
      "profile_background_image_url_https" : "https://pbs.twimg.com/profile_background_images/871683408/62c85b46792dfe6bfd16420b71646cdb.png",
      "profile_background_tile" : true,
      "profile_image_url" : "http://pbs.twimg.com/profile_images/660891140418236416/7zeCwT9K_normal.png",
      "profile_image_url_https" : "https://pbs.twimg.com/profile_images/660891140418236416/7zeCwT9K_normal.png",
      "profile_banner_url" : "https://pbs.twimg.com/profile_banners/1183041/1368668860",
      "profile_link_color" : "F6101E",
      "profile_sidebar_border_color" : "000000",
      "profile_sidebar_fill_color" : "C0DFEC",
      "profile_text_color" : "333333",
      "profile_use_background_image" : true,
      "has_extended_profile" : true,
      "default_profile" : false,
      "default_profile_image" : false,
      "following" : false,
      "follow_request_sent" : false,
      "notifications" : false
    },
    "geo" : null,
    "coordinates" : null,
    "place" : null,
    "contributors" : null,
    "is_quote_status" : false,
    "retweet_count" : 249,
    "favorite_count" : 1418,
    "favorited" : false,
    "retweeted" : false,
    "lang" : "en"
  },
  "is_quote_status" : false,
  "retweet_count" : 249,
  "favorite_count" : 0,
  "favorited" : false,
  "retweeted" : false,
  "lang" : "en"
}
""";

const string NORMAL_WITH_MEDIA =
"""
{
  "created_at" : "Wed Aug 03 11:18:39 +0000 2016",
  "id" : 760797019908739072,
  "id_str" : "760797019908739072",
  "text" : "Someone went and ruined the last fun thing we had left https://t.co/a9Fc65NpIn",
  "truncated" : false,
  "entities" : {
    "hashtags" : [
    ],
    "symbols" : [
    ],
    "user_mentions" : [
    ],
    "urls" : [
    ],
    "media" : [
      {
        "id" : 760796983409901568,
        "id_str" : "760796983409901568",
        "indices" : [
          55,
          78
        ],
        "media_url" : "http://pbs.twimg.com/media/Co7k01ZWAAAO7XA.jpg",
        "media_url_https" : "https://pbs.twimg.com/media/Co7k01ZWAAAO7XA.jpg",
        "url" : "https://t.co/a9Fc65NpIn",
        "display_url" : "pic.twitter.com/a9Fc65NpIn",
        "expanded_url" : "http://twitter.com/internetofshit/status/760797019908739072/photo/1",
        "type" : "photo",
        "sizes" : {
          "medium" : {
            "w" : 1200,
            "h" : 646,
            "resize" : "fit"
          },
          "small" : {
            "w" : 680,
            "h" : 366,
            "resize" : "fit"
          },
          "large" : {
            "w" : 1972,
            "h" : 1062,
            "resize" : "fit"
          },
          "thumb" : {
            "w" : 150,
            "h" : 150,
            "resize" : "crop"
          }
        }
      }
    ]
  },
  "extended_entities" : {
    "media" : [
      {
        "id" : 760796983409901568,
        "id_str" : "760796983409901568",
        "indices" : [
          55,
          78
        ],
        "media_url" : "http://pbs.twimg.com/media/Co7k01ZWAAAO7XA.jpg",
        "media_url_https" : "https://pbs.twimg.com/media/Co7k01ZWAAAO7XA.jpg",
        "url" : "https://t.co/a9Fc65NpIn",
        "display_url" : "pic.twitter.com/a9Fc65NpIn",
        "expanded_url" : "http://twitter.com/internetofshit/status/760797019908739072/photo/1",
        "type" : "photo",
        "sizes" : {
          "medium" : {
            "w" : 1200,
            "h" : 646,
            "resize" : "fit"
          },
          "small" : {
            "w" : 680,
            "h" : 366,
            "resize" : "fit"
          },
          "large" : {
            "w" : 1972,
            "h" : 1062,
            "resize" : "fit"
          },
          "thumb" : {
            "w" : 150,
            "h" : 150,
            "resize" : "crop"
          }
        }
      }
    ]
  },
  "source" : "<a href=\"https://about.twitter.com/products/tweetdeck\" rel=\"nofollow\">TweetDeck</a>",
  "in_reply_to_status_id" : null,
  "in_reply_to_status_id_str" : null,
  "in_reply_to_user_id" : null,
  "in_reply_to_user_id_str" : null,
  "in_reply_to_screen_name" : null,
  "user" : {
    "id" : 3356531254,
    "id_str" : "3356531254",
    "name" : "Internet of Shit",
    "screen_name" : "internetofshit",
    "location" : "In your stuff",
    "description" : "Obviously the best thing to do is put a chip in it. Tips: internetofshit@gmail.com / Also on FB: https://t.co/VhThiGNgOo",
    "url" : null,
    "entities" : {
      "description" : {
        "urls" : [
          {
            "url" : "https://t.co/VhThiGNgOo",
            "expanded_url" : "https://www.facebook.com/internetofshit",
            "display_url" : "facebook.com/internetofshit",
            "indices" : [
              97,
              120
            ]
          }
        ]
      }
    },
    "protected" : false,
    "followers_count" : 126017,
    "friends_count" : 92,
    "listed_count" : 1630,
    "created_at" : "Fri Jul 03 09:04:06 +0000 2015",
    "favourites_count" : 2190,
    "utc_offset" : -25200,
    "time_zone" : "Pacific Time (US & Canada)",
    "geo_enabled" : true,
    "verified" : false,
    "statuses_count" : 2254,
    "lang" : "en",
    "contributors_enabled" : false,
    "is_translator" : false,
    "is_translation_enabled" : false,
    "profile_background_color" : "C0DEED",
    "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_tile" : false,
    "profile_image_url" : "http://pbs.twimg.com/profile_images/616895706150797312/ol4PeiHz_normal.png",
    "profile_image_url_https" : "https://pbs.twimg.com/profile_images/616895706150797312/ol4PeiHz_normal.png",
    "profile_link_color" : "0084B4",
    "profile_sidebar_border_color" : "C0DEED",
    "profile_sidebar_fill_color" : "DDEEF6",
    "profile_text_color" : "333333",
    "profile_use_background_image" : true,
    "has_extended_profile" : false,
    "default_profile" : true,
    "default_profile_image" : false,
    "following" : true,
    "follow_request_sent" : false,
    "notifications" : false
  },
  "geo" : null,
  "coordinates" : null,
  "place" : null,
  "contributors" : null,
  "is_quote_status" : false,
  "retweet_count" : 103,
  "favorite_count" : 84,
  "favorited" : false,
  "retweeted" : false,
  "possibly_sensitive" : false,
  "possibly_sensitive_appealable" : false,
  "lang" : "en"
}
""";

const string NORMAL_QUOTE =
"""
{
  "created_at" : "Wed Aug 03 07:15:48 +0000 2016",
  "id" : 760735908287119360,
  "id_str" : "760735908287119360",
  "text" : "Gute Nachrichten zum Morgen: @EMMUREmusic haben die Aufnahmen zu ihrem neuen Album abgeschlossen! https://t.co/zGwh0FXMJi",
  "truncated" : false,
  "entities" : {
    "hashtags" : [
    ],
    "symbols" : [
    ],
    "user_mentions" : [
      {
        "screen_name" : "EMMUREmusic",
        "name" : "EMMURE",
        "id" : 42820699,
        "id_str" : "42820699",
        "indices" : [
          29,
          41
        ]
      }
    ],
    "urls" : [
      {
        "url" : "https://t.co/zGwh0FXMJi",
        "expanded_url" : "https://twitter.com/FrankiePalmeri/status/760334690737790976",
        "display_url" : "twitter.com/FrankiePalmeri…",
        "indices" : [
          98,
          121
        ]
      }
    ]
  },
  "source" : "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>",
  "in_reply_to_status_id" : null,
  "in_reply_to_status_id_str" : null,
  "in_reply_to_user_id" : null,
  "in_reply_to_user_id_str" : null,
  "in_reply_to_screen_name" : null,
  "user" : {
    "id" : 51725030,
    "id_str" : "51725030",
    "name" : "impericon_de",
    "screen_name" : "impericon_de",
    "location" : "Leipzig/ Germany",
    "description" : "check out http://t.co/RbUklLeWkv for further information",
    "url" : "http://t.co/RbUklLeWkv",
    "entities" : {
      "url" : {
        "urls" : [
          {
            "url" : "http://t.co/RbUklLeWkv",
            "expanded_url" : "http://www.impericon.com",
            "display_url" : "impericon.com",
            "indices" : [
              0,
              22
            ]
          }
        ]
      },
      "description" : {
        "urls" : [
          {
            "url" : "http://t.co/RbUklLeWkv",
            "expanded_url" : "http://www.impericon.com",
            "display_url" : "impericon.com",
            "indices" : [
              10,
              32
            ]
          }
        ]
      }
    },
    "protected" : false,
    "followers_count" : 8077,
    "friends_count" : 1226,
    "listed_count" : 46,
    "created_at" : "Sun Jun 28 13:07:50 +0000 2009",
    "favourites_count" : 2657,
    "utc_offset" : 7200,
    "time_zone" : "Berlin",
    "geo_enabled" : true,
    "verified" : false,
    "statuses_count" : 17025,
    "lang" : "de",
    "contributors_enabled" : false,
    "is_translator" : false,
    "is_translation_enabled" : false,
    "profile_background_color" : "611222",
    "profile_background_image_url" : "http://pbs.twimg.com/profile_background_images/868968985/73b34a4e0d724f8c8f61c06d76dcf925.jpeg",
    "profile_background_image_url_https" : "https://pbs.twimg.com/profile_background_images/868968985/73b34a4e0d724f8c8f61c06d76dcf925.jpeg",
    "profile_background_tile" : true,
    "profile_image_url" : "http://pbs.twimg.com/profile_images/1374777540/ic_germany_normal.png",
    "profile_image_url_https" : "https://pbs.twimg.com/profile_images/1374777540/ic_germany_normal.png",
    "profile_banner_url" : "https://pbs.twimg.com/profile_banners/51725030/1470217813",
    "profile_link_color" : "611222",
    "profile_sidebar_border_color" : "000000",
    "profile_sidebar_fill_color" : "DDFFCC",
    "profile_text_color" : "333333",
    "profile_use_background_image" : true,
    "has_extended_profile" : false,
    "default_profile" : false,
    "default_profile_image" : false,
    "following" : true,
    "follow_request_sent" : false,
    "notifications" : false
  },
  "geo" : null,
  "coordinates" : null,
  "place" : null,
  "contributors" : null,
  "is_quote_status" : true,
  "quoted_status_id" : 760334690737790976,
  "quoted_status_id_str" : "760334690737790976",
  "quoted_status" : {
    "created_at" : "Tue Aug 02 04:41:31 +0000 2016",
    "id" : 760334690737790976,
    "id_str" : "760334690737790976",
    "text" : "Finished tracking the record. 🖒",
    "truncated" : false,
    "entities" : {
      "hashtags" : [
      ],
      "symbols" : [
      ],
      "user_mentions" : [
      ],
      "urls" : [
      ]
    },
    "source" : "<a href=\"http://twitter.com/download/android\" rel=\"nofollow\">Twitter for Android</a>",
    "in_reply_to_status_id" : null,
    "in_reply_to_status_id_str" : null,
    "in_reply_to_user_id" : null,
    "in_reply_to_user_id_str" : null,
    "in_reply_to_screen_name" : null,
    "user" : {
      "id" : 208089519,
      "id_str" : "208089519",
      "name" : "⛧",
      "screen_name" : "FrankiePalmeri",
      "location" : "World Warrior ",
      "description" : "シャドルー                                                                    Best known as the singer of @EMMUREmusic\nFor booking/features-GodOfRue@Gmail.com\n#MVC2",
      "url" : null,
      "entities" : {
        "description" : {
          "urls" : [
          ]
        }
      },
      "protected" : false,
      "followers_count" : 6843,
      "friends_count" : 0,
      "listed_count" : 17,
      "created_at" : "Tue Oct 26 16:20:47 +0000 2010",
      "favourites_count" : 6444,
      "utc_offset" : -18000,
      "time_zone" : "Central Time (US & Canada)",
      "geo_enabled" : true,
      "verified" : true,
      "statuses_count" : 7346,
      "lang" : "en",
      "contributors_enabled" : false,
      "is_translator" : false,
      "is_translation_enabled" : false,
      "profile_background_color" : "C0DEED",
      "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme1/bg.png",
      "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme1/bg.png",
      "profile_background_tile" : false,
      "profile_image_url" : "http://pbs.twimg.com/profile_images/744425940789276672/qOmnwRUv_normal.jpg",
      "profile_image_url_https" : "https://pbs.twimg.com/profile_images/744425940789276672/qOmnwRUv_normal.jpg",
      "profile_banner_url" : "https://pbs.twimg.com/profile_banners/208089519/1466846528",
      "profile_link_color" : "0084B4",
      "profile_sidebar_border_color" : "C0DEED",
      "profile_sidebar_fill_color" : "DDEEF6",
      "profile_text_color" : "333333",
      "profile_use_background_image" : true,
      "has_extended_profile" : false,
      "default_profile" : true,
      "default_profile_image" : false,
      "following" : false,
      "follow_request_sent" : false,
      "notifications" : false
    },
    "geo" : null,
    "coordinates" : null,
    "place" : {
      "id" : "3b77caf94bfc81fe",
      "url" : "https://api.twitter.com/1.1/geo/id/3b77caf94bfc81fe.json",
      "place_type" : "city",
      "name" : "Los Angeles",
      "full_name" : "Los Angeles, CA",
      "country_code" : "US",
      "country" : "United States",
      "contained_within" : [
      ],
      "bounding_box" : {
        "type" : "Polygon",
        "coordinates" : [
          [
            [
              -118.668404,
              33.704537999999999
            ],
            [
              -118.15540900000001,
              33.704537999999999
            ],
            [
              -118.15540900000001,
              34.337040999999999
            ],
            [
              -118.668404,
              34.337040999999999
            ]
          ]
        ]
      },
      "attributes" : {
      }
    },
    "contributors" : null,
    "is_quote_status" : false,
    "retweet_count" : 38,
    "favorite_count" : 136,
    "favorited" : false,
    "retweeted" : false,
    "lang" : "en"
  },
  "retweet_count" : 1,
  "favorite_count" : 7,
  "favorited" : false,
  "retweeted" : false,
  "possibly_sensitive" : false,
  "possibly_sensitive_appealable" : false,
  "lang" : "de"
}
""";

const string QUOTE_WITH_MEDIA =
"""
{
  "created_at" : "Wed Aug 03 09:48:12 +0000 2016",
  "id" : 760774260315004928,
  "id_str" : "760774260315004928",
  "text" : "Wir sind am Wochenende übrigens wieder beim Wacken Open Air am Start - wer noch? https://t.co/xEEtAO37jF",
  "truncated" : false,
  "entities" : {
    "hashtags" : [
    ],
    "symbols" : [
    ],
    "user_mentions" : [
    ],
    "urls" : [
      {
        "url" : "https://t.co/xEEtAO37jF",
        "expanded_url" : "https://twitter.com/Wacken/status/760774020631556096",
        "display_url" : "twitter.com/Wacken/status/…",
        "indices" : [
          81,
          104
        ]
      }
    ]
  },
  "source" : "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>",
  "in_reply_to_status_id" : null,
  "in_reply_to_status_id_str" : null,
  "in_reply_to_user_id" : null,
  "in_reply_to_user_id_str" : null,
  "in_reply_to_screen_name" : null,
  "user" : {
    "id" : 51725030,
    "id_str" : "51725030",
    "name" : "impericon_de",
    "screen_name" : "impericon_de",
    "location" : "Leipzig/ Germany",
    "description" : "check out http://t.co/RbUklLeWkv for further information",
    "url" : "http://t.co/RbUklLeWkv",
    "entities" : {
      "url" : {
        "urls" : [
          {
            "url" : "http://t.co/RbUklLeWkv",
            "expanded_url" : "http://www.impericon.com",
            "display_url" : "impericon.com",
            "indices" : [
              0,
              22
            ]
          }
        ]
      },
      "description" : {
        "urls" : [
          {
            "url" : "http://t.co/RbUklLeWkv",
            "expanded_url" : "http://www.impericon.com",
            "display_url" : "impericon.com",
            "indices" : [
              10,
              32
            ]
          }
        ]
      }
    },
    "protected" : false,
    "followers_count" : 8077,
    "friends_count" : 1226,
    "listed_count" : 46,
    "created_at" : "Sun Jun 28 13:07:50 +0000 2009",
    "favourites_count" : 2657,
    "utc_offset" : 7200,
    "time_zone" : "Berlin",
    "geo_enabled" : true,
    "verified" : false,
    "statuses_count" : 17025,
    "lang" : "de",
    "contributors_enabled" : false,
    "is_translator" : false,
    "is_translation_enabled" : false,
    "profile_background_color" : "611222",
    "profile_background_image_url" : "http://pbs.twimg.com/profile_background_images/868968985/73b34a4e0d724f8c8f61c06d76dcf925.jpeg",
    "profile_background_image_url_https" : "https://pbs.twimg.com/profile_background_images/868968985/73b34a4e0d724f8c8f61c06d76dcf925.jpeg",
    "profile_background_tile" : true,
    "profile_image_url" : "http://pbs.twimg.com/profile_images/1374777540/ic_germany_normal.png",
    "profile_image_url_https" : "https://pbs.twimg.com/profile_images/1374777540/ic_germany_normal.png",
    "profile_banner_url" : "https://pbs.twimg.com/profile_banners/51725030/1470217813",
    "profile_link_color" : "611222",
    "profile_sidebar_border_color" : "000000",
    "profile_sidebar_fill_color" : "DDFFCC",
    "profile_text_color" : "333333",
    "profile_use_background_image" : true,
    "has_extended_profile" : false,
    "default_profile" : false,
    "default_profile_image" : false,
    "following" : true,
    "follow_request_sent" : false,
    "notifications" : false
  },
  "geo" : null,
  "coordinates" : null,
  "place" : null,
  "contributors" : null,
  "is_quote_status" : true,
  "quoted_status_id" : 760774020631556096,
  "quoted_status_id_str" : "760774020631556096",
  "quoted_status" : {
    "created_at" : "Wed Aug 03 09:47:15 +0000 2016",
    "id" : 760774020631556096,
    "id_str" : "760774020631556096",
    "text" : "Business as usual. Work on main stages continues. All is well.  #Wacken https://t.co/6oNpNgSFmx",
    "truncated" : false,
    "entities" : {
      "hashtags" : [
        {
          "text" : "Wacken",
          "indices" : [
            64,
            71
          ]
        }
      ],
      "symbols" : [
      ],
      "user_mentions" : [
      ],
      "urls" : [
      ],
      "media" : [
        {
          "id" : 760773998955421696,
          "id_str" : "760773998955421696",
          "indices" : [
            72,
            95
          ],
          "media_url" : "http://pbs.twimg.com/media/Co7P69oXYAAcTYR.jpg",
          "media_url_https" : "https://pbs.twimg.com/media/Co7P69oXYAAcTYR.jpg",
          "url" : "https://t.co/6oNpNgSFmx",
          "display_url" : "pic.twitter.com/6oNpNgSFmx",
          "expanded_url" : "http://twitter.com/Wacken/status/760774020631556096/photo/1",
          "type" : "photo",
          "sizes" : {
            "medium" : {
              "w" : 1200,
              "h" : 675,
              "resize" : "fit"
            },
            "small" : {
              "w" : 680,
              "h" : 383,
              "resize" : "fit"
            },
            "large" : {
              "w" : 2048,
              "h" : 1152,
              "resize" : "fit"
            },
            "thumb" : {
              "w" : 150,
              "h" : 150,
              "resize" : "crop"
            }
          }
        }
      ]
    },
    "extended_entities" : {
      "media" : [
        {
          "id" : 760773998955421696,
          "id_str" : "760773998955421696",
          "indices" : [
            72,
            95
          ],
          "media_url" : "http://pbs.twimg.com/media/Co7P69oXYAAcTYR.jpg",
          "media_url_https" : "https://pbs.twimg.com/media/Co7P69oXYAAcTYR.jpg",
          "url" : "https://t.co/6oNpNgSFmx",
          "display_url" : "pic.twitter.com/6oNpNgSFmx",
          "expanded_url" : "http://twitter.com/Wacken/status/760774020631556096/photo/1",
          "type" : "photo",
          "sizes" : {
            "medium" : {
              "w" : 1200,
              "h" : 675,
              "resize" : "fit"
            },
            "small" : {
              "w" : 680,
              "h" : 383,
              "resize" : "fit"
            },
            "large" : {
              "w" : 2048,
              "h" : 1152,
              "resize" : "fit"
            },
            "thumb" : {
              "w" : 150,
              "h" : 150,
              "resize" : "crop"
            }
          }
        }
      ]
    },
    "source" : "<a href=\"http://twitter.com/download/android\" rel=\"nofollow\">Twitter for Android</a>",
    "in_reply_to_status_id" : null,
    "in_reply_to_status_id_str" : null,
    "in_reply_to_user_id" : null,
    "in_reply_to_user_id_str" : null,
    "in_reply_to_screen_name" : null,
    "user" : {
      "id" : 15475088,
      "id_str" : "15475088",
      "name" : "Wacken Open Air",
      "screen_name" : "Wacken",
      "location" : "Wacken, Germany",
      "description" : "Welcome to the official W:O:A Twitter account!   Impressum: https://t.co/0Nvmi1UOVI",
      "url" : "http://t.co/eklJ4O4IqD",
      "entities" : {
        "url" : {
          "urls" : [
            {
              "url" : "http://t.co/eklJ4O4IqD",
              "expanded_url" : "http://www.wacken.com/",
              "display_url" : "wacken.com",
              "indices" : [
                0,
                22
              ]
            }
          ]
        },
        "description" : {
          "urls" : [
            {
              "url" : "https://t.co/0Nvmi1UOVI",
              "expanded_url" : "http://bit.ly/1xx5ODO",
              "display_url" : "bit.ly/1xx5ODO",
              "indices" : [
                60,
                83
              ]
            }
          ]
        }
      },
      "protected" : false,
      "followers_count" : 61074,
      "friends_count" : 259,
      "listed_count" : 602,
      "created_at" : "Thu Jul 17 22:46:52 +0000 2008",
      "favourites_count" : 314,
      "utc_offset" : 7200,
      "time_zone" : "Ljubljana",
      "geo_enabled" : true,
      "verified" : false,
      "statuses_count" : 3660,
      "lang" : "de",
      "contributors_enabled" : false,
      "is_translator" : false,
      "is_translation_enabled" : false,
      "profile_background_color" : "000000",
      "profile_background_image_url" : "http://pbs.twimg.com/profile_background_images/436070844293345280/3EWufvsr.jpeg",
      "profile_background_image_url_https" : "https://pbs.twimg.com/profile_background_images/436070844293345280/3EWufvsr.jpeg",
      "profile_background_tile" : false,
      "profile_image_url" : "http://pbs.twimg.com/profile_images/627856569699598340/OsQ1UOLl_normal.png",
      "profile_image_url_https" : "https://pbs.twimg.com/profile_images/627856569699598340/OsQ1UOLl_normal.png",
      "profile_banner_url" : "https://pbs.twimg.com/profile_banners/15475088/1438527965",
      "profile_link_color" : "5BD006",
      "profile_sidebar_border_color" : "000000",
      "profile_sidebar_fill_color" : "EFEFEF",
      "profile_text_color" : "333333",
      "profile_use_background_image" : true,
      "has_extended_profile" : false,
      "default_profile" : false,
      "default_profile_image" : false,
      "following" : false,
      "follow_request_sent" : false,
      "notifications" : false
    },
    "geo" : null,
    "coordinates" : null,
    "place" : {
      "id" : "b442982971a0c2b5",
      "url" : "https://api.twitter.com/1.1/geo/id/b442982971a0c2b5.json",
      "place_type" : "city",
      "name" : "Wacken",
      "full_name" : "Wacken, Deutschland",
      "country_code" : "DE",
      "country" : "Germany",
      "contained_within" : [
      ],
      "bounding_box" : {
        "type" : "Polygon",
        "coordinates" : [
          [
            [
              9.3435539999999992,
              54.009207000000004
            ],
            [
              9.4074019999999994,
              54.009207000000004
            ],
            [
              9.4074019999999994,
              54.038155000000003
            ],
            [
              9.3435539999999992,
              54.038155000000003
            ]
          ]
        ]
      },
      "attributes" : {
      }
    },
    "contributors" : null,
    "is_quote_status" : false,
    "retweet_count" : 7,
    "favorite_count" : 15,
    "favorited" : false,
    "retweeted" : false,
    "possibly_sensitive" : false,
    "possibly_sensitive_appealable" : false,
    "lang" : "en"
  },
  "retweet_count" : 0,
  "favorite_count" : 0,
  "favorited" : false,
  "retweeted" : false,
  "possibly_sensitive" : false,
  "possibly_sensitive_appealable" : false,
  "lang" : "de"
}
""";
const string RETWEET_WITH_MEDIA =
"""

{
  "created_at" : "Wed Aug 03 01:22:42 +0000 2016",
  "id" : 760647046835544064,
  "id_str" : "760647046835544064",
  "text" : "RT @shutupmikeginn: Hey @ScottAdamsSays, @eedrk &amp; I are big fans so we recut Dilbert to deal with contemporary social issues! Please RT! ht…",
  "truncated" : false,
  "entities" : {
    "hashtags" : [
    ],
    "symbols" : [
    ],
    "user_mentions" : [
      {
        "screen_name" : "shutupmikeginn",
        "name" : "shut up, mike",
        "id" : 246394886,
        "id_str" : "246394886",
        "indices" : [
          3,
          18
        ]
      },
      {
        "screen_name" : "ScottAdamsSays",
        "name" : "Scott Adams",
        "id" : 2853461537,
        "id_str" : "2853461537",
        "indices" : [
          24,
          39
        ]
      },
      {
        "screen_name" : "eedrk",
        "name" : "derek",
        "id" : 1350600582,
        "id_str" : "1350600582",
        "indices" : [
          41,
          47
        ]
      }
    ],
    "urls" : [
    ],
    "media" : [
      {
        "id" : 760627464456462336,
        "id_str" : "760627464456462336",
        "indices" : [
          143,
          144
        ],
        "media_url" : "http://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
        "media_url_https" : "https://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
        "url" : "https://t.co/Dth5YBHXeu",
        "display_url" : "pic.twitter.com/Dth5YBHXeu",
        "expanded_url" : "http://twitter.com/shutupmikeginn/status/760628917837312000/video/1",
        "type" : "photo",
        "sizes" : {
          "medium" : {
            "w" : 600,
            "h" : 411,
            "resize" : "fit"
          },
          "thumb" : {
            "w" : 150,
            "h" : 150,
            "resize" : "crop"
          },
          "large" : {
            "w" : 700,
            "h" : 480,
            "resize" : "fit"
          },
          "small" : {
            "w" : 340,
            "h" : 233,
            "resize" : "fit"
          }
        },
        "source_status_id" : 760628917837312000,
        "source_status_id_str" : "760628917837312000",
        "source_user_id" : 246394886,
        "source_user_id_str" : "246394886"
      }
    ]
  },
  "extended_entities" : {
    "media" : [
      {
        "id" : 760627464456462336,
        "id_str" : "760627464456462336",
        "indices" : [
          143,
          144
        ],
        "media_url" : "http://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
        "media_url_https" : "https://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
        "url" : "https://t.co/Dth5YBHXeu",
        "display_url" : "pic.twitter.com/Dth5YBHXeu",
        "expanded_url" : "http://twitter.com/shutupmikeginn/status/760628917837312000/video/1",
        "type" : "video",
        "sizes" : {
          "medium" : {
            "w" : 600,
            "h" : 411,
            "resize" : "fit"
          },
          "thumb" : {
            "w" : 150,
            "h" : 150,
            "resize" : "crop"
          },
          "large" : {
            "w" : 700,
            "h" : 480,
            "resize" : "fit"
          },
          "small" : {
            "w" : 340,
            "h" : 233,
            "resize" : "fit"
          }
        },
        "source_status_id" : 760628917837312000,
        "source_status_id_str" : "760628917837312000",
        "source_user_id" : 246394886,
        "source_user_id_str" : "246394886",
        "video_info" : {
          "aspect_ratio" : [
            35,
            24
          ],
          "duration_millis" : 50017,
          "variants" : [
            {
              "content_type" : "application/dash+xml",
              "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/pl/WgyGZ2bR67CZKbIe.mpd"
            },
            {
              "bitrate" : 320000,
              "content_type" : "video/mp4",
              "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/vid/262x180/bMwQb2LGoymiuNBF.mp4"
            },
            {
              "content_type" : "application/x-mpegURL",
              "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/pl/WgyGZ2bR67CZKbIe.m3u8"
            },
            {
              "bitrate" : 832000,
              "content_type" : "video/mp4",
              "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/vid/524x360/akoT29AzRB-K7Tvf.mp4"
            }
          ]
        },
        "additional_media_info" : {
          "monetizable" : false,
          "source_user" : {
            "id" : 246394886,
            "id_str" : "246394886",
            "name" : "shut up, mike",
            "screen_name" : "shutupmikeginn",
            "location" : "Los Angeles, CA",
            "description" : "writer (left handed) // shutupmikeginn @ gmail . com // @midnight",
            "url" : "https://t.co/JLpcO66Txj",
            "entities" : {
              "url" : {
                "urls" : [
                  {
                    "url" : "https://t.co/JLpcO66Txj",
                    "expanded_url" : "http://www.shutupmikeginn.com",
                    "display_url" : "shutupmikeginn.com",
                    "indices" : [
                      0,
                      23
                    ]
                  }
                ]
              },
              "description" : {
                "urls" : [
                ]
              }
            },
            "protected" : false,
            "followers_count" : 155598,
            "friends_count" : 757,
            "listed_count" : 1675,
            "created_at" : "Wed Feb 02 18:21:51 +0000 2011",
            "favourites_count" : 58329,
            "utc_offset" : null,
            "time_zone" : null,
            "geo_enabled" : false,
            "verified" : false,
            "statuses_count" : 9001,
            "lang" : "en",
            "contributors_enabled" : false,
            "is_translator" : false,
            "is_translation_enabled" : false,
            "profile_background_color" : "000000",
            "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme15/bg.png",
            "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme15/bg.png",
            "profile_background_tile" : false,
            "profile_image_url" : "http://pbs.twimg.com/profile_images/523668808020422656/szD5CZyb_normal.jpeg",
            "profile_image_url_https" : "https://pbs.twimg.com/profile_images/523668808020422656/szD5CZyb_normal.jpeg",
            "profile_banner_url" : "https://pbs.twimg.com/profile_banners/246394886/1460523073",
            "profile_link_color" : "4A913C",
            "profile_sidebar_border_color" : "000000",
            "profile_sidebar_fill_color" : "000000",
            "profile_text_color" : "000000",
            "profile_use_background_image" : false,
            "has_extended_profile" : true,
            "default_profile" : false,
            "default_profile_image" : false,
            "following" : false,
            "follow_request_sent" : false,
            "notifications" : false
          }
        }
      }
    ]
  },
  "source" : "<a href=\"http://twitter.com/download/iphone\" rel=\"nofollow\">Twitter for iPhone</a>",
  "in_reply_to_status_id" : null,
  "in_reply_to_status_id_str" : null,
  "in_reply_to_user_id" : null,
  "in_reply_to_user_id_str" : null,
  "in_reply_to_screen_name" : null,
  "user" : {
    "id" : 21369740,
    "id_str" : "21369740",
    "name" : "Rob DenBleyker",
    "screen_name" : "RobDenBleyker",
    "location" : "Dallas",
    "description" : "I'm not Rob Dyrdek. Don't follow me.",
    "url" : "https://t.co/5jh1OQTAOO",
    "entities" : {
      "url" : {
        "urls" : [
          {
            "url" : "https://t.co/5jh1OQTAOO",
            "expanded_url" : "http://www.explosm.net",
            "display_url" : "explosm.net",
            "indices" : [
              0,
              23
            ]
          }
        ]
      },
      "description" : {
        "urls" : [
        ]
      }
    },
    "protected" : false,
    "followers_count" : 126457,
    "friends_count" : 800,
    "listed_count" : 1284,
    "created_at" : "Fri Feb 20 03:26:24 +0000 2009",
    "favourites_count" : 1452,
    "utc_offset" : -18000,
    "time_zone" : "Central Time (US & Canada)",
    "geo_enabled" : true,
    "verified" : false,
    "statuses_count" : 8088,
    "lang" : "en",
    "contributors_enabled" : false,
    "is_translator" : false,
    "is_translation_enabled" : false,
    "profile_background_color" : "49585E",
    "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_tile" : false,
    "profile_image_url" : "http://pbs.twimg.com/profile_images/751256809873281024/-FuDkY2p_normal.jpg",
    "profile_image_url_https" : "https://pbs.twimg.com/profile_images/751256809873281024/-FuDkY2p_normal.jpg",
    "profile_link_color" : "0C90F5",
    "profile_sidebar_border_color" : "C0DEED",
    "profile_sidebar_fill_color" : "DDEEF6",
    "profile_text_color" : "333333",
    "profile_use_background_image" : false,
    "has_extended_profile" : false,
    "default_profile" : false,
    "default_profile_image" : false,
    "following" : true,
    "follow_request_sent" : false,
    "notifications" : false
  },
  "geo" : null,
  "coordinates" : null,
  "place" : null,
  "contributors" : null,
  "retweeted_status" : {
    "created_at" : "Wed Aug 03 00:10:40 +0000 2016",
    "id" : 760628917837312000,
    "id_str" : "760628917837312000",
    "text" : "Hey @ScottAdamsSays, @eedrk &amp; I are big fans so we recut Dilbert to deal with contemporary social issues! Please RT! https://t.co/Dth5YBHXeu",
    "truncated" : false,
    "entities" : {
      "hashtags" : [
      ],
      "symbols" : [
      ],
      "user_mentions" : [
        {
          "screen_name" : "ScottAdamsSays",
          "name" : "Scott Adams",
          "id" : 2853461537,
          "id_str" : "2853461537",
          "indices" : [
            4,
            19
          ]
        },
        {
          "screen_name" : "eedrk",
          "name" : "derek",
          "id" : 1350600582,
          "id_str" : "1350600582",
          "indices" : [
            21,
            27
          ]
        }
      ],
      "urls" : [
      ],
      "media" : [
        {
          "id" : 760627464456462336,
          "id_str" : "760627464456462336",
          "indices" : [
            121,
            144
          ],
          "media_url" : "http://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
          "media_url_https" : "https://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
          "url" : "https://t.co/Dth5YBHXeu",
          "display_url" : "pic.twitter.com/Dth5YBHXeu",
          "expanded_url" : "http://twitter.com/shutupmikeginn/status/760628917837312000/video/1",
          "type" : "photo",
          "sizes" : {
            "medium" : {
              "w" : 600,
              "h" : 411,
              "resize" : "fit"
            },
            "thumb" : {
              "w" : 150,
              "h" : 150,
              "resize" : "crop"
            },
            "large" : {
              "w" : 700,
              "h" : 480,
              "resize" : "fit"
            },
            "small" : {
              "w" : 340,
              "h" : 233,
              "resize" : "fit"
            }
          }
        }
      ]
    },
    "extended_entities" : {
      "media" : [
        {
          "id" : 760627464456462336,
          "id_str" : "760627464456462336",
          "indices" : [
            121,
            144
          ],
          "media_url" : "http://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
          "media_url_https" : "https://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
          "url" : "https://t.co/Dth5YBHXeu",
          "display_url" : "pic.twitter.com/Dth5YBHXeu",
          "expanded_url" : "http://twitter.com/shutupmikeginn/status/760628917837312000/video/1",
          "type" : "video",
          "sizes" : {
            "medium" : {
              "w" : 600,
              "h" : 411,
              "resize" : "fit"
            },
            "thumb" : {
              "w" : 150,
              "h" : 150,
              "resize" : "crop"
            },
            "large" : {
              "w" : 700,
              "h" : 480,
              "resize" : "fit"
            },
            "small" : {
              "w" : 340,
              "h" : 233,
              "resize" : "fit"
            }
          },
          "video_info" : {
            "aspect_ratio" : [
              35,
              24
            ],
            "duration_millis" : 50017,
            "variants" : [
              {
                "content_type" : "application/dash+xml",
                "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/pl/WgyGZ2bR67CZKbIe.mpd"
              },
              {
                "bitrate" : 320000,
                "content_type" : "video/mp4",
                "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/vid/262x180/bMwQb2LGoymiuNBF.mp4"
              },
              {
                "content_type" : "application/x-mpegURL",
                "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/pl/WgyGZ2bR67CZKbIe.m3u8"
              },
              {
                "bitrate" : 832000,
                "content_type" : "video/mp4",
                "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/vid/524x360/akoT29AzRB-K7Tvf.mp4"
              }
            ]
          },
          "additional_media_info" : {
            "monetizable" : false
          }
        }
      ]
    },
    "source" : "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>",
    "in_reply_to_status_id" : null,
    "in_reply_to_status_id_str" : null,
    "in_reply_to_user_id" : null,
    "in_reply_to_user_id_str" : null,
    "in_reply_to_screen_name" : null,
    "user" : {
      "id" : 246394886,
      "id_str" : "246394886",
      "name" : "shut up, mike",
      "screen_name" : "shutupmikeginn",
      "location" : "Los Angeles, CA",
      "description" : "writer (left handed) // shutupmikeginn @ gmail . com // @midnight",
      "url" : "https://t.co/JLpcO66Txj",
      "entities" : {
        "url" : {
          "urls" : [
            {
              "url" : "https://t.co/JLpcO66Txj",
              "expanded_url" : "http://www.shutupmikeginn.com",
              "display_url" : "shutupmikeginn.com",
              "indices" : [
                0,
                23
              ]
            }
          ]
        },
        "description" : {
          "urls" : [
          ]
        }
      },
      "protected" : false,
      "followers_count" : 155598,
      "friends_count" : 757,
      "listed_count" : 1675,
      "created_at" : "Wed Feb 02 18:21:51 +0000 2011",
      "favourites_count" : 58329,
      "utc_offset" : null,
      "time_zone" : null,
      "geo_enabled" : false,
      "verified" : false,
      "statuses_count" : 9001,
      "lang" : "en",
      "contributors_enabled" : false,
      "is_translator" : false,
      "is_translation_enabled" : false,
      "profile_background_color" : "000000",
      "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme15/bg.png",
      "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme15/bg.png",
      "profile_background_tile" : false,
      "profile_image_url" : "http://pbs.twimg.com/profile_images/523668808020422656/szD5CZyb_normal.jpeg",
      "profile_image_url_https" : "https://pbs.twimg.com/profile_images/523668808020422656/szD5CZyb_normal.jpeg",
      "profile_banner_url" : "https://pbs.twimg.com/profile_banners/246394886/1460523073",
      "profile_link_color" : "4A913C",
      "profile_sidebar_border_color" : "000000",
      "profile_sidebar_fill_color" : "000000",
      "profile_text_color" : "000000",
      "profile_use_background_image" : false,
      "has_extended_profile" : true,
      "default_profile" : false,
      "default_profile_image" : false,
      "following" : false,
      "follow_request_sent" : false,
      "notifications" : false
    },
    "geo" : null,
    "coordinates" : null,
    "place" : null,
    "contributors" : null,
    "is_quote_status" : false,
    "retweet_count" : 128,
    "favorite_count" : 523,
    "favorited" : false,
    "retweeted" : false,
    "possibly_sensitive" : false,
    "possibly_sensitive_appealable" : false,
    "lang" : "en"
  },
  "is_quote_status" : false,
  "retweet_count" : 128,
  "favorite_count" : 0,
  "favorited" : false,
  "retweeted" : false,
  "possibly_sensitive" : false,
  "possibly_sensitive_appealable" : false,
  "lang" : "en"
}
""";

const string EMPTY_TWEET_WITH_MEDIA =
"""
{
  "created_at" : "Wed Aug 03 02:48:12 +0000 2016",
  "id" : 760668562323189761,
  "id_str" : "760668562323189761",
  "text" : "https://t.co/ffI4jeND7m",
  "truncated" : false,
  "entities" : {
    "hashtags" : [
    ],
    "symbols" : [
    ],
    "user_mentions" : [
    ],
    "urls" : [
    ],
    "media" : [
      {
        "id" : 760668555239010304,
        "id_str" : "760668555239010304",
        "indices" : [
          0,
          23
        ],
        "media_url" : "http://pbs.twimg.com/media/Co5wBVLUsAASfCW.jpg",
        "media_url_https" : "https://pbs.twimg.com/media/Co5wBVLUsAASfCW.jpg",
        "url" : "https://t.co/ffI4jeND7m",
        "display_url" : "pic.twitter.com/ffI4jeND7m",
        "expanded_url" : "http://twitter.com/RobDenBleyker/status/760668562323189761/photo/1",
        "type" : "photo",
        "sizes" : {
          "large" : {
            "w" : 820,
            "h" : 300,
            "resize" : "fit"
          },
          "small" : {
            "w" : 680,
            "h" : 249,
            "resize" : "fit"
          },
          "medium" : {
            "w" : 820,
            "h" : 300,
            "resize" : "fit"
          },
          "thumb" : {
            "w" : 150,
            "h" : 150,
            "resize" : "crop"
          }
        }
      }
    ]
  },
  "extended_entities" : {
    "media" : [
      {
        "id" : 760668555239010304,
        "id_str" : "760668555239010304",
        "indices" : [
          0,
          23
        ],
        "media_url" : "http://pbs.twimg.com/media/Co5wBVLUsAASfCW.jpg",
        "media_url_https" : "https://pbs.twimg.com/media/Co5wBVLUsAASfCW.jpg",
        "url" : "https://t.co/ffI4jeND7m",
        "display_url" : "pic.twitter.com/ffI4jeND7m",
        "expanded_url" : "http://twitter.com/RobDenBleyker/status/760668562323189761/photo/1",
        "type" : "photo",
        "sizes" : {
          "large" : {
            "w" : 820,
            "h" : 300,
            "resize" : "fit"
          },
          "small" : {
            "w" : 680,
            "h" : 249,
            "resize" : "fit"
          },
          "medium" : {
            "w" : 820,
            "h" : 300,
            "resize" : "fit"
          },
          "thumb" : {
            "w" : 150,
            "h" : 150,
            "resize" : "crop"
          }
        }
      }
    ]
  },
  "source" : "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>",
  "in_reply_to_status_id" : null,
  "in_reply_to_status_id_str" : null,
  "in_reply_to_user_id" : null,
  "in_reply_to_user_id_str" : null,
  "in_reply_to_screen_name" : null,
  "user" : {
    "id" : 21369740,
    "id_str" : "21369740",
    "name" : "Rob DenBleyker",
    "screen_name" : "RobDenBleyker",
    "location" : "Dallas",
    "description" : "I'm not Rob Dyrdek. Don't follow me.",
    "url" : "https://t.co/5jh1OQTAOO",
    "entities" : {
      "url" : {
        "urls" : [
          {
            "url" : "https://t.co/5jh1OQTAOO",
            "expanded_url" : "http://www.explosm.net",
            "display_url" : "explosm.net",
            "indices" : [
              0,
              23
            ]
          }
        ]
      },
      "description" : {
        "urls" : [
        ]
      }
    },
    "protected" : false,
    "followers_count" : 126457,
    "friends_count" : 800,
    "listed_count" : 1284,
    "created_at" : "Fri Feb 20 03:26:24 +0000 2009",
    "favourites_count" : 1452,
    "utc_offset" : -18000,
    "time_zone" : "Central Time (US & Canada)",
    "geo_enabled" : true,
    "verified" : false,
    "statuses_count" : 8088,
    "lang" : "en",
    "contributors_enabled" : false,
    "is_translator" : false,
    "is_translation_enabled" : false,
    "profile_background_color" : "49585E",
    "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_tile" : false,
    "profile_image_url" : "http://pbs.twimg.com/profile_images/751256809873281024/-FuDkY2p_normal.jpg",
    "profile_image_url_https" : "https://pbs.twimg.com/profile_images/751256809873281024/-FuDkY2p_normal.jpg",
    "profile_link_color" : "0C90F5",
    "profile_sidebar_border_color" : "C0DEED",
    "profile_sidebar_fill_color" : "DDEEF6",
    "profile_text_color" : "333333",
    "profile_use_background_image" : false,
    "has_extended_profile" : false,
    "default_profile" : false,
    "default_profile_image" : false,
    "following" : true,
    "follow_request_sent" : false,
    "notifications" : false
  },
  "geo" : null,
  "coordinates" : null,
  "place" : null,
  "contributors" : null,
  "is_quote_status" : false,
  "retweet_count" : 90,
  "favorite_count" : 238,
  "favorited" : false,
  "retweeted" : false,
  "possibly_sensitive" : false,
  "possibly_sensitive_appealable" : false,
  "lang" : "und"
}
""";

const string EMPTY_RETWEET_WITH_MEDIA =
"""

{
  "created_at" : "Wed Aug 03 01:22:42 +0000 2016",
  "id" : 760647046835544064,
  "id_str" : "760647046835544064",
  "text" : "RT @shutupmikeginn: Hey @ScottAdamsSays, @eedrk &amp; I are big fans so we recut Dilbert to deal with contemporary social issues! Please RT! ht…",
  "truncated" : false,
  "entities" : {
    "hashtags" : [
    ],
    "symbols" : [
    ],
    "user_mentions" : [
      {
        "screen_name" : "shutupmikeginn",
        "name" : "shut up, mike",
        "id" : 246394886,
        "id_str" : "246394886",
        "indices" : [
          3,
          18
        ]
      },
      {
        "screen_name" : "ScottAdamsSays",
        "name" : "Scott Adams",
        "id" : 2853461537,
        "id_str" : "2853461537",
        "indices" : [
          24,
          39
        ]
      },
      {
        "screen_name" : "eedrk",
        "name" : "derek",
        "id" : 1350600582,
        "id_str" : "1350600582",
        "indices" : [
          41,
          47
        ]
      }
    ],
    "urls" : [
    ],
    "media" : [
      {
        "id" : 760627464456462336,
        "id_str" : "760627464456462336",
        "indices" : [
          143,
          144
        ],
        "media_url" : "http://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
        "media_url_https" : "https://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
        "url" : "https://t.co/Dth5YBHXeu",
        "display_url" : "pic.twitter.com/Dth5YBHXeu",
        "expanded_url" : "http://twitter.com/shutupmikeginn/status/760628917837312000/video/1",
        "type" : "photo",
        "sizes" : {
          "medium" : {
            "w" : 600,
            "h" : 411,
            "resize" : "fit"
          },
          "thumb" : {
            "w" : 150,
            "h" : 150,
            "resize" : "crop"
          },
          "large" : {
            "w" : 700,
            "h" : 480,
            "resize" : "fit"
          },
          "small" : {
            "w" : 340,
            "h" : 233,
            "resize" : "fit"
          }
        },
        "source_status_id" : 760628917837312000,
        "source_status_id_str" : "760628917837312000",
        "source_user_id" : 246394886,
        "source_user_id_str" : "246394886"
      }
    ]
  },
  "extended_entities" : {
    "media" : [
      {
        "id" : 760627464456462336,
        "id_str" : "760627464456462336",
        "indices" : [
          143,
          144
        ],
        "media_url" : "http://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
        "media_url_https" : "https://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
        "url" : "https://t.co/Dth5YBHXeu",
        "display_url" : "pic.twitter.com/Dth5YBHXeu",
        "expanded_url" : "http://twitter.com/shutupmikeginn/status/760628917837312000/video/1",
        "type" : "video",
        "sizes" : {
          "medium" : {
            "w" : 600,
            "h" : 411,
            "resize" : "fit"
          },
          "thumb" : {
            "w" : 150,
            "h" : 150,
            "resize" : "crop"
          },
          "large" : {
            "w" : 700,
            "h" : 480,
            "resize" : "fit"
          },
          "small" : {
            "w" : 340,
            "h" : 233,
            "resize" : "fit"
          }
        },
        "source_status_id" : 760628917837312000,
        "source_status_id_str" : "760628917837312000",
        "source_user_id" : 246394886,
        "source_user_id_str" : "246394886",
        "video_info" : {
          "aspect_ratio" : [
            35,
            24
          ],
          "duration_millis" : 50017,
          "variants" : [
            {
              "content_type" : "application/dash+xml",
              "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/pl/WgyGZ2bR67CZKbIe.mpd"
            },
            {
              "bitrate" : 320000,
              "content_type" : "video/mp4",
              "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/vid/262x180/bMwQb2LGoymiuNBF.mp4"
            },
            {
              "content_type" : "application/x-mpegURL",
              "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/pl/WgyGZ2bR67CZKbIe.m3u8"
            },
            {
              "bitrate" : 832000,
              "content_type" : "video/mp4",
              "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/vid/524x360/akoT29AzRB-K7Tvf.mp4"
            }
          ]
        },
        "additional_media_info" : {
          "monetizable" : false,
          "source_user" : {
            "id" : 246394886,
            "id_str" : "246394886",
            "name" : "shut up, mike",
            "screen_name" : "shutupmikeginn",
            "location" : "Los Angeles, CA",
            "description" : "writer (left handed) // shutupmikeginn @ gmail . com // @midnight",
            "url" : "https://t.co/JLpcO66Txj",
            "entities" : {
              "url" : {
                "urls" : [
                  {
                    "url" : "https://t.co/JLpcO66Txj",
                    "expanded_url" : "http://www.shutupmikeginn.com",
                    "display_url" : "shutupmikeginn.com",
                    "indices" : [
                      0,
                      23
                    ]
                  }
                ]
              },
              "description" : {
                "urls" : [
                ]
              }
            },
            "protected" : false,
            "followers_count" : 155598,
            "friends_count" : 757,
            "listed_count" : 1675,
            "created_at" : "Wed Feb 02 18:21:51 +0000 2011",
            "favourites_count" : 58329,
            "utc_offset" : null,
            "time_zone" : null,
            "geo_enabled" : false,
            "verified" : false,
            "statuses_count" : 9001,
            "lang" : "en",
            "contributors_enabled" : false,
            "is_translator" : false,
            "is_translation_enabled" : false,
            "profile_background_color" : "000000",
            "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme15/bg.png",
            "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme15/bg.png",
            "profile_background_tile" : false,
            "profile_image_url" : "http://pbs.twimg.com/profile_images/523668808020422656/szD5CZyb_normal.jpeg",
            "profile_image_url_https" : "https://pbs.twimg.com/profile_images/523668808020422656/szD5CZyb_normal.jpeg",
            "profile_banner_url" : "https://pbs.twimg.com/profile_banners/246394886/1460523073",
            "profile_link_color" : "4A913C",
            "profile_sidebar_border_color" : "000000",
            "profile_sidebar_fill_color" : "000000",
            "profile_text_color" : "000000",
            "profile_use_background_image" : false,
            "has_extended_profile" : true,
            "default_profile" : false,
            "default_profile_image" : false,
            "following" : false,
            "follow_request_sent" : false,
            "notifications" : false
          }
        }
      }
    ]
  },
  "source" : "<a href=\"http://twitter.com/download/iphone\" rel=\"nofollow\">Twitter for iPhone</a>",
  "in_reply_to_status_id" : null,
  "in_reply_to_status_id_str" : null,
  "in_reply_to_user_id" : null,
  "in_reply_to_user_id_str" : null,
  "in_reply_to_screen_name" : null,
  "user" : {
    "id" : 21369740,
    "id_str" : "21369740",
    "name" : "Rob DenBleyker",
    "screen_name" : "RobDenBleyker",
    "location" : "Dallas",
    "description" : "I'm not Rob Dyrdek. Don't follow me.",
    "url" : "https://t.co/5jh1OQTAOO",
    "entities" : {
      "url" : {
        "urls" : [
          {
            "url" : "https://t.co/5jh1OQTAOO",
            "expanded_url" : "http://www.explosm.net",
            "display_url" : "explosm.net",
            "indices" : [
              0,
              23
            ]
          }
        ]
      },
      "description" : {
        "urls" : [
        ]
      }
    },
    "protected" : false,
    "followers_count" : 126457,
    "friends_count" : 800,
    "listed_count" : 1284,
    "created_at" : "Fri Feb 20 03:26:24 +0000 2009",
    "favourites_count" : 1452,
    "utc_offset" : -18000,
    "time_zone" : "Central Time (US & Canada)",
    "geo_enabled" : true,
    "verified" : false,
    "statuses_count" : 8088,
    "lang" : "en",
    "contributors_enabled" : false,
    "is_translator" : false,
    "is_translation_enabled" : false,
    "profile_background_color" : "49585E",
    "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme1/bg.png",
    "profile_background_tile" : false,
    "profile_image_url" : "http://pbs.twimg.com/profile_images/751256809873281024/-FuDkY2p_normal.jpg",
    "profile_image_url_https" : "https://pbs.twimg.com/profile_images/751256809873281024/-FuDkY2p_normal.jpg",
    "profile_link_color" : "0C90F5",
    "profile_sidebar_border_color" : "C0DEED",
    "profile_sidebar_fill_color" : "DDEEF6",
    "profile_text_color" : "333333",
    "profile_use_background_image" : false,
    "has_extended_profile" : false,
    "default_profile" : false,
    "default_profile_image" : false,
    "following" : true,
    "follow_request_sent" : false,
    "notifications" : false
  },
  "geo" : null,
  "coordinates" : null,
  "place" : null,
  "contributors" : null,
  "retweeted_status" : {
    "created_at" : "Wed Aug 03 00:10:40 +0000 2016",
    "id" : 760628917837312000,
    "id_str" : "760628917837312000",
    "text" : "",
    "truncated" : false,
    "entities" : {
      "hashtags" : [
      ],
      "symbols" : [
      ],
      "user_mentions" : [
        {
          "screen_name" : "ScottAdamsSays",
          "name" : "Scott Adams",
          "id" : 2853461537,
          "id_str" : "2853461537",
          "indices" : [
            4,
            19
          ]
        },
        {
          "screen_name" : "eedrk",
          "name" : "derek",
          "id" : 1350600582,
          "id_str" : "1350600582",
          "indices" : [
            21,
            27
          ]
        }
      ],
      "urls" : [
      ],
      "media" : [
        {
          "id" : 760627464456462336,
          "id_str" : "760627464456462336",
          "indices" : [
            121,
            144
          ],
          "media_url" : "http://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
          "media_url_https" : "https://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
          "url" : "https://t.co/Dth5YBHXeu",
          "display_url" : "pic.twitter.com/Dth5YBHXeu",
          "expanded_url" : "http://twitter.com/shutupmikeginn/status/760628917837312000/video/1",
          "type" : "photo",
          "sizes" : {
            "medium" : {
              "w" : 600,
              "h" : 411,
              "resize" : "fit"
            },
            "thumb" : {
              "w" : 150,
              "h" : 150,
              "resize" : "crop"
            },
            "large" : {
              "w" : 700,
              "h" : 480,
              "resize" : "fit"
            },
            "small" : {
              "w" : 340,
              "h" : 233,
              "resize" : "fit"
            }
          }
        }
      ]
    },
    "extended_entities" : {
      "media" : [
        {
          "id" : 760627464456462336,
          "id_str" : "760627464456462336",
          "indices" : [
            121,
            144
          ],
          "media_url" : "http://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
          "media_url_https" : "https://pbs.twimg.com/ext_tw_video_thumb/760627464456462336/pu/img/ZmNeZzX7qcwzsuon.jpg",
          "url" : "https://t.co/Dth5YBHXeu",
          "display_url" : "pic.twitter.com/Dth5YBHXeu",
          "expanded_url" : "http://twitter.com/shutupmikeginn/status/760628917837312000/video/1",
          "type" : "video",
          "sizes" : {
            "medium" : {
              "w" : 600,
              "h" : 411,
              "resize" : "fit"
            },
            "thumb" : {
              "w" : 150,
              "h" : 150,
              "resize" : "crop"
            },
            "large" : {
              "w" : 700,
              "h" : 480,
              "resize" : "fit"
            },
            "small" : {
              "w" : 340,
              "h" : 233,
              "resize" : "fit"
            }
          },
          "video_info" : {
            "aspect_ratio" : [
              35,
              24
            ],
            "duration_millis" : 50017,
            "variants" : [
              {
                "content_type" : "application/dash+xml",
                "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/pl/WgyGZ2bR67CZKbIe.mpd"
              },
              {
                "bitrate" : 320000,
                "content_type" : "video/mp4",
                "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/vid/262x180/bMwQb2LGoymiuNBF.mp4"
              },
              {
                "content_type" : "application/x-mpegURL",
                "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/pl/WgyGZ2bR67CZKbIe.m3u8"
              },
              {
                "bitrate" : 832000,
                "content_type" : "video/mp4",
                "url" : "https://video.twimg.com/ext_tw_video/760627464456462336/pu/vid/524x360/akoT29AzRB-K7Tvf.mp4"
              }
            ]
          },
          "additional_media_info" : {
            "monetizable" : false
          }
        }
      ]
    },
    "source" : "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>",
    "in_reply_to_status_id" : null,
    "in_reply_to_status_id_str" : null,
    "in_reply_to_user_id" : null,
    "in_reply_to_user_id_str" : null,
    "in_reply_to_screen_name" : null,
    "user" : {
      "id" : 246394886,
      "id_str" : "246394886",
      "name" : "shut up, mike",
      "screen_name" : "shutupmikeginn",
      "location" : "Los Angeles, CA",
      "description" : "writer (left handed) // shutupmikeginn @ gmail . com // @midnight",
      "url" : "https://t.co/JLpcO66Txj",
      "entities" : {
        "url" : {
          "urls" : [
            {
              "url" : "https://t.co/JLpcO66Txj",
              "expanded_url" : "http://www.shutupmikeginn.com",
              "display_url" : "shutupmikeginn.com",
              "indices" : [
                0,
                23
              ]
            }
          ]
        },
        "description" : {
          "urls" : [
          ]
        }
      },
      "protected" : false,
      "followers_count" : 155598,
      "friends_count" : 757,
      "listed_count" : 1675,
      "created_at" : "Wed Feb 02 18:21:51 +0000 2011",
      "favourites_count" : 58329,
      "utc_offset" : null,
      "time_zone" : null,
      "geo_enabled" : false,
      "verified" : false,
      "statuses_count" : 9001,
      "lang" : "en",
      "contributors_enabled" : false,
      "is_translator" : false,
      "is_translation_enabled" : false,
      "profile_background_color" : "000000",
      "profile_background_image_url" : "http://abs.twimg.com/images/themes/theme15/bg.png",
      "profile_background_image_url_https" : "https://abs.twimg.com/images/themes/theme15/bg.png",
      "profile_background_tile" : false,
      "profile_image_url" : "http://pbs.twimg.com/profile_images/523668808020422656/szD5CZyb_normal.jpeg",
      "profile_image_url_https" : "https://pbs.twimg.com/profile_images/523668808020422656/szD5CZyb_normal.jpeg",
      "profile_banner_url" : "https://pbs.twimg.com/profile_banners/246394886/1460523073",
      "profile_link_color" : "4A913C",
      "profile_sidebar_border_color" : "000000",
      "profile_sidebar_fill_color" : "000000",
      "profile_text_color" : "000000",
      "profile_use_background_image" : false,
      "has_extended_profile" : true,
      "default_profile" : false,
      "default_profile_image" : false,
      "following" : false,
      "follow_request_sent" : false,
      "notifications" : false
    },
    "geo" : null,
    "coordinates" : null,
    "place" : null,
    "contributors" : null,
    "is_quote_status" : false,
    "retweet_count" : 128,
    "favorite_count" : 523,
    "favorited" : false,
    "retweeted" : false,
    "possibly_sensitive" : false,
    "possibly_sensitive_appealable" : false,
    "lang" : "en"
  },
  "is_quote_status" : false,
  "retweet_count" : 128,
  "favorite_count" : 0,
  "favorited" : false,
  "retweeted" : false,
  "possibly_sensitive" : false,
  "possibly_sensitive_appealable" : false,
  "lang" : "en"
}
""";


