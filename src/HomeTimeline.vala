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

class HomeTimeline : IMessageReceiver, DefaultTimeline {

  public HomeTimeline(int id) {
    base (id);
  }

  private void stream_message_received (StreamMessageType type, Json.Node root) { // {{{
    if (type == StreamMessageType.TWEET) {
      add_tweet (root);
    } else if (type == StreamMessageType.DELETE) {
      int64 id = root.get_object ().get_object_member ("delete")
                     .get_object_member ("status").get_int_member ("id");
      delete_tweet (id);
    } else if (type == StreamMessageType.EVENT_FAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      toggle_favorite (id, true);
    } else if (type == StreamMessageType.EVENT_UNFAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      toggle_favorite (id, false);
    }
  } // }}}

  private void delete_tweet (int64 tweet_id) { // {{{
    foreach (Gtk.Widget w in tweet_list.get_children ()) {
      if (w == null || !(w is TweetListEntry))
        continue;

      var tle = (TweetListEntry) w;
      if (tle.tweet.id == tweet_id) {
        if (!tle.seen) {
          tweet_list.remove (tle);
          unread_count --;
          update_unread_count ();
        }else
          tle.sensitive = false;
        return;
      } else if (tle.tweet.retweeted && tle.tweet.my_retweet == tweet_id) {
        tle.tweet.retweeted = false;
        return;
      }
    }
  } // }}}

  private void toggle_favorite (int64 id, bool mode) {
    var tweets = tweet_list.get_children ();

    foreach (var w in tweets) {
      if (!(w is TweetListEntry))
        continue;
      var t = ((TweetListEntry)w).tweet;
      if (t.id == id) {
        t.favorited = mode;
        break;
      }
    }
  }

  private void add_tweet (Json.Node obj) { // {{{
    GLib.DateTime now = new GLib.DateTime.now_local ();
    Tweet t = new Tweet();
    t.load_from_json (obj, now);

    if (t.is_retweet && !should_display_retweet (obj, t))
      return;

    bool auto_scroll = Settings.auto_scroll_on_new_tweets ();

    this.balance_next_upper_change (TOP);

    var entry = new TweetListEntry(t, main_window, account);
    entry.seen = this.scrolled_up  &&
                 main_window.cur_page_id == this.id &&
                 (t.user_id == account.id || auto_scroll);

    delta_updater.add (entry);
    tweet_list.add(entry);

    if (this.scrolled_up && (t.user_id == account.id || auto_scroll)) {
      this.scroll_up_next (true, false,
                           main_window.cur_page_id != this.id);
    }

    if (!entry.seen) {
      unread_count ++;
      update_unread_count ();
    }


    this.max_id = t.id;

    int stack_size = Settings.get_tweet_stack_count ();
    bool show_notification = !(stack_size == 1 && t.text.contains("@" + account.screen_name));
    if (!show_notification || t.user_id == account.id)
      return;

    message ("Stack size: %d", stack_size);
    message ("Unread count: %d", unread_count);
    if (stack_size == 1) {
      if (t.has_inline_media){
        t.inline_media_added.connect (tweet_inline_media_added_cb);
      } else {
        // calling this with image = null will just create the
        // appropriate notification etc.
        tweet_inline_media_added_cb (t, null);
      }
    } else if(stack_size != 0 && unread_count % stack_size == 0
              && unread_count > 0) {
      string summary = _("%d new Tweets!").printf (unread_count);
      NotificationManager.notify (summary);
    }
  } // }}}

  /**
   * Determines whether the given tweet should be displayed.
   * This is only important for retweets which should not be
   * shown if, e.g., the user himself retweeted the original tweet, etc.
   *
   * @param root_node The Json.Node representing the root node of the tweet's json data
   * @param t The tweet object constructed from the given root_node
   *
   * @return false if the (re)tweet should not be shown, true otherwise.
   */
  private bool should_display_retweet (Json.Node root_node, Tweet t) { // {{{

    // Don't show if the user was retweeted
    if (t.user_id == account.id)
      return false;


    // Don't show tweets the user retweeted again

    /* If the tweet is a tweet the user retweeted, check
       if it's already in the list. If so, mark it retweeted */
    if (t.retweeted_by == account.name) {
      foreach (Gtk.Widget w in tweet_list.get_children ()) {
        if (w == null || !(w is TweetListEntry))
          continue;

        var tle = (TweetListEntry) w;
        if (tle.tweet.id == t.rt_id) {
          tle.tweet.retweeted = true;
          tle.tweet.my_retweet = t.id;
        }
      }
      return false;
    }

    // Don't show it if the user already follows the retweeted user
//    if (root_node.get_object ().get_object_member ("retweeted_status").get_object_member ("user")
//        .get_boolean_member ("following")) {
//      return false;
//    }
    // XXX Fun: 'following' is just null if the tweet is a retweet, yay!

    // Check if the original tweet already exists in the timeline
    foreach (Gtk.Widget w in tweet_list.get_children ()) {
      if (w == null || !(w is TweetListEntry))
        continue;;

      var tle = (TweetListEntry) w;
      if (tle.tweet.id == t.rt_id || tle.tweet.rt_id == t.rt_id)
        return false;
    }

    return true;
  } // }}}

  // Will be called once the inline media of a tweet has been loaded.
  private void tweet_inline_media_added_cb (Tweet t, Gdk.Pixbuf? image) {
    string summary = "";
    if (t.is_retweet){
      summary = _("%s retweeted %s").printf(t.retweeted_by, t.user_name);
    } else {
      summary = _("%s tweeted").printf(t.user_name);
    }
    NotificationManager.notify (summary, t.get_real_text (), Notify.Urgency.NORMAL,
                                Utils.user_file ("assets/avatars/" + t.avatar_name),
                                t.media);

  }


  public override void load_newest () {
    this.loading = true;
    this.load_newest_internal.begin ("1.1/statuses/home_timeline.json",  () => {
      this.loading = false;
    });
  }

  public override void load_older () {
    this.balance_next_upper_change (BOTTOM);
    main_window.start_progress ();
    this.loading = true;
    this.load_older_internal.begin ("1.1/statuses/home_timeline.json", () => {
      this.loading = false;
      main_window.stop_progress ();
    });
  }

  public override void create_tool_button(RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "corebird-stream-symbolic");
    tool_button.tooltip_text = _("Home");
    tool_button.label = _("Home");
  }
}
