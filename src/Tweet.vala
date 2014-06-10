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


using Gtk;

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
  public Gdk.Pixbuf inline_media;
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

  /** if 0, this tweet is NOT part of a conversation */
  public int64 reply_id = 0;
  public string media;
  public string media_thumb;
  public signal void inline_media_added(Gdk.Pixbuf? media);
  public bool has_inline_media = false;
  public string original_media_url;

  /** if the json from twitter has inline media **/
  private GLib.SList<TweetUtils.Sequence?> urls;
  public int retweet_count;
  public int favorite_count;

  /** List of users mentioned in this tweet */
  public string[] mentions;

  /** List of all the used media **/
  public Media[] medias;


  public Tweet(){
    this.avatar = Twitter.no_avatar;
  }

  /**
   * Fills all the data of this tweet from Json data.
   * @param status The Json object to get the data from
   * @param now The current time
   */
  public void load_from_json (Json.Node status_node, GLib.DateTime now,
                              Account account) {
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
      this.avatar_url    = rt_user.get_string_member("profile_image_url");
      this.user_id       = rt_user.get_int_member("id");
      this.screen_name   = rt_user.get_string_member("screen_name");
      this.rt_created_at = Utils.parse_date(rt.get_string_member("created_at"))
                                  .to_unix();
      this.verified      = rt_user.get_boolean_member("verified");
      if (!rt.get_null_member("in_reply_to_status_id"))
        this.reply_id = rt.get_int_member("in_reply_to_status_id");
    } else {
      entities = status.get_object_member ("entities");
      this.text        = status.get_string_member("text");
      this.user_name   = user.get_string_member("name");
      this.user_id     = user.get_int_member("id");
      this.screen_name = user.get_string_member("screen_name");
      this.avatar_url  = user.get_string_member("profile_image_url");
      this.verified    = user.get_boolean_member("verified");
      if (!status.get_null_member("in_reply_to_status_id"))
        this.reply_id  = status.get_int_member("in_reply_to_status_id");
    }
    if (status.has_member ("current_user_retweet")) {
      this.my_retweet = status.get_object_member ("current_user_retweet").get_int_member ("id");
      this.retweeted  = true;
    }

    this.user_name = this.user_name.replace ("&", "&amp;");
    this.avatar_name = Utils.get_avatar_name(this.avatar_url);

    // 'Resolve' the used URLs
    var urls = entities.get_array_member("urls");
    var hashtags = entities.get_array_member ("hashtags");
    var user_mentions = entities.get_array_member ("user_mentions");
    this.mentions = new string[user_mentions.get_length ()];
    this.urls = new GLib.SList<TweetUtils.Sequence?>();
    urls.foreach_element((arr, index, node) => {
      var url = node.get_object();
      string expanded_url = url.get_string_member("expanded_url");

      Json.Array indices = url.get_array_member ("indices");
      expanded_url = expanded_url.replace("&", "&amp;");
      this.urls.prepend (TweetUtils.Sequence() {
        start = (int)indices.get_int_element (0),
        end   = (int)indices.get_int_element (1) ,
        url   = expanded_url,
        display_url = url.get_string_member ("display_url"),
        visual_display_url = false
      });
      InlineMediaDownloader.try_load_media.begin(this, expanded_url);
    });

    hashtags.foreach_element ((arr, index, node) => {
      var hashtag = node.get_object ();
      Json.Array indices = hashtag.get_array_member ("indices");
      this.urls.prepend(TweetUtils.Sequence(){
        start = (int)indices.get_int_element (0),
        end   = (int)indices.get_int_element (1),
        url   = "#"+hashtag.get_string_member ("text"),
        display_url = "#"+hashtag.get_string_member ("text"),
        visual_display_url=  false
      });
    });


    int real_mentions = 0;
    user_mentions.foreach_element ((arr, index, node) => {
      var mention = node.get_object ();
      Json.Array indices = mention.get_array_member ("indices");

      string screen_name = mention.get_string_member ("screen_name");
      // Avoid duplicate mentions
      if (!(screen_name in this.mentions) && screen_name != account.screen_name
          && screen_name != this.screen_name) {
        this.mentions[real_mentions] = "@" + screen_name;
        real_mentions ++;
      }
      string name = mention.get_string_member ("name");
      int64 id = mention.get_int_member ("id");
      account.user_counter.user_seen (id, screen_name, name);
      this.urls.prepend(TweetUtils.Sequence(){
        start = (int)indices.get_int_element (0),
        end   = (int)indices.get_int_element (1),
        url   = "@" + mention.get_string_member ("id_str") + "/" + screen_name,
        display_url = "@" + screen_name,
        visual_display_url = true,
        title = mention.get_string_member ("name")
      });
    });
    this.mentions.resize (real_mentions);


    // The same with media
    if (entities.has_member ("media")) {
      var medias = entities.get_array_member ("media");
      medias.foreach_element ((arr, index, node) => {
        var url = node.get_object();
        has_inline_media = true;
        string expanded_url = url.get_string_member ("expanded_url");
        expanded_url = expanded_url.replace ("&", "&amp;");
        Json.Array indices = url.get_array_member ("indices");
        this.urls.prepend(TweetUtils.Sequence(){
          start = (int)indices.get_int_element (0),
          end   = (int)indices.get_int_element (1),
          url   = expanded_url,
          display_url = url.get_string_member ("display_url"),
          visual_display_url = false
        });
        InlineMediaDownloader.try_load_media.begin(this,
                url.get_string_member("media_url"));
      });
    }

    if (status.has_member ("extended_entities")) {
      var extended_entities = status.get_object_member ("extended_entities");
      var extended_media = extended_entities.get_array_member ("media");
      this.medias = new Media[extended_media.get_length ()];
      int real_media_count = 0;
      extended_media.foreach_element ((arr, index, node) => {
        var media_obj = node.get_object ();
        var m = new Media ();
        m.url = media_obj.get_string_member ("media_url");
        m.id = media_obj.get_int_member ("id");
        m.type = Media.type_from_string (media_obj.get_string_member ("type"));
        this.medias[real_media_count] = m;
        real_media_count ++;
        InlineMediaDownloader.load_media.begin (this, m);
      });
      this.medias.resize (real_media_count);
    }


    this.urls.sort ((a, b) => {
      if (a.start < b.start)
        return -1;
      return 1;
    });

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
    return TweetUtils.get_formatted_text (this.text, urls);
  }

  /**
   * Returns the text of this tweet, with its long urls.
   * Twitter automatically shortens them.
   *
   * @return The tweet's text with long urls
   */
  public string get_real_text () {
    return TweetUtils.get_real_text (this.text, urls);
  }

}
