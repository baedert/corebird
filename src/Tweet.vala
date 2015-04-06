/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */


public class Tweet : GLib.Object {
  public static const int MAX_LENGTH = 140;

#if DEBUG
  public string json_data;
#endif


  public int64 id;
  /** If this tweet is a retweet, this is its id */
  public int64 rt_id = 0;
  public bool retweeted { get; set; default = false; }
  public bool favorited { get; set; default = false; }
  public string text;
  public int64 user_id;
  public string user_name;
  public string retweeted_by;
  public string rt_by_screen_name;
  public int64 rt_by_id;
  public bool is_retweet;
  public unowned Gdk.Pixbuf avatar {get; set;}
  public string time_delta = "-1s";
  /** The avatar url on the server */
  public string avatar_url;
  /** The name of the avatar image file on the hard disk */
  public string avatar_name;
  public string screen_name;
  public int64 created_at;
  public int64 rt_created_at;
  public bool verified = false;
  /** If the user retweeted this tweet */
  public int64 my_retweet;
  public bool protected;

  /** if 0, this tweet is NOT part of a conversation */
  public int64 reply_id = 0;

  /** List of all the used media **/
  public Media[] medias;
  public bool has_inline_media {
    get { return medias != null && medias.length > 0; }
  }

  /** if the json from twitter has inline media **/
  public TextEntity[] urls;
  public int retweet_count;
  public int favorite_count;

  /** List of users mentioned in this tweet */
  public string[] mentions;


  public Tweet () {
    this.avatar = Twitter.no_avatar;
  }

  /**
   * Fills all the data of this tweet from Json data.
   * @param status The Json object to get the data from
   * @param now The current time
   */
  public void load_from_json (Json.Node     status_node,
                              GLib.DateTime now,
                              Account       account) {
    Json.Object status = status_node.get_object ();
    Json.Object user = status.get_object_member("user");
    Json.Object entities;
    this.id          = status.get_int_member("id");
    this.favorited   = status.get_boolean_member("favorited");
    this.retweeted   = status.get_boolean_member("retweeted");
    this.retweet_count = (int)status.get_int_member ("retweet_count");
    this.favorite_count = (int)status.get_int_member ("favorite_count");
    this.created_at  = Utils.parse_date(status.get_string_member("created_at"))
                      .to_unix();


    if (status.has_member("retweeted_status")) {
      Json.Object rt      = status.get_object_member("retweeted_status");
      Json.Object rt_user = rt.get_object_member("user");
      entities           = rt.get_object_member ("entities");
      this.is_retweet    = true;
      this.rt_id         = rt.get_int_member("id");
      this.retweeted_by  = user.get_string_member("name").replace ("&", "&amp;");
      this.rt_by_screen_name = user.get_string_member ("screen_name");
      this.rt_by_id      = user.get_int_member ("id");
      this.text          = rt.get_string_member("text");
      this.user_name     = rt_user.get_string_member ("name");
      this.avatar_url    = rt_user.get_string_member ("profile_image_url");
      this.user_id       = rt_user.get_int_member ("id");
      this.screen_name   = rt_user.get_string_member ("screen_name");
      this.rt_created_at = Utils.parse_date(rt.get_string_member ("created_at"))
                                  .to_unix();
      this.verified      = rt_user.get_boolean_member ("verified");
      this.protected     = rt_user.get_boolean_member ("protected");
      if (!rt.get_null_member ("in_reply_to_status_id"))
        this.reply_id = rt.get_int_member ("in_reply_to_status_id");
    } else {
      entities = status.get_object_member ("entities");
      this.text        = status.get_string_member ("text");
      this.user_name   = user.get_string_member ("name");
      this.user_id     = user.get_int_member ("id");
      this.screen_name = user.get_string_member ("screen_name");
      this.avatar_url  = user.get_string_member ("profile_image_url");
      this.verified    = user.get_boolean_member ("verified");
      this.protected   = user.get_boolean_member ("protected");
      if (!status.get_null_member("in_reply_to_status_id"))
        this.reply_id  = status.get_int_member("in_reply_to_status_id");
    }
    if (status.has_member ("current_user_retweet")) {
      this.my_retweet = status.get_object_member ("current_user_retweet").get_int_member ("id");
      this.retweeted  = true;
    }

    this.user_name = this.user_name.replace ("&", "&amp;").strip ();
    this.avatar_name = Utils.get_avatar_name (this.avatar_url);

    // 'Resolve' the used URLs
    var urls = entities.get_array_member("urls");
    var hashtags = entities.get_array_member ("hashtags");
    var user_mentions = entities.get_array_member ("user_mentions");
    this.mentions = new string[user_mentions.get_length ()];

    int media_count = Utils.get_json_array_size (entities, "media");
    if (status.has_member ("extended_entities"))
      media_count += Utils.get_json_array_size (status.get_object_member ("extended_entities"), "media");

    media_count += (int)urls.get_length ();

    this.medias = new Media[media_count];
    int real_media_count = 0;

    /* Overallocate here, remove the unnecessary parts later. */
    this.urls = new TextEntity[urls.get_length () +
                               hashtags.get_length () +
                               user_mentions.get_length () +
                               media_count];

    int url_index = 0;


    urls.foreach_element((arr, index, node) => {
      var url = node.get_object();
      string expanded_url = url.get_string_member("expanded_url");

      if (InlineMediaDownloader.is_media_candidate (expanded_url)) {
        var m = new Media ();
        m.url = expanded_url;
        m.id = real_media_count;
        m.type = Media.type_from_url (expanded_url);
        this.medias[real_media_count] = m;
        real_media_count ++;
      }

      Json.Array indices = url.get_array_member ("indices");
      expanded_url = expanded_url.replace("&", "&amp;");
      this.urls[url_index] = TextEntity () {
        from = (uint) indices.get_int_element (0),
        to   = (uint) indices.get_int_element (1),
        display_text = url.get_string_member ("display_url"),
        tooltip_text = expanded_url,
        target = expanded_url
      };
      url_index ++;
    });

    hashtags.foreach_element ((arr, index, node) => {
      var hashtag = node.get_object ();
      Json.Array indices = hashtag.get_array_member ("indices");
      this.urls[url_index] = TextEntity () {
        from = (uint) indices.get_int_element (0),
        to   = (uint) indices.get_int_element (1),
        display_text = "#" + hashtag.get_string_member ("text"),
        tooltip_text = "#" + hashtag.get_string_member ("text"),
        target = null // == display_text
      };
      url_index ++;
    });


    int real_mentions = 0;
    user_mentions.foreach_element ((arr, index, node) => {
      var mention = node.get_object ();
      Json.Array indices = mention.get_array_member ("indices");

      string screen_name = mention.get_string_member ("screen_name");
      // Avoid duplicate mentions
      if (!(screen_name in this.mentions) && screen_name != account.screen_name
          && screen_name != this.rt_by_screen_name
          && screen_name != this.screen_name) {
        this.mentions[real_mentions] = "@" + screen_name;
        real_mentions ++;
      }
      string name = mention.get_string_member ("name");
      int64 id = mention.get_int_member ("id");
      account.user_counter.user_seen (id, screen_name, name);

      this.urls[url_index] = TextEntity () {
        from = (uint) indices.get_int_element (0),
        to   = (uint) indices.get_int_element (1),
        display_text = "@" + screen_name,
        target = "@" + mention.get_string_member ("id_str") + "/" + screen_name,
        tooltip_text = mention.get_string_member ("name")
      };
      url_index ++;
    });
    this.mentions.resize (real_mentions);

    // The same with media
    if (entities.has_member ("media")) {
      var medias = entities.get_array_member ("media");
      medias.foreach_element ((arr, index, node) => {
        var url = node.get_object();
        string expanded_url = url.get_string_member ("expanded_url");
        expanded_url = expanded_url.replace ("&", "&amp;");
        Json.Array indices = url.get_array_member ("indices");
        this.urls[url_index] = TextEntity () {
          from = (uint) indices.get_int_element (0),
          to   = (uint) indices.get_int_element (1),
          target = url.get_string_member ("url"),
          display_text = url.get_string_member ("display_url")
        };
        url_index ++;
        string media_url = url.get_string_member ("media_url");
        if (InlineMediaDownloader.is_media_candidate (media_url)) {
          var m = new Media ();
          m.url = media_url;
          m.target_url = media_url + ":large";
          this.medias[real_media_count] = m;
          real_media_count ++;
        }
      });
    }

    if (status.has_member ("extended_entities")) {
      var extended_entities = status.get_object_member ("extended_entities");
      var extended_media = extended_entities.get_array_member ("media");
      extended_media.foreach_element ((arr, index, node) => {
        var media_obj = node.get_object ();
        string media_type = media_obj.get_string_member ("type");
        if (media_type == "photo") {
          string url = media_obj.get_string_member ("media_url");
          foreach (Media m in this.medias) {
            if (m != null && m.url == url)
              return;
          }
          if (InlineMediaDownloader.is_media_candidate (url)) {
            var m = new Media ();
            m.url = url;
            m.target_url = url + ":large";
            m.id = media_obj.get_int_member ("id");
            m.type = Media.type_from_string (media_obj.get_string_member ("type"));
            this.medias[real_media_count] = m;
            real_media_count ++;
          }
        } else if (media_type == "video" ||
                   media_type == "animated_gif") {
          Json.Object variant = media_obj.get_object_member ("video_info")
                                         .get_array_member ("variants")
                                         .get_object_element (0); // XXX ???
          Media m = new Media ();
          m.url = variant.get_string_member ("url");
          m.thumb_url = media_obj.get_string_member ("media_url");
          m.type = MediaType.TWITTER_VIDEO;
          m.id = media_obj.get_int_member ("id");
          this.medias[real_media_count] = m;
          real_media_count ++;
        }
      });
    }

    this.medias.resize (real_media_count);
    InlineMediaDownloader.load_all_media (this, this.medias);

    /* Remove unnecessary url entries */
    this.urls.resize (url_index);
    TweetUtils.sort_entities (ref this.urls);

    var dt = new DateTime.from_unix_local(is_retweet ? rt_created_at : created_at);
    this.time_delta  = Utils.get_time_delta(dt, now);


    this.avatar = Twitter.get ().get_avatar (avatar_url, (a) => {
      this.avatar = a;
    });

#if DEBUG
    var gen = new Json.Generator ();
    gen.root = status_node;
    gen.pretty = true;
    this.json_data = gen.to_data (null);
#endif
  }

  /**
   * Returns the text of this tweet in pango markup form,
   * i.e. formatted with the html tags used by pango.
   *
   * @return The tweet's formatted text.
   */
  public string get_formatted_text () {
    return TextTransform.transform (this.text,
                                    this.urls,
                                    0,
                                    this.medias.length);
  }

  /**
   * Returns the text of this tweet, with its long urls.
   * Twitter automatically shortens them.
   *
   * @return The tweet's text with long urls
   */
  public string get_real_text () {
    return TextTransform.transform (this.text,
                                    this.urls,
                                    TransformFlags.EXPAND_LINKS,
                                    this.medias.length);
  }

  public string get_trimmed_text () {
    return TextTransform.transform (this.text,
                                    this.urls,
                                    (TransformFlags) Settings.get_text_transform_flags (),
                                    this.medias.length);
  }

}
