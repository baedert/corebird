
[CCode (cprefix = "Cb", lower_case_cprefix = "cb_")]
namespace Cb {
  [CCode (cprefix = "CB_MEDIA_TYPE_", cheader_filename = "Media.h")]
  public enum MediaType {
    IMAGE,
    VINE,
    GIF,
    ANIMATED_GIF,
    TWITTER_VIDEO,
    INSTAGRAM_VIDEO,

    UNKNOWN
  }

  [CCode (cprefix = "CbMedia_", lower_case_cprefix = "cb_media_", cheader_filename = "Media.h")]
  public class Media : GLib.Object {
    public int64 length;
    public bool loaded;
    public bool invalid;
    public string url;
    public string thumb_url;
    public string target_url;
    public MediaType type;
    public int width;
    public int height;
    public int percent_loaded;
    public Cairo.ImageSurface? surface;
    public Gdk.PixbufAnimation? animation;
    public signal void progress();

    public Media();
    public bool is_video ();
  }

  [CCode (cprefix = "CbUserIdentity_", lower_case_cprefix = "cb_user_identity_", cheader_filename = "Types.h",
          destroy_function = "cb_user_identity_free")]
  public struct UserIdentity {
    public int64 id;
    public string screen_name;
    public string user_name;
    public void parse (Json.Object object);
  }

  /* Needed for unit tests */
  [CCode (cprefix = "CbMediaDownloader", lower_case_cprefix = "cb_media_downloader_",
          cheader_filename = "MediaDownloader.h")]
  public class MediaDownloader : GLib.Object {
    public static unowned MediaDownloader get_default ();
    public async void load_async (Media media);
  }

  [CCode (cprefix = "CbTextEntity", lower_case_cprefix = "cb_text_entity_", cheader_filename = "Types.h",
          destroy_function = "cb_text_entity_free")]
  public struct TextEntity {
    public uint from;
    public uint to;
    public string display_text;
    public string tooltip_text;
    public string? target; // If target is null, use display_text as target!
    public uint info;
  }

  [CCode (cprefix = "CbMiniTweet", lower_case_cprefix = "cb_mini_tweet_", cheader_filename = "Types.h",
          destroy_function = "cb_mini_tweet_free")]
  public struct MiniTweet {
    public int64 id;
    public int64 created_at;
    public Cb.UserIdentity author;
    public string text;
    [CCode (array_length_cname = "n_entities", array_length_type = "size_t")]
    public Cb.TextEntity[] entities;
    [CCode (array_length_cname = "n_medias", array_length_type = "size_t")]
    public Cb.Media[] medias;

    [CCode (cname = "cb_mini_tweet_init")]
    public MiniTweet();
    public void parse (Json.Object obj);
    public void parse_entities (Json.Object status);
  }

  [CCode (cprefix = "CbTweet", lower_case_cprefix = "cb_tweet_", cheader_filename = "CbTweet.h")]
    public class Tweet : GLib.Object {
      [CCode (cname = "CB_TWEET_MAX_LENGTH")]
      public static int MAX_LENGTH;
      public Cb.MiniTweet source_tweet;
      public Cb.MiniTweet? retweeted_tweet;
      public Cb.MiniTweet? quoted_tweet;
      public int64 id;
      public int64 my_retweet;
      public int64 reply_id;
      //public bool seen;
      public int favorite_count;
      public int retweet_count;
      public string avatar_url;

      public Tweet();

      public int64 get_user_id ();
      public unowned string get_screen_name ();
      public unowned string get_user_name ();

      public bool has_inline_media ();
      public void load_from_json (Json.Node node, GLib.DateTime now);

      public bool is_flag_set (uint flag);
      public void set_flag (uint flag);
      public void unset_flag (uint flag);

      public string get_formatted_text (uint transform_flags);
      public string get_trimmed_text (uint transform_flags);
      public string get_real_text ();

      public unowned Cb.Media[] get_medias();
      public string[] get_mentions();

      public signal void state_changed();
      public bool is_hidden ();
      public string? notification_id;

      public bool get_seen ();
      public void set_seen (bool val);

      public uint state;
#if DEBUG
      public string json_data;
#endif
    }

    [CCode (cprefix = "CB_TWEET_STATE_", lower_case_cprefix = "CbTweetState", cheader_filename = "CbTweet.h")]
    [Flags]
    public enum TweetState {
      HIDDEN_FORCE,
      HIDDEN_UNFOLLOWED,
      HIDDEN_FILTERED,
      HIDDEN_RTS_DISABLED,
      HIDDEN_RT_BY_USER,
      HIDDEN_RT_BY_FOLLOWEE,
      HIDDEN_AUTHOR_BLOCKED,
      HIDDEN_RETWEETER_BLOCKED,
      HIDDEN_AUTHOR_MUTED,
      HIDDEN_RETWEETER_MUTED,

      RETWEETED,
      FAVORITED,
      DELETED,
      VERIFIED,
      PROTECTED,
      NSFW
    }

  [CCode (cprefix = "CB_TEXT_TRANSFORM_", lower_case_cprefix = "CbTextTransformFlags", cheader_filename = "TextTransform.h")]
    public enum TransformFlags {
    REMOVE_TRAILING_HASHTAGS,
    EXPAND_LINKS,
    REMOVE_MEDIA_LINKS
  }

  [CCode (cprefix = "cb_text_transform_", cheader_filename = "TextTransform.h")]
  namespace TextTransform {
    string tweet (ref MiniTweet tweet, uint flags, int64 quote_id);
    string text (string text, TextEntity[] entities, uint flags, size_t n_medias, int64 quote_id);
  }


}
