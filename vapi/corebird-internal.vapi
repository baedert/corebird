
[CCode (cprefix = "Cb", lower_case_cprefix = "cb_")]
namespace Cb {
  [CCode (cprefix = "CB_MEDIA_TYPE_", cheader_filename = "CbMedia.h")]
  public enum MediaType {
    IMAGE,
    GIF,
    ANIMATED_GIF,
    TWITTER_VIDEO,
    INSTAGRAM_VIDEO,

    UNKNOWN
  }

  [CCode (cprefix = "CbMedia_", lower_case_cprefix = "cb_media_", cheader_filename = "CbMedia.h")]
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
    public double percent_loaded;
    public Cairo.ImageSurface? surface;
    public Gdk.PixbufAnimation? animation;
    public signal void progress();

    public Media();
    public bool is_video ();
  }

  [CCode (cprefix = "CbUserIdentity_", lower_case_cprefix = "cb_user_identity_", cheader_filename = "CbTypes.h",
          destroy_function = "cb_user_identity_free")]
  public struct UserIdentity {
    public int64 id;
    public string screen_name;
    public string user_name;
    public void parse (Json.Object object);
  }

  /* Needed for unit tests */
  [CCode (cprefix = "CbMediaDownloader", lower_case_cprefix = "cb_media_downloader_",
          cheader_filename = "CbMediaDownloader.h")]
  public class MediaDownloader : GLib.Object {
    public static unowned MediaDownloader get_default ();
    public async void load_async (Media media);
    public void disable ();
    public void shutdown ();
  }

  [CCode (cprefix = "CbTextEntity", lower_case_cprefix = "cb_text_entity_", cheader_filename = "CbTypes.h",
          destroy_function = "cb_text_entity_free")]
  public struct TextEntity {
    public uint from;
    public uint to;
    public string display_text;
    public string tooltip_text;
    public string? target; // If target is null, use display_text as target!
    public uint info;
  }

  [CCode (cprefix = "CbMiniTweet", lower_case_cprefix = "cb_mini_tweet_", cheader_filename = "CbTypes.h",
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
      public int favorite_count;
      public int retweet_count;
      public string avatar_url;

      public Tweet();

      public int64 get_user_id ();
      public unowned string get_screen_name ();
      public unowned string get_user_name ();

      public bool has_inline_media ();
      public void load_from_json (Json.Node node, int64 account_id, GLib.DateTime now);

      public bool is_flag_set (uint flag);
      public void set_flag (uint flag);
      public void unset_flag (uint flag);

      public string get_formatted_text ();
      public string get_trimmed_text (uint transform_flags);
      public string get_real_text ();
      public string get_filter_text ();

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

  [CCode (cprefix = "CB_TEXT_TRANSFORM_", lower_case_cprefix = "CbTextTransformFlags", cheader_filename = "CbTextTransform.h")]
  public enum TransformFlags {
    REMOVE_TRAILING_HASHTAGS,
    EXPAND_LINKS,
    REMOVE_MEDIA_LINKS
  }

  [CCode (cprefix = "cb_text_transform_", cheader_filename = "CbTextTransform.h")]
  namespace TextTransform {
    string tweet (ref MiniTweet tweet, uint flags, int64 quote_id);
    string text (string text, TextEntity[] entities, uint flags, size_t n_medias, int64 quote_id);
  }

  [CCode (cprefix = "cb_filter_", cheader_filename = "CbFilter.h")]
  public class Filter : GLib.Object {
    public Filter(string expr);
    public bool matches (string text);
    public void reset (string expr);
    public unowned string get_contents();
    public int get_id ();
    public void set_id (int id);
  }

  [CCode (cprefix = "cb_avatar_cache_", cheader_filename = "CbAvatarCache.h")]
  class AvatarCache : GLib.Object {
    public AvatarCache ();
    public void add (int64 user_id, Cairo.Surface? surface, string? avatar_url);
    public void increase_refcount_for_surface (Cairo.Surface surface);
    public void decrease_refcount_for_surface (Cairo.Surface surface);
    public void set_url (int64 user_id, string url);
    public void set_avatar (int64 user_id, Cairo.Surface? surface, string url);
    public unowned Cairo.Surface? get_surface_for_id (int64 user_id, out bool found);
    public unowned string? get_url_for_id (int64 user_id);
    public uint get_n_entries ();
  }

  [CCode (cprefix = "cb_user_counter_", cheader_filename = "CbUserCounter.h")]
  public class UserCounter : GLib.Object {
    public UserCounter ();
    public void id_seen (ref Cb.UserIdentity id);
    public void user_seen (int64 id, string screen_name, string user_name);
    public int save (Sqlite.Database db);
    public void query_by_prefix (Sqlite.Database db,
                                 string prefix,
                                 int max_results,
                                 out Cb.UserInfo[] infos);
  }

  [CCode (cheader_filename = "CbUserCounter.h")]
  public struct UserInfo {
    int64 user_id;
    string screen_name;
    string user_name;
    int score;
    bool changed;
  }


  [CCode (cprefix = "CbMediaImageWidget_", lower_case_cprefix = "cb_media_image_widget_", cheader_filename =
          "CbMediaImageWidget.h")]
  public class MediaImageWidget : Gtk.ScrolledWindow {
    public MediaImageWidget (Media media);
  }

  [CCode (cprefix = "CbTweetModel_", lower_case_cprefix = "cb_tweet_model_", cheader_filename =
          "CbTweetModel.h")]
  public class TweetModel : GLib.Object, GLib.ListModel {
    public int64 min_id;
    public int64 max_id;
    public GLib.GenericArray<Tweet> hidden_tweets;

    public TweetModel ();
    public bool contains_id (int64 id);
    public void clear ();
    public unowned Tweet? get_for_id (int64 id, int diff = -1);
    public void add (Tweet t);
    public void remove_last_n_visible (uint amount);
    public bool delete_id (int64 id, out bool seen);
    public bool set_tweet_flag (Tweet t, TweetState flag);
    public bool unset_tweet_flag (Tweet t, TweetState flag);
    public void remove_tweet (Tweet t);
    public void remove_tweets_above (int64 id);
    public void toggle_flag_on_user_tweets (int64 user_id, TweetState flag, bool active);
    public void toggle_flag_on_user_retweets (int64 user_id, TweetState flag, bool active);
  }

  [CCode (cprefix = "CbTwitterItemInterface_", lower_case_cprefix = "cb_twitter_item_", cheader_filename =
          "CbTwitterItem.h", type_cname = "CbTwitterItemInterface")]
  public interface TwitterItem : GLib.Object {
    public abstract int64 get_sort_factor();
    public abstract int64 get_timestamp();
    public abstract int update_time_delta (GLib.DateTime? now = null);
    public abstract void set_last_set_timediff (GLib.TimeSpan span);
    public abstract GLib.TimeSpan get_last_set_timediff ();
  }

  [CCode (cprefix = "CbDeltaUpdater_", lower_case_cprefix = "cb_delta_updater_", cheader_filename =
          "CbDeltaUpdater.h")]
  public class DeltaUpdater : GLib.Object {
    public DeltaUpdater (Gtk.Widget listbox);
  }

  [CCode (cprefix = "CbUtils_", lower_case_cprefix = "cb_utils_", cheader_filename =
          "CbUtils.h")]
  namespace Utils {
    public void bind_model (Gtk.Widget listbox, GLib.ListModel model, Gtk.ListBoxCreateWidgetFunc func);
    public GLib.DateTime parse_date (string _in);
  }
}
