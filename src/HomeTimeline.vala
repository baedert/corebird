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

  public HomeTimeline(int id, Account account) {
    base (id);
    this.account = account;
    this.tweet_list.account = account;
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
    } else if (type == StreamMessageType.EVENT_BLOCK) {
      int64 user_id = root.get_object ().get_object_member ("target").get_int_member ("id");
      hide_tweets_from (user_id, TweetState.HIDDEN_AUTHOR_BLOCKED);
    } else if (type == StreamMessageType.EVENT_UNBLOCK) {
      int64 user_id = root.get_object ().get_object_member ("target").get_int_member ("id");
      show_tweets_from (user_id, TweetState.HIDDEN_AUTHOR_BLOCKED);
    }
  } // }}}

  private void add_tweet (Json.Node obj) { // {{{
    GLib.DateTime now = new GLib.DateTime.now_local ();
    Tweet t = new Tweet();
    t.load_from_json (obj, now, account);

    if (t.retweeted_tweet != null)
      t.set_flag (get_rt_flags (t));

    if (account.blocked_or_muted (t.user_id))
      t.set_flag (TweetState.HIDDEN_RETWEETER_BLOCKED);


    if (t.retweeted_tweet != null && account.blocked_or_muted (t.retweeted_tweet.author.id))
      t.set_flag (TweetState.HIDDEN_AUTHOR_BLOCKED);

    if (account.filter_matches (t))
      t.set_flag (TweetState.HIDDEN_FILTERED);

    bool auto_scroll = Settings.auto_scroll_on_new_tweets ();

    t.seen = t.user_id == account.id ||
             (t.retweeted_tweet != null && t.retweeted_tweet.author.id == account.id) ||
             (this.scrolled_up  &&
              main_window.cur_page_id == this.id &&
              auto_scroll);

    bool should_focus = (tweet_list.get_first_visible_row ().is_focus && this.scrolled_up);

    tweet_list.model.add (t);

    if (!t.is_hidden) {
      this.balance_next_upper_change (TOP);

      if (!base.scroll_up (t))

      if (!t.seen)
        this.unread_count ++;
    }

    if (should_focus) {
      tweet_list.get_first_visible_row ().grab_focus ();
    }

    // We never show any notifications if auto-scroll-on-new-tweet is enabled

    int stack_size = Settings.get_tweet_stack_count ();
    if (t.user_id == account.id || auto_scroll)
      return;

    if (stack_size == 1 && !auto_scroll) {
      string summary = "";
      if (t.retweeted_tweet != null){
        summary = _("%s retweeted %s").printf (t.source_tweet.author.user_name,
                                               t.retweeted_tweet.author.user_name);
      } else {
        summary = _("%s tweeted").printf (t.source_tweet.author.user_name);
      }
      NotificationManager.notify (account, summary, t.get_real_text ());

    } else if(stack_size != 0 && unread_count % stack_size == 0
              && unread_count > 0) {
      string summary = ngettext("%d new Tweet!",
                                "%d new Tweets!", unread_count).printf (unread_count);
      NotificationManager.notify (account, summary);
    }
  } // }}}


  public void hide_tweets_from (int64 user_id, TweetState reason) {
    TweetModel tm = (TweetModel) tweet_list.model;

    tm.toggle_flag_on_tweet (user_id, reason, true);
  }

  public void show_tweets_from (int64 user_id, TweetState reason) {
    TweetModel tm = (TweetModel) tweet_list.model;

    tm.toggle_flag_on_tweet (user_id, reason, false);
  }

  public void hide_retweets_from (int64 user_id, TweetState reason) {
    TweetModel tm = (TweetModel) tweet_list.model;

    tm.toggle_flag_on_retweet (user_id, reason, true);
  }

  public void show_retweets_from (int64 user_id, TweetState reason) {
    TweetModel tm = (TweetModel) tweet_list.model;

    tm.toggle_flag_on_retweet (user_id, reason, false);
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

  public override void create_radio_button (Gtk.RadioButton? group) {
    radio_button = new BadgeRadioButton(group, "user-home-symbolic", _("Home"));
  }
}
