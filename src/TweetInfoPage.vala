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
[GtkTemplate (ui = "/org/baedert/corebird/ui/tweet-info-page.ui")]
class TweetInfoPage : IPage , ScrollWidget {
  public static const uint BY_INSTANCE = 1;
  public static const uint BY_ID       = 2;

  public int unread_count { get{return 0;} set {} }
  private int id;
  public unowned MainWindow main_window { get; set; }
  public unowned Account account { get; set; }
  private int64 tweet_id;
  private bool values_set = false;
  private Tweet tweet;
  private bool following;

  [GtkChild]
  private Label text_label;
  [GtkChild]
  private Label name_label;
  [GtkChild]
  private Label screen_name_label;
  [GtkChild]
  private Image avatar_image;
  [GtkChild]
  private Label rt_fav_label;
  [GtkChild]
  private ListBox bottom_list_box;
  [GtkChild]
  private Spinner progress_spinner;
  [GtkChild]
  private ToggleButton favorite_button;
  [GtkChild]
  private ToggleButton retweet_button;
  [GtkChild]
  private Button follow_button;
  [GtkChild]
  private Label time_label;
  [GtkChild]
  private PixbufButton media_button;
  [GtkChild]
  private Gtk.MenuItem delete_menu_item;

  public TweetInfoPage (int id) {
    this.id = id;
    this.button_press_event.connect (button_pressed_event_cb);
  }

  public void on_join (int page_id, va_list args){
    uint mode = args.arg ();

    if (mode == 0)
      return;

    values_set = false;


    bottom_list_box.foreach ((w) => {bottom_list_box.remove (w);});
    bottom_list_box.hide ();
    progress_spinner.hide ();
    media_button.hide ();


    if (mode == BY_INSTANCE) {
      this.tweet = args.arg ();
      this.tweet_id = tweet.id;
      set_tweet_data (tweet);
    } else if (mode == BY_ID) {
      this.tweet_id = args.arg ();
    }
    query_tweet_info ();
  }

  public void on_leave () {

  }


  [GtkCallback]
  private void favorite_button_toggled_cb () {
    if (!values_set)
      return;

    favorite_button.sensitive = false;
    TweetUtils.toggle_favorite_tweet.begin (account, tweet, !favorite_button.active, () => {
        favorite_button.sensitive = true;
    });
  }

  [GtkCallback]
  private void retweet_button_toggled_cb () {
    if (!values_set)
      return;
    retweet_button.sensitive = false;
    TweetUtils.toggle_retweet_tweet.begin (account, tweet, !retweet_button.active, () => {
      retweet_button.sensitive = true;
    });
  }

  [GtkCallback]
  private void reply_button_clicked_cb () {
    ComposeTweetWindow ctw = new ComposeTweetWindow(main_window, this.account, this.tweet,
                                                    ComposeTweetWindow.Mode.REPLY);
    ctw.show ();
  }

  [GtkCallback]
  private void quote_item_activate_cb () {
    ComposeTweetWindow ctw = new ComposeTweetWindow(main_window, this.account, this.tweet,
                                                    ComposeTweetWindow.Mode.QUOTE);
    ctw.show ();
  }

  [GtkCallback]
  private void delete_item_activate_cb () {
    error ("Show confirmation dialog, then delete tweet");
//    TweetUtils.
  }

  [GtkCallback]
  private void follow_button_clicked_cb () {
    var call = account.proxy.new_call();
    if (following)
      call.set_function ("1.1/friendships/create.json");
    else
      call.set_function( "1.1/friendships/destroy.json");
    call.set_method ("POST");
    call.add_param ("follow", "true");
    call.add_param ("id", tweet.user_id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try {
        set_follow_button_state (!following);
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        critical (e.message);
      }
    });
  }

  [GtkCallback]
  private bool link_activated_cb (string uri) {
    return TweetUtils.activate_link (uri, main_window);
  }


  /**
   * Loads the data of the tweet with the id tweet_id from the Twitter server.
   */
  private void query_tweet_info () { //{{{
    var call = account.proxy.new_call ();
    call.set_method ("GET");
    call.set_function ("1.1/statuses/show.json");
    call.add_param ("id", tweet_id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try{call.invoke_async.end (res);}catch(GLib.Error e){critical(e.message);return;}
      var now = new GLib.DateTime.now_local ();
      this.tweet = new Tweet ();
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }
      tweet.load_from_json (parser.get_root (), now);
      Json.Object root_object = parser.get_root ().get_object ();
      if (root_object.has_member ("retweeted_status"))
        this.following = root_object.get_object_member ("retweeted_status")
                                    .get_object_member ("user").get_boolean_member ("following");
      else
        this.following = root_object.get_object_member ("user").get_boolean_member ("following");

      string with = root_object.get_string_member ("source");
      with = extract_source (with);
      set_tweet_data (tweet, following, with);
      if (!root_object.get_null_member ("place"))
        screen_name_label.label += " in " + root_object.get_string_member ("place");

      if (tweet.reply_id != 0) {
        progress_spinner.show();
        progress_spinner.start ();
        load_replied_to_tweet (tweet.reply_id);
      }
      values_set = true;
    });

  } //}}}

  /**
   * Loads the tweet this tweet is a reply to.
   * This will recursively call itself until the end of the chain is reached.
   *
   * @param reply_id The id of the tweet the previous tweet was a reply to.
   */
  private void load_replied_to_tweet (int64 reply_id) { //{{{
    if (reply_id == 0) {
      progress_spinner.stop ();
      progress_spinner.hide ();
      return;
    }

    bottom_list_box.show ();
    var call = account.proxy.new_call ();
    call.set_function ("1.1/statuses/show.json");
    call.set_method ("GET");
    call.add_param ("id", reply_id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try{call.invoke_async.end (res);message("code: %u", call.get_status_code ());}catch(GLib.Error e){
      critical(e.message);progress_spinner.hide ();return;}

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }
      Tweet tweet = new Tweet ();
      tweet.load_from_json (parser.get_root (), new GLib.DateTime.now_local ());
      bottom_list_box.add (new TweetListEntry (tweet, main_window, account));
      load_replied_to_tweet (tweet.reply_id);
    });
  } //}}}

  /**
   *
   */
  private void set_tweet_data (Tweet tweet, bool following = false, string? with = null) {//{{{
    GLib.DateTime created_at = new GLib.DateTime.from_unix_local (tweet.created_at);
    string time_format = created_at.format ("%x, %X");
    if (with != null) {
      time_format += " via " + with;
    }

    text_label.label = "<b><big><big><big>"+tweet.get_formatted_text ()+"</big></big></big></b>";
    name_label.label = tweet.user_name;
    screen_name_label.label = "@" + tweet.screen_name;
    avatar_image.pixbuf = tweet.avatar;
    rt_fav_label.label = "<big><b>%'d</b></big> Retweets  <big><b>%'d</b></big> Favorites"
                         .printf (tweet.retweet_count, tweet.favorite_count);
    time_label.label = time_format;
    retweet_button.active = tweet.retweeted;
    favorite_button.active = tweet.favorited;

    // TODO: Also do this on inline_media_added signal
    if (tweet.has_inline_media) {
      media_button.show ();
      media_button.set_bg (tweet.inline_media);
      media_button.clicked.connect (() => {
        ImageDialog id = new ImageDialog (main_window, tweet.media);
        id.show_all ();
      });
    }

    if (tweet.user_id == account.id) {
      follow_button.hide ();
      delete_menu_item.show ();
      retweet_button.hide ();
    } else {
      set_follow_button_state (following);
      follow_button.show ();
      delete_menu_item.hide ();
      retweet_button.show ();
    }
  } //}}}

  private void set_follow_button_state (bool following) {
    var sc = follow_button.get_style_context ();
    if (following) {
      sc.remove_class ("suggested-action");
      sc.add_class ("destructive-action");
      follow_button.label = _("Unfollow");
    } else {
      sc.remove_class ("destructive-action");
      sc.add_class ("suggested-action");
      follow_button.label = _("Follow");
    }
    this.following = following;
  }

  /**
   * Twitter's source parameter of tweets includes a 'rel' parameter
   * that doesn't work as pango markup, so we just remove it here.
   *
   * Example string:
   *   <a href=\"http://www.tweetdeck.com\" rel=\"nofollow\">TweetDeck</a>
   *
   * @param source_str The source string from twitter
   *
   * @return The #source_string without the rel parameter
   */
  private string extract_source (string source_str) {
    int from, to;
    int tmp = 0;
    tmp = source_str.index_of_char ('"');
    tmp = source_str.index_of_char ('"', tmp + 1);
    from = source_str.index_of_char ('"', tmp + 1);
    to = source_str.index_of_char ('"', from + 1);
    if (to == -1 || from == -1)
      return source_str;
    return source_str.substring (0, from-5) + source_str.substring(to + 1);
  }



  public int get_id () {
    return id;
  }
  public void create_tool_button (Gtk.RadioToolButton? group) {}
  public Gtk.RadioToolButton? get_tool_button () {
    return null;
  }
}
