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

public class HomeTimeline : IMessageReceiver, DefaultTimeline {
  protected override string function {
    get {
      return "1.1/statuses/home_timeline.json";
    }
  }

  public HomeTimeline(int id) {
    base (id);
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) { // {{{
    if (type == StreamMessageType.TWEET) {
      add_tweet (root);
    } else if (type == StreamMessageType.DELETE) {
      int64 id = root.get_object ().get_object_member ("delete")
                     .get_object_member ("status").get_int_member ("id");
      delete_tweet (id);
    } else if (type == StreamMessageType.EVENT_FAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      int64 source_id = root.get_object ().get_object_member ("source").get_int_member ("id");
      if (source_id == account.id)
        toggle_favorite (id, true);
    } else if (type == StreamMessageType.EVENT_UNFAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      int64 source_id = root.get_object ().get_object_member ("source").get_int_member ("id");
      if (source_id == account.id)
        toggle_favorite (id, false);
    }
  } // }}}

  // TODO: Split this logic out and make it unit-testable
  private void add_tweet (Json.Node obj) { // {{{
    GLib.DateTime now = new GLib.DateTime.now_local ();
    Tweet t = new Tweet();
    t.load_from_json (obj, now, account);

    if (t.is_retweet && !should_display_retweet (t))
      return;

    if (account.filter_matches (t))
      return;

    bool auto_scroll = Settings.auto_scroll_on_new_tweets ();

    this.balance_next_upper_change (TOP);

    var entry = new TweetListEntry (t, main_window, account);
    entry.seen =  t.user_id == account.id ||
                  (this.scrolled_up  &&
                   main_window.cur_page_id == this.id &&
                   auto_scroll);

    delta_updater.add (entry);
    tweet_list.add(entry);

    base.scroll_up (t);
    base.postprocess_tweet (entry);

    // We never show any notifications if auto-scroll-on-new-tweet is enabled
    int stack_size = Settings.get_tweet_stack_count ();
    if (t.user_id == account.id || auto_scroll)
      return;

    if (stack_size == 1 && !auto_scroll) {
      if (t.has_inline_media){
        //t.inline_media_added.connect (tweet_inline_media_added_cb);
      } else {
        // calling this with image = null will just create the
        // appropriate notification etc.
        tweet_inline_media_added_cb (t, null);
      }
    } else if(stack_size != 0 && unread_count % stack_size == 0
              && unread_count > 0) {
      string summary = _("%d new Tweets!").printf (unread_count);
      NotificationManager.notify (account, summary);
    }
  } // }}}


  // Will be called once the inline media of a tweet has been loaded.
  private void tweet_inline_media_added_cb (Tweet t, Gdk.Pixbuf? image) {
    string summary = "";
    if (t.is_retweet){
      summary = _("%s retweeted %s").printf(t.retweeted_by, t.user_name);
    } else {
      summary = _("%s tweeted").printf(t.user_name);
    }
    NotificationManager.notify (account, summary, t.get_real_text (),
                                Dirs.cache ("assets/avatars/" + t.avatar_name));

  }

  public override string? get_title () {
    return "@" + account.screen_name;
  }

  public override void load_newest () {
    this.loading = true;
    this.load_newest_internal.begin (() => {
      this.loading = false;
    });
  }

  public override void load_older () {
    this.balance_next_upper_change (BOTTOM);
    main_window.start_progress ();
    this.loading = true;
    this.load_older_internal.begin (() => {
      this.loading = false;
      main_window.stop_progress ();
    });
  }

  public override void create_tool_button (Gtk.RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "corebird-stream-symbolic");
    tool_button.tooltip_text = _("Home");
    tool_button.label = _("Home");
  }
}
