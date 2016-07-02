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
  /** Hidden because the author was muted */
  HIDDEN_AUTHOR_MUTED,
  /** Hidden because the author of a retweet is muted */
  HIDDEN_RETWEETER_MUTED,

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

public class Tweet : GLib.Object {
  public static const int MAX_LENGTH = 140;
  public uint state = 0;

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
                               TweetState.HIDDEN_RETWEETER_BLOCKED |
                               TweetState.HIDDEN_AUTHOR_MUTED |
                               TweetState.HIDDEN_RETWEETER_MUTED);
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
  public Cb.MiniTweet  source_tweet;
  public Cb.MiniTweet? retweeted_tweet = null;
  public Cb.MiniTweet? quoted_tweet = null;

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

  public Cb.Media[] medias {
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
    Cb.TextEntity[] entities;
    if (this.retweeted_tweet != null)
      entities = this.retweeted_tweet.entities;
    else
      entities = this.source_tweet.entities;


    string[] e = new string[entities.length];
    int n_mentions = 0;
    foreach (unowned Cb.TextEntity entity in entities) {
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

    this.source_tweet = Cb.MiniTweet ();
    this.source_tweet.parse (status);

    bool has_media = Utils.get_json_array_size (status.get_object_member ("entities"),
                                                "media") > 0;

    if (status.has_member ("retweeted_status")) {
      Json.Object rt      = status.get_object_member ("retweeted_status");
      this.retweeted_tweet = Cb.MiniTweet ();
      this.retweeted_tweet.parse (rt);
      this.retweeted_tweet.parse_entities (rt);

      Json.Object rt_user = rt.get_object_member("user");
      this.avatar_url    = rt_user.get_string_member ("profile_image_url");
      if (rt_user.get_boolean_member ("protected"))
        this.state |= TweetState.PROTECTED;

      if (rt_user.get_boolean_member ("verified"))
        this.state |= TweetState.VERIFIED;

      if (!rt.get_null_member ("in_reply_to_status_id"))
        this.reply_id = rt.get_int_member ("in_reply_to_status_id");
    } else {
      this.source_tweet.parse_entities (status);
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
      this.quoted_tweet = Cb.MiniTweet ();
      this.quoted_tweet.parse (quoted_status);
      this.quoted_tweet.parse_entities (quoted_status);
    } else if (this.retweeted_tweet != null &&
               status.get_object_member ("retweeted_status").has_member ("quoted_status")) {
      var quoted_status = status.get_object_member ("retweeted_status").get_object_member ("quoted_status");
      this.quoted_tweet = Cb.MiniTweet ();
      this.quoted_tweet.parse (quoted_status);
      this.quoted_tweet.parse_entities (quoted_status);
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
    if (this.retweeted_tweet != null)
      return Cb.TextTransform.tweet (ref this.retweeted_tweet,
                                     Settings.get_text_transform_flags (), 0);
    else
      return Cb.TextTransform.tweet (ref this.source_tweet,
                                     Settings.get_text_transform_flags (), 0);
  }

  /**
   * Returns the text of this tweet, with its long urls.
   * Twitter automatically shortens them.
   *
   * @return The tweet's text with long urls
   */
  public string get_real_text () {
    if (this.retweeted_tweet != null) {
      return Cb.TextTransform.tweet (ref this.retweeted_tweet,
                                     Cb.TransformFlags.EXPAND_LINKS,
                                     0);
    } else {
      return Cb.TextTransform.tweet (ref this.source_tweet,
                                     Cb.TransformFlags.EXPAND_LINKS,
                                     0);
    }
  }

  public string get_trimmed_text () {
    int64 quote_id = this.quoted_tweet != null ? this.quoted_tweet.id : 0;
    if (this.retweeted_tweet != null) {
      return Cb.TextTransform.tweet (ref this.retweeted_tweet,
                                     Settings.get_text_transform_flags (),
                                     quote_id);
    } else {
      return Cb.TextTransform.tweet (ref this.source_tweet,
                                     Settings.get_text_transform_flags (),
                                     quote_id);
    }
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
