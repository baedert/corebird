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

  private void add_tweet (Json.Node obj) { // {{{
    GLib.DateTime now = new GLib.DateTime.now_local ();
    Tweet t = new Tweet();
    t.load_from_json (obj, now, account);


    var entry = new TweetListEntry (t, main_window, account);
    entry.visible = true;

    if (t.is_retweet && !should_display_retweet (t))
      entry.visible = false;

    if (account.blocked_or_muted (t.user_id) ||
        (t.is_retweet && account.blocked_or_muted (t.rt_by_id)))
      entry.visible = false;

    if (account.filter_matches (t))
      entry.visible = false;

    bool auto_scroll = Settings.auto_scroll_on_new_tweets ();

    this.balance_next_upper_change (TOP);

    entry.seen =  t.user_id == account.id ||
                  t.rt_by_id == account.id ||
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
      string summary = "";
      if (t.is_retweet){
        summary = _("%s retweeted %s").printf(t.retweeted_by, t.user_name);
      } else {
        summary = _("%s tweeted").printf(t.user_name);
      }
      NotificationManager.notify (account, summary, t.get_real_text (),
                                  Dirs.cache ("assets/avatars/" + t.avatar_name));

    } else if(stack_size != 0 && unread_count % stack_size == 0
              && unread_count > 0) {
      string summary = ngettext("%d new Tweet!",
                                "%d new Tweets!", unread_count).printf (unread_count);
      NotificationManager.notify (account, summary);
    }
  } // }}}


  public void hide_tweets_from (int64 user_id) {
    GLib.List<unowned Gtk.Widget> children = tweet_list.get_children ();
    foreach (Gtk.Widget w in children) {
      if (!(w is TweetListEntry))
        continue;

      TweetListEntry tle = (TweetListEntry) w;
      if (tle.tweet.user_id == user_id && !tle.tweet.is_retweet) {
        tle.hide ();
      } else if (tle.tweet.user_id == user_id &&
                 tle.tweet.is_retweet) {
        tle.show ();
      }

    }
  }

  public void show_tweets_from (int64 user_id) {
    GLib.List<unowned Gtk.Widget> children = tweet_list.get_children ();
    foreach (Gtk.Widget w in children) {
      if (!(w is TweetListEntry))
        continue;

      TweetListEntry tle = (TweetListEntry) w;
      if (tle.tweet.user_id == user_id && !tle.visible) {
        tle.show ();
      }

    }
  }

  public void hide_retweets_from (int64 user_id) {
    GLib.List<unowned Gtk.Widget> children = tweet_list.get_children ();
    foreach (Gtk.Widget w in children) {
      if (!(w is TweetListEntry))
        continue;

      TweetListEntry tle = (TweetListEntry) w;
      if (tle.tweet.rt_by_id == user_id && tle.tweet.is_retweet) {
        tle.hide ();
      }

    }
  }

  public void show_retweets_from (int64 user_id) {
    GLib.List<unowned Gtk.Widget> children = tweet_list.get_children ();
    foreach (Gtk.Widget w in children) {
      if (!(w is TweetListEntry))
        continue;

      TweetListEntry tle = (TweetListEntry) w;
      if (tle.tweet.rt_by_id == user_id && tle.tweet.is_retweet && !tle.visible) {
        tle.show ();
      }

    }
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
    this.loading = true;
    this.load_older_internal.begin (() => {
      this.loading = false;
    });
  }

  public override void create_tool_button (Gtk.RadioButton? group) {
    tool_button = new BadgeRadioToolButton(group, "user-home-symbolic", _("Home"));
  }
}
