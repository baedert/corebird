
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

  [CCode (cprefix = "CB_STREAM_MESSAGE_", cheader_filename = "CbUserStream.h")]
  public enum StreamMessageType {
    UNSUPPORTED,
    DELETE,
    DM_DELETE,
    SCRUB_GEO,
    LIMIT,
    DISCONNECT,
    FRIENDS,
    EVENT,
    WARNING,
    DIRECT_MESSAGE,

    TWEET,
    EVENT_LIST_CREATED,
    EVENT_LIST_DESTROYED,
    EVENT_LIST_UPDATED,
    EVENT_LIST_UNSUBSCRIBED,
    EVENT_LIST_SUBSCRIBED,
    EVENT_LIST_MEMBER_ADDED,
    EVENT_LIST_MEMBER_REMOVED,
    EVENT_FAVORITE,
    EVENT_UNFAVORITE,
    EVENT_FOLLOW,
    EVENT_UNFOLLOW,
    EVENT_BLOCK,
    EVENT_UNBLOCK,
    EVENT_MUTE,
    EVENT_UNMUTE,
    EVENT_USER_UPDATE,
    EVENT_QUOTED_TWEET
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
    public Gsk.Texture texture;
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
    public bool verified;
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
    public uint display_range_start;
    public int64 reply_id;
    public Cb.UserIdentity author;
    public string text;
    [CCode (array_length_cname = "n_entities", array_length_type = "size_t")]
    public Cb.TextEntity[] entities;
    [CCode (array_length_cname = "n_medias", array_length_type = "size_t")]
    public Cb.Media[] medias;
    [CCode (array_length_cname = "n_reply_users", array_length_type = "size_t")]
    public Cb.UserIdentity[] reply_users;

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

      public unowned Cb.UserIdentity[] get_reply_users ();

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
    string text (string text, TextEntity[] entities, uint flags, size_t n_medias, int64 quote_id, uint display_range_start = 0);
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
    public void scroll_to (double x, double y);
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

  [CCode (cprefix = "CbMessageReceiverInterface_", lower_case_cprefix = "cb_message_receiver_", cheader_filename =
          "CbMessageReceiver.h", type_cname = "CbMessageReceiverInterface")]
  public interface MessageReceiver : GLib.Object {
    public abstract void stream_message_received (Cb.StreamMessageType type,
                                                  Json.Node node);
  }


  [CCode (cprefix = "CbDeltaUpdater_", lower_case_cprefix = "cb_delta_updater_", cheader_filename =
          "CbDeltaUpdater.h")]
  public class DeltaUpdater : GLib.Object {
    public DeltaUpdater (Gtk.Widget listbox);
  }

  [CCode (cprefix = "CbUtils_", lower_case_cprefix = "cb_utils_", cheader_filename =
          "CbUtils.h")]
  namespace Utils {
    public delegate Gtk.Widget CreateWidgetFunc (void *item);
    public void bind_model (Gtk.Widget listbox, GLib.ListModel model, Gtk.ListBoxCreateWidgetFunc func);
    public void bind_non_gobject_model (Gtk.Widget listbox, GLib.ListModel model, Cb.Utils.CreateWidgetFunc func);
    public void unbind_non_gobject_model (Gtk.Widget *listbox, GLib.ListModel model);
    public void linkify_user (ref Cb.UserIdentity id, GLib.StringBuilder str);
    public void write_reply_text (ref Cb.MiniTweet t, GLib.StringBuilder str);
    public GLib.DateTime parse_date (string _in);
    public string get_file_type (string url);
    public string rest_proxy_call_to_string (Rest.ProxyCall c);
    public async Json.Node? load_threaded_async (Rest.ProxyCall call, GLib.Cancellable? cancellable) throws GLib.Error;
    public async UserIdentity[] query_users_async (Rest.Proxy p, string q, GLib.Cancellable? cancellable) throws GLib.Error;
    public Gsk.Texture surface_to_texture (Cairo.Surface s, int scale);
  }

  [CCode (cprefix = "CbBundle_", lower_case_cprefix = "cb_bundle_", cheader_filename =
          "CbBundle.h")]
  public class Bundle : GLib.Object {
    public Bundle ();

    public void put_string (int key, string val);
    public unowned string get_string (int key);

    public void put_int (int key, int val);
    public int get_int (int key);

    public void put_int64 (int key, int64 val);
    public int64 get_int64 (int key);

    public void put_bool (int key, bool val);
    public bool get_bool (int key);

    public void put_object (int key, GLib.Object val);
    public unowned GLib.Object get_object (int key);

    public bool equals (Bundle? other);
  }

  [CCode (cprefix = "CbBundleHistory_", lower_case_cprefix = "cb_bundle_history_", cheader_filename =
          "CbBundleHistory.h")]
  public class BundleHistory : GLib.Object {
    public BundleHistory ();

    public void push (int v, Cb.Bundle? b);
    public int forward ();
    public int back ();
    public bool at_start ();
    public bool at_end ();

    public void remove_current ();

    public int get_current ();
    public unowned Cb.Bundle? get_current_bundle ();

  }
  [CCode (cprefix = "CbSnippetManager_", lower_case_cprefix = "cb_snippet_manager_", cheader_filename =
          "CbSnippetManager.h")]
  public class SnippetManager : GLib.Object {
    public SnippetManager (Sqlite.Database db);
    public unowned string get_snippet (string key);
    public bool has_snippet_n (string key, size_t key_len);
    public uint n_snippets ();
    public void query_snippets (GLib.HFunc func);
    public void set_snippet (string old_key, string key, string value);
    public void remove_snippet (string key);
    public void insert_snippet (string key, string value);
  }
  [CCode (cprefix = "CbMediaVideoWidget_", lower_case_cprefix = "cb_media_video_widget_", cheader_filename =
          "CbMediaVideoWidget.h")]
  public class MediaVideoWidget : Gtk.Stack {
    public MediaVideoWidget (Media media);
    public void start ();
  }

  [CCode (cprefix = "CbUserStream_", lower_case_cprefix = "cb_user_stream_", cheader_filename =
          "CbUserStream.h")]
  public class UserStream : GLib.Object {
    public UserStream (string name, bool b);
    public void register (MessageReceiver r);
    public void unregister (MessageReceiver r);
    public void push_data (string data);
    public void start ();
    public void stop ();
    public void set_proxy_data (string a, string b);

    public signal void interrupted ();
    public signal void resumed ();
  }

  [CCode (cprefix = "CbComposeJob_", lower_case_cprefix = "cb_compose_job_", cheader_filename =
          "CbComposeJob.h")]
  public class ComposeJob : GLib.Object {
    public signal void image_upload_progress (string a, double d);
    public signal void image_upload_finished (string a, string? b);
    public ComposeJob (Rest.Proxy proxy, Rest.Proxy proxy2, GLib.Cancellable cancellable);
    public void set_reply_id (int64 id);
    public void set_quoted_tweet (Cb.Tweet t);
    public void set_text (string s);
    public void upload_image_async (string p);
    public void abort_image_upload (string s);
    public async bool send_async (GLib.Cancellable c) throws GLib.Error;
  }

  [CCode (cprefix = "CbUserCompletionModel_", lower_case_cprefix = "cb_user_completion_model_", cheader_filename =
          "CbUserCompletionModel.h")]
  public class UserCompletionModel : GLib.Object, GLib.ListModel {
    public UserCompletionModel ();
    public void insert_infos (Cb.UserInfo[] infos);
    public void insert_items (Cb.UserIdentity[] ids);
    public void clear ();
  }

  [CCode (cprefix = "CbEmojiChooser_", lower_case_cprefix = "cb_emoji_chooser_", cheader_filename =
          "CbEmojiChooser.h")]
  public class EmojiChooser : Gtk.Box {
    public EmojiChooser ();
    public void populate ();
    public bool try_init ();
    public signal void emoji_picked (string emoji);
  }

  [CCode (cprefix = "CbTweetRow_", lower_case_cprefix = "cb_tweet_row_", cheader_filename =
          "CbTweetRow.h")]
  public class TweetRow : Gtk.ListBoxRow {
    public TweetRow (Tweet tweet, MainWindow toplevel);//, Account account);
    public Tweet tweet;
  }

  [CCode (cprefix = "CbTextView_", lower_case_cprefix = "cb_text_view_", cheader_filename =
          "CbTextView.h")]
  public class TextView : Gtk.Widget {
    public TextView ();
    public void set_account (Account acc);
    public void add_widget (Gtk.Widget widget);
    public void insert_at_cursor (string s);
    public void set_text (string s);
  }

}
