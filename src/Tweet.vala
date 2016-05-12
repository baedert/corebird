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

public struct UserIdentity {
  int64 id;
  string screen_name;
  string user_name;
}

[Flags]
public enum TweetState {
  /** Force hiding (there's no way this flag will ever get flipped...)*/
  HIDDEN_FORCE,
  /** Hidden because we unfolled the author */
  HIDDEN_UNFOLLOWED,
  /** Hidden because one o the filters matched the tweet */
  HIDDEN_FILTERED,
  /** Hidden because RTs of the author are disabled */
  HIDDEN_RTS_DISABLED,
  /** Hidden because it's a RT by the authenticating user */
  HIDDEN_RT_BY_USER,
  HIDDEN_RT_BY_FOLLOWEE,
  /** Hidden because the author is blocked */
  HIDDEN_AUTHOR_BLOCKED,
  /** Hidden because the author of a retweet is blocked */
  HIDDEN_RETWEETER_BLOCKED,

  /* The authenticating user retweeted this tweet */
  RETWEETED,
  /* The authenticating user favorited this tweet */
  FAVORITED,
  /* This tweet has been deleted by its author */
  DELETED,
  /* The author of this tweet is verified */
  VERIFIED,
  /* The author of this tweet is protected */
  PROTECTED,
  /* At least one media attached to this tweet is marked sensitive */
  NSFW
}

UserIdentity? parse_identity (Json.Object user_obj)
{
  UserIdentity id = {};
  id.id = user_obj.get_int_member ("id");
  id.screen_name = user_obj.get_string_member ("screen_name");
  id.user_name = user_obj.get_string_member ("name").replace ("&", "&amp;").strip ();

  return id;
}

// XXX FUCK THIS SHOULD BE A STRUCT FFS
public class MiniTweet {
  public int64 id;
  public int64 created_at;
  public UserIdentity author;
  public string text;
  public TextEntity[] entities;
  public Media[] medias;
}

MiniTweet? parse_mini_tweet (Json.Object status)
{
  MiniTweet mt = new MiniTweet ();
  mt.id = status.get_int_member ("id");
  mt.author = parse_identity (status.get_object_member ("user"));
  mt.text = status.get_string_member ("text");
  mt.created_at = Utils.parse_date (status.get_string_member ("created_at")).to_unix ();

  return mt;
}

void parse_entities (MiniTweet mt, Json.Object status)
{ // {{{
  var entities = status.get_object_member ("entities");
  var urls = entities.get_array_member("urls");
  var hashtags = entities.get_array_member ("hashtags");
  var user_mentions = entities.get_array_member ("user_mentions");

  int media_count = Utils.get_json_array_size (entities, "media");
  if (status.has_member ("extended_entities"))
    media_count += Utils.get_json_array_size (status.get_object_member ("extended_entities"), "media");

  media_count += (int)urls.get_length ();

  mt.medias = new Media[media_count];
  int real_media_count = 0;

  /* Overallocate here, remove the unnecessary parts later. */
  mt.entities = new TextEntity[urls.get_length () +
                               hashtags.get_length () +
                               user_mentions.get_length () +
                               media_count];

  int url_index = 0;


  urls.foreach_element((arr, index, node) => {
    var url = node.get_object();
    string expanded_url = url.get_string_member("expanded_url");

    if (is_media_candidate (expanded_url)) {
      var m = new Media ();
      m.url = expanded_url;
      m.type = Media.type_from_url (expanded_url);
      mt.medias[real_media_count] = m;
      real_media_count ++;
    }

    Json.Array indices = url.get_array_member ("indices");
    expanded_url = expanded_url.replace("&", "&amp;");
    mt.entities[url_index] = TextEntity () {
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
    mt.entities[url_index] = TextEntity () {
      from = (uint) indices.get_int_element (0),
      to   = (uint) indices.get_int_element (1),
      display_text = "#" + hashtag.get_string_member ("text"),
      tooltip_text = "#" + hashtag.get_string_member ("text"),
      target = null // == display_text
    };
    url_index ++;
  });


  user_mentions.foreach_element ((arr, index, node) => {
    var mention = node.get_object ();
    Json.Array indices = mention.get_array_member ("indices");

    string screen_name = mention.get_string_member ("screen_name");
    mt.entities[url_index] = TextEntity () {
      from = (uint) indices.get_int_element (0),
      to   = (uint) indices.get_int_element (1),
      display_text = "@" + screen_name,
      target = "@" + mention.get_string_member ("id_str") + "/@" + screen_name,
      tooltip_text = mention.get_string_member ("name")
    };
    url_index ++;
  });

  if (entities.has_member ("media")) {
    var medias = entities.get_array_member ("media");
    medias.foreach_element ((arr, index, node) => {
      var url = node.get_object();
      string expanded_url = url.get_string_member ("expanded_url");
      expanded_url = expanded_url.replace ("&", "&amp;");
      Json.Array indices = url.get_array_member ("indices");
      mt.entities[url_index] = TextEntity () {
        from = (uint) indices.get_int_element (0),
        to   = (uint) indices.get_int_element (1),
        target = url.get_string_member ("url"),
        display_text = url.get_string_member ("display_url")
      };
      url_index ++;
    });
  }

  /* entities->media and extended_entities contain exactly the same media objects,
     but extended_entities is not always present, and entities->media doesn't
     contain all the attached media, so parse both the same way... */
  int n_media_arrays = 0;
  if (entities.has_member ("media")) n_media_arrays ++;
  if (status.has_member ("extended_entities")) n_media_arrays ++;
  Json.Array[] media_arrays = new Json.Array[n_media_arrays];
  int m_i = 0;
  if (entities.has_member ("media")) media_arrays[m_i++] = entities.get_array_member ("media");
  if (status.has_member ("extended_entities"))
      media_arrays[m_i++] = status.get_object_member ("extended_entities").get_array_member ("media");

  foreach (Json.Array media_array in media_arrays) {
    media_array.foreach_element ((arr, index, node) => {
      var media_obj = node.get_object ();
      string media_type = media_obj.get_string_member ("type");
      if (media_type == "photo") {
        string url = media_obj.get_string_member ("media_url");
        foreach (Media m in mt.medias) {
          if (m != null && m.url == url)
            return;
        }
        if (is_media_candidate (url)) {
          var m = new Media ();
          m.url = url;
          m.target_url = url + ":orig";
          m.type = Media.type_from_string (media_obj.get_string_member ("type"));

          if (media_obj.has_member ("sizes")) {
            var size_obj = media_obj.get_object_member ("sizes")
                                    .get_object_member ("medium");

            m.width  = (int)size_obj.get_int_member ("w");
            m.height = (int)size_obj.get_int_member ("h");
          }

          mt.medias[real_media_count] = m;
          real_media_count ++;
        }
      } else if (media_type == "video" ||
                 media_type == "animated_gif") {
        int thumb_width = -1;
        int thumb_height = -1;
        Json.Object? variant = null;
        Json.Array variants = media_obj.get_object_member ("video_info")
                                       .get_array_member ("variants");

        if (media_obj.has_member ("sizes")) {
          var size_obj = media_obj.get_object_member ("sizes")
                                  .get_object_member ("medium");
          thumb_width = (int)size_obj.get_int_member ("w");
          thumb_height = (int)size_obj.get_int_member ("h");
        }

        int variant_width = 0;
        int variant_height = 0;

        bool hls_found = false;
        /* See if we can find a HLS stream and prefer that */
        for (uint i = 0; i < variants.get_length (); i ++) {
          var cur_variant = variants.get_element (i).get_object ();
          if (cur_variant.get_string_member ("content_type") == "application/x-mpegURL") {
            hls_found = true;
            variant = cur_variant;
          }
        }


        if (!hls_found) {
          /* We pick the mp4 variant with a size closest to the
             thumbnail size, but not bigger */
          for (uint i = 0; i < variants.get_length (); i ++) {
            var cur_variant = variants.get_element (i).get_object ();
            if (cur_variant.get_string_member ("content_type") == "video/mp4") {
              if (thumb_width == -1 && thumb_height == -1)
                break;


              int w, h;
              Utils.get_size_from_url (cur_variant.get_string_member ("url"),
                                       out w, out h);
              if (w > variant_width && w <= thumb_width &&
                  h > variant_height && h <= thumb_height) {
                variant_width = w;
                variant_height = h;
                variant = cur_variant;
              }
            }
          }
        }

        if (variant == null && variants.get_length () > 0)
          variant = variants.get_element (0).get_object ();

        if (variant != null) {
          Media m = new Media ();
          m.url = variant.get_string_member ("url");
          m.thumb_url = media_obj.get_string_member ("media_url");
          m.type = MediaType.TWITTER_VIDEO;
          m.width = thumb_width;
          m.height = thumb_height;

          mt.medias[real_media_count] = m;
          real_media_count ++;
        }
      }
    });
  }

  mt.medias.resize (real_media_count);
  InlineMediaDownloader.get ().load_all_media (mt, mt.medias);

  /* Remove unnecessary url entries */
  mt.entities.resize (url_index);
  TweetUtils.sort_entities (ref mt.entities);

} // }}}


public class Tweet : GLib.Object {
  public static const int MAX_LENGTH = 140;
  private uint state = 0;

#if DEBUG
  public string json_data;
#endif

  public bool is_hidden {
    get {
      return this.is_flag_set (TweetState.HIDDEN_FORCE |
                               TweetState.HIDDEN_UNFOLLOWED |
                               TweetState.HIDDEN_FILTERED |
                               TweetState.HIDDEN_RTS_DISABLED |
                               TweetState.HIDDEN_RT_BY_USER |
                               TweetState.HIDDEN_RT_BY_FOLLOWEE |
                               TweetState.HIDDEN_AUTHOR_BLOCKED |
                               TweetState.HIDDEN_RETWEETER_BLOCKED);
    }
  }
  public signal void state_changed ();

  public int64 id;

  public int64 user_id {
    get {
      if (this.retweeted_tweet != null)
        return this.retweeted_tweet.author.id;
      else
        return this.source_tweet.author.id;
    }
  }
  public string screen_name {
   get {
      if (this.retweeted_tweet != null)
        return this.retweeted_tweet.author.screen_name;
      else
        return this.source_tweet.author.screen_name;
    }
  }
  public string user_name {
    get {
      if (this.retweeted_tweet != null)
        return this.retweeted_tweet.author.user_name;
      else
        return this.source_tweet.author.user_name;
    }
  }
  public MiniTweet  source_tweet;
  public MiniTweet? retweeted_tweet = null;
  public MiniTweet? quoted_tweet = null;

  /** The avatar url on the server */
  public string avatar_url;
  public int64 my_retweet;
  public string? notification_id = null;
  private bool _seen = true;
  public bool seen {
    get {
      return _seen;
    }
    set {
      _seen = value;
      if (value && notification_id != null) {
        GLib.Application.get_default ().withdraw_notification (notification_id);
        this.notification_id = null;
      }
    }
  }

  /** if 0, this tweet is NOT part of a conversation */
  public int64 reply_id = 0;

  public Media[] medias {
    get {
      if (this.quoted_tweet != null)
          return this.quoted_tweet.medias;
      else if (this.retweeted_tweet != null)
        return this.retweeted_tweet.medias;
      else
        return this.source_tweet.medias;
    }
  }
  public bool has_inline_media {
    get {
      /* If there's a quoted tweet, always prefer that. */
      if (this.quoted_tweet != null) {
        return this.quoted_tweet.medias != null &&
               this.quoted_tweet.medias.length > 0;
      }

      if (this.retweeted_tweet != null)
        return retweeted_tweet.medias != null &&
               retweeted_tweet.medias.length > 0;
      else
        return source_tweet.medias != null &&
               source_tweet.medias.length > 0;
    }
  }

  public int retweet_count;
  public int favorite_count;

  public string[] get_mentions () {
    TextEntity[] entities;
    if (this.retweeted_tweet != null)
      entities = this.retweeted_tweet.entities;
    else
      entities = this.source_tweet.entities;


    string[] e = new string[entities.length];
    int n_mentions = 0;
    foreach (unowned TextEntity entity in entities) {
      if (entity.display_text[0] == '@') {
        e[n_mentions] = entity.display_text;
        n_mentions ++;
      }
    }

    e.resize (n_mentions);
    return e;
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
    this.id          = status.get_int_member("id");
    if (status.get_boolean_member ("favorited"))
      this.state |= TweetState.FAVORITED;
    if (status.get_boolean_member ("retweeted"))
      this.state |= TweetState.RETWEETED;

    this.retweet_count = (int)status.get_int_member ("retweet_count");
    this.favorite_count = (int)status.get_int_member ("favorite_count");

    if (Utils.usable_json_value (status, "possibly_sensitive") &&
        status.get_boolean_member ("possibly_sensitive"))
      this.state |= TweetState.NSFW;

    this.source_tweet = parse_mini_tweet (status);

    bool has_media = Utils.get_json_array_size (status.get_object_member ("entities"),
                                                "media") > 0;

    if (status.has_member ("retweeted_status")) {
      Json.Object rt      = status.get_object_member ("retweeted_status");
      this.retweeted_tweet = parse_mini_tweet (rt);
      parse_entities (this.retweeted_tweet, rt);

      Json.Object rt_user = rt.get_object_member("user");
      this.avatar_url    = rt_user.get_string_member ("profile_image_url");
      if (rt_user.get_boolean_member ("protected"))
        this.state |= TweetState.PROTECTED;

      if (rt_user.get_boolean_member ("verified"))
        this.state |= TweetState.VERIFIED;

      if (!rt.get_null_member ("in_reply_to_status_id"))
        this.reply_id = rt.get_int_member ("in_reply_to_status_id");
    } else {
      parse_entities (this.source_tweet, status);
      this.avatar_url  = user.get_string_member ("profile_image_url");
      if (user.get_boolean_member ("verified"))
        this.state |= TweetState.VERIFIED;

      if (user.get_boolean_member ("protected"))
        this.state |= TweetState.PROTECTED;

      if (!status.get_null_member ("in_reply_to_status_id"))
        this.reply_id  = status.get_int_member ("in_reply_to_status_id");
    }

    if (status.has_member ("quoted_status") && !has_media) {
      var quoted_status = status.get_object_member ("quoted_status");
      this.quoted_tweet = parse_mini_tweet (quoted_status);
      parse_entities (this.quoted_tweet, quoted_status);
    } else if (this.retweeted_tweet != null &&
               status.get_object_member ("retweeted_status").has_member ("quoted_status")) {
      var quoted_status = status.get_object_member ("retweeted_status").get_object_member ("quoted_status");
      this.quoted_tweet = parse_mini_tweet (quoted_status);
      parse_entities (this.quoted_tweet, quoted_status);
    }

    if (status.has_member ("current_user_retweet")) {
      this.my_retweet = status.get_object_member ("current_user_retweet").get_int_member ("id");
      this.state |= TweetState.RETWEETED;
    }

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
    MiniTweet t;
    if (this.retweeted_tweet != null)
      t = this.retweeted_tweet;
    else
      t = this.source_tweet;

    return TextTransform.transform_tweet (t, 0);
  }

  /**
   * Returns the text of this tweet, with its long urls.
   * Twitter automatically shortens them.
   *
   * @return The tweet's text with long urls
   */
  public string get_real_text () {
    MiniTweet t;
    if (this.retweeted_tweet != null)
      t = this.retweeted_tweet;
    else
      t = this.source_tweet;

    return TextTransform.transform_tweet (t,
                                          TransformFlags.EXPAND_LINKS);
  }

  public string get_trimmed_text () {
    MiniTweet t;
    if (this.retweeted_tweet != null)
      t = this.retweeted_tweet;
    else
      t = this.source_tweet;

    int64 quote_id = this.quoted_tweet != null ? this.quoted_tweet.id : -1;

    return TextTransform.transform_tweet (t,
                                          Settings.get_text_transform_flags (),
                                          quote_id);
  }

  public void set_flag (TweetState flag) {
    uint state_before = this.state;
    this.state |= flag;

    if (state_before != this.state)
      this.state_changed ();
  }

  public void unset_flag (TweetState flag) {
    uint state_before = this.state;
    this.state &= ~flag;

    if (state_before != this.state)
      this.state_changed ();
  }

  public bool is_flag_set (TweetState flag) {
    return (this.state & flag) > 0;
  }
}
