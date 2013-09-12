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

class Tweet : GLib.Object {

  public static const int TYPE_NORMAL   = 1;
  public static const int TYPE_MENTION  = 2;
  public static const int TYPE_FAVORITE = 3;

#if __DEV
  public string json_data;
#endif


  public int64 id;
  /** If this tweet is a retweet, this is its id */
  public int64 rt_id;
  public bool retweeted = false;
  public bool favorited = false;
  public string text;
  public int64 user_id;
  public string user_name;
  public string retweeted_by;
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

  /** if 0, this tweet is NOT part of a conversation */
  public int64 reply_id = 0;
  public string media;
  public string media_thumb;
  public signal void inline_media_added(Gdk.Pixbuf? media);
  public bool has_inline_media = false;
  public int type = -1;
  private GLib.SList<TweetUtils.Sequence?> urls;
  public int retweet_count;
  public int favorite_count;


  public Tweet(){
    this.avatar = Twitter.no_avatar;
  }

  /**
   * Fills all the data of this tweet from Json data.
   * @param status The Json object to get the data from
   * @param now The current time
   */
  public void load_from_json(Json.Node status_node, GLib.DateTime now) {
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
      this.retweeted_by  = user.get_string_member("name");
      this.text          = rt.get_string_member("text");
      this.user_name     = rt_user.get_string_member ("name").replace ("&", "&amp;");
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
      this.screen_name = user.get_string_member("screen_name").replace ("&", "&amp;");
      this.avatar_url  = user.get_string_member("profile_image_url");
      this.verified    = user.get_boolean_member("verified");
      if (!status.get_null_member("in_reply_to_status_id"))
        this.reply_id  = status.get_int_member("in_reply_to_status_id");
    }
    if (status.has_member ("current_user_retweet"))
      this.my_retweet    = status.get_object_member ("current_user_retweet").get_int_member ("id");


    this.avatar_name = Utils.get_avatar_name(this.avatar_url);



    // 'Resolve' the used URLs
    var urls = entities.get_array_member("urls");
    var hashtags = entities.get_array_member ("hashtags");
    var user_mentions = entities.get_array_member ("user_mentions");
    this.urls = new GLib.SList<TweetUtils.Sequence?>();
    urls.foreach_element((arr, index, node) => {
      var url = node.get_object();
      string expanded_url = url.get_string_member("expanded_url");

      Json.Array indices = url.get_array_member ("indices");
      expanded_url = expanded_url.replace("&", "&amp;");
      this.urls.prepend(TweetUtils.Sequence() {
        start = (int)indices.get_int_element (0),
        end   = (int)indices.get_int_element (1) ,
        url   = expanded_url,
        display_url = url.get_string_member ("display_url")
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
        display_url = "#"+hashtag.get_string_member ("text")
      });
    });

    user_mentions.foreach_element ((arr, index, node) => {
      var mention = node.get_object ();
      Json.Array indices = mention.get_array_member ("indices");

      this.urls.prepend(TweetUtils.Sequence(){
        start = (int)indices.get_int_element (0),
        end   = (int)indices.get_int_element (1),
        url   = "@"+mention.get_string_member ("id_str"),
        display_url = "@"+mention.get_string_member ("screen_name")
      });
    });


    // The same with media
    if (entities.has_member ("media")) {
      var medias = entities.get_array_member ("media");
      medias.foreach_element ((arr, index, node) => {
        var url = node.get_object();
        string expanded_url = url.get_string_member ("expanded_url");
        expanded_url = expanded_url.replace ("&", "&amp;");
        Json.Array indices = url.get_array_member ("indices");
        this.urls.prepend(TweetUtils.Sequence(){
          start = (int)indices.get_int_element (0),
          end   = (int)indices.get_int_element (1),
          url   = expanded_url,
          display_url = url.get_string_member ("display_url")
        });
        InlineMediaDownloader.try_load_media.begin(this,
                url.get_string_member("media_url"));
      });
    }




    var dt = new DateTime.from_unix_local(is_retweet ? rt_created_at : created_at);
    this.time_delta  = Utils.get_time_delta(dt, now);


    //this.load_avatar();
    this.avatar = TweetUtils.load_avatar (avatar_url);
    if (this.avatar == null) {
      TweetUtils.download_avatar.begin (avatar_url, (obj, res) => {
        var avatar = TweetUtils.download_avatar.end (res);
        this.avatar = TweetUtils.load_avatar (avatar_url, avatar);
      });
    }

#if __DEV
  // This is pretty stupid because we're actually getting the json string
  // from Twitter but meh...
  var gen = new Json.Generator ();
  gen.root = status_node;
  gen.pretty = true;
  this.json_data = gen.to_data (null);
#endif
  }

  /**
   * Returns the text of this tweet in pango markup form,
   * i.e. formatted with the html tags formatted by pango.
   *
   * @return The tweet's formatted text.
   */
  public string get_formatted_text () {
    return TweetUtils.get_formatted_text (this.text, urls);
  }

}
