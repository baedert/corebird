
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
