

// {{{
const string TD1 = """
{
  "created_at": "Tue Apr 29 00:50:10 +0000 2014",
  "id": 460944092554227713,
  "id_str": "460944092554227713",
  "text": "Combined. http:\/\/t.co\/fFJqqT1A4j",
  "source": "\u003ca href=\"http:\/\/twitter.com\/geekculturejam\" rel=\"nofollow\"\u003eCultureJam\u003c\/a\u003e",
  "truncated": false,
  "in_reply_to_status_id": null,
  "in_reply_to_status_id_str": null,
  "in_reply_to_user_id": null,
  "in_reply_to_user_id_str": null,
  "in_reply_to_screen_name": null,
  "user": {
    "id": 657693,
    "id_str": "657693",
    "screen_name": "FOOBAR",
    "name": "Foo Bar",
    "profile_image_url": "http://foobar.org/bla.png",
    "verified" : false
  },
  "geo": null,
  "coordinates": null,
  "place": null,
  "contributors": null,
  "retweet_count": 0,
  "favorite_count": 0,
  "entities": {
    "hashtags": [],
    "symbols": [],
    "urls": [],
    "user_mentions": [],
    "media": []
  },
  "extended_entities": {
    "media": [
      {
        "id": 460938773744717825,
        "id_str": "460938773744717825",
        "indices": [
          10,
          32
        ],
        "media_url": "http:\/\/pbs.twimg.com\/media\/BmWVX2BCEAEx4MK.jpg",
        "media_url_https": "https:\/\/pbs.twimg.com\/media\/BmWVX2BCEAEx4MK.jpg",
        "url": "http:\/\/t.co\/fFJqqT1A4j",
        "display_url": "pic.twitter.com\/fFJqqT1A4j",
        "expanded_url": "http:\/\/twitter.com\/froginthevalley\/status\/460944092554227713\/photo\/1",
        "type": "photo",
        "sizes": {
          "medium": {
            "w": 599,
            "h": 397,
            "resize": "fit"
          },
          "thumb": {
            "w": 150,
            "h": 150,
            "resize": "crop"
          },
          "small": {
            "w": 340,
            "h": 225,
            "resize": "fit"
          },
          "large": {
            "w": 1023,
            "h": 678,
            "resize": "fit"
          }
        }
      },
      {
        "id": 460938635315916800,
        "id_str": "460938635315916800",
        "indices": [
          10,
          32
        ],
        "media_url": "http:\/\/pbs.twimg.com\/media\/BmWVPyVCMAAeAwI.jpg",
        "media_url_https": "https:\/\/pbs.twimg.com\/media\/BmWVPyVCMAAeAwI.jpg",
        "url": "http:\/\/t.co\/fFJqqT1A4j",
        "display_url": "pic.twitter.com\/fFJqqT1A4j",
        "expanded_url": "http:\/\/twitter.com\/froginthevalley\/status\/460944092554227713\/photo\/1",
        "type": "photo",
        "sizes": {
          "medium": {
            "w": 600,
            "h": 600,
            "resize": "fit"
          },
          "thumb": {
            "w": 150,
            "h": 150,
            "resize": "crop"
          },
          "large": {
            "w": 1024,
            "h": 1024,
            "resize": "fit"
          },
          "small": {
            "w": 340,
            "h": 340,
            "resize": "fit"
          }
        }
      }
    ]
  },
  "favorited": false,
  "retweeted": false,
  "possibly_sensitive": false,
  "lang": "en"
}
""";
// XXX Use normal tweet + extended_media from twitter article
// }}}



void normal () {
  Tweet t = new Tweet ();
  Json.Parser parser = new Json.Parser ();
  GLib.DateTime now = new GLib.DateTime.now_local ();
  Account acc = new Account (1234, "foobar", "Foo Bar");
  try {
    parser.load_from_data (TD1);
  } catch (GLib.Error e) {
    critical (e.message);
  }
  t.load_from_json (parser.get_root (), now, acc);
  assert (t.medias.length == 2);

}


void main (string[] args) {
  GLib.Test.init (ref args);
  Settings.init ();
  Twitter.get ().init ();

  GLib.Test.add_func ("/multimedia/normal", normal);
  GLib.Test.run ();
}
