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

class MentionsTimeline : IMessageReceiver, DefaultTimeline {
  protected override string function {
    get {
      return "1.1/statuses/mentions_timeline.json";
    }
  }

  public MentionsTimeline(int id, Account account) {
    base (id);
    this.account = account;
    this.tweet_list.account= account;
  }

  private void stream_message_received (StreamMessageType type, Json.Node root){
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
  }


  private void add_tweet (Json.Node root_node) {
    /* Mark tweets as seen the user has already replied to */
    var root = root_node.get_object ();
    var author = root.get_object_member ("user");
    if (author.get_int_member ("id") == account.id &&
        !root.get_null_member ("in_reply_to_status_id")) {
      mark_seen (root.get_int_member ("in_reply_to_status_id"));
      return;
    }



    if (root.get_string_member ("text").contains ("@" + account.screen_name)) {
      GLib.DateTime now = new GLib.DateTime.now_local ();
      Tweet t = new Tweet ();
      t.load_from_json (root_node, now, account);
      if (t.user_id == account.id)
        return;

      if (t.retweeted_tweet != null && get_rt_flags (t) > 0)
        return;

      if (account.filter_matches (t))
        return;

      if (account.blocked_or_muted (t.user_id))
        return;

      this.balance_next_upper_change (TOP);
      t.seen = false;
      tweet_list.model.add (t);


      base.scroll_up (t);
      this.unread_count ++;

      if (Settings.notify_new_mentions ()) {
        string text;
        if (t.retweeted_tweet != null)
          text = t.retweeted_tweet.text;
        else
          text = t.source_tweet.text;
        t.notification_id = send_notification (t.screen_name,
                                               t.id,
                                               Utils.unescape_html (text));
      }
    }
  }


  /**
   * @return The notification's ID
   */
  private string send_notification (string sender_screen_name, int64 tweet_id, string text) {
    var n = new GLib.Notification (_("New Mention from @%s")
                                   .printf (sender_screen_name));
    n.set_body (text);
    n.set_default_action_and_target_value ("app.show-window", account.id);
    string id = "new-dm-" + tweet_id.to_string ();
    GLib.Application.get_default ().send_notification (id, n);
    return id;
  }

  public override void load_newest () {
    this.loading = true;
    this.load_newest_internal.begin (() => {
      this.loading = false;
    });
  }

  public override void load_older () {
    if (!initialized)
      return;

    this.balance_next_upper_change (BOTTOM);
    this.loading = true;
    this.load_older_internal.begin (() => {
      this.loading = false;
    });
  }

  public override string? get_title () {
    return _("Mentions");
  }

  public override void create_radio_button (Gtk.RadioButton? group) {
    radio_button = new BadgeRadioButton(group, "corebird-mentions-symbolic", _("Mentions"));
  }
}
