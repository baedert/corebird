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

class MentionsTimeline : IMessageReceiver, DefaultTimeline {

  public MentionsTimeline(int id){
    base (id);
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


/* TODO: All the following functions should probably go into DefaultTimeline
         so we can avoid the code duplication in MentionsTimeline and HomeTimeline */

  private void add_tweet (Json.Node root_node) { // {{{
    var root = root_node.get_object ();
    var author = root.get_object_member ("user");
    if (author.get_int_member ("id") == account.id &&
        !root.get_null_member ("in_reply_to_status_id")) {
      mark_seen (root.get_int_member ("in_reply_to_status_id"));
      return;
    }



    if (root.get_string_member("text").contains("@"+account.screen_name)) {
      GLib.DateTime now = new GLib.DateTime.now_local ();
      Tweet t = new Tweet();
      t.load_from_json(root_node, now, account);
      if (t.user_id == account.id)
        return;

      if (t.is_retweet && !should_display_retweet (t))
        return;

      if (account.filter_matches (t))
        return;

      bool auto_scroll = Settings.auto_scroll_on_new_tweets ();

      this.balance_next_upper_change (TOP);
      var entry = new TweetListEntry(t, main_window, account);
      entry.seen = false;

      delta_updater.add (entry);
      tweet_list.add (entry);

      base.scroll_up (t);

      unread_count++;
      update_unread_count();
      this.max_id = t.id;

      // This is for example the case if the timeline has not been initialized yet, but a tweet arrived.
      if (t.id < lowest_id)
        lowest_id = t.id;

      if (Settings.notify_new_mentions ()) {
        NotificationManager.notify_pixbuf (_("New Mention from %s").printf ("@" + t.screen_name),
                                           t.text,
                                           t.avatar);
      }
    }
  } // }}}


  public override void load_newest () {
    this.loading = true;
    this.load_newest_internal.begin("1.1/statuses/mentions_timeline.json", () => {
      this.loading = false;
    });
  }

  public override void load_older () {
    if (!initialized)
      return;

    this.balance_next_upper_change (BOTTOM);
    main_window.start_progress ();
    this.loading = true;
    this.load_older_internal.begin ("1.1/statuses/mentions_timeline.json", () => {
      this.loading = false;
      main_window.stop_progress ();
    });
  }



  public override void create_tool_button (RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "corebird-mentions-symbolic");
    tool_button.tooltip_text = _("Mentions");
    tool_button.label = _("Mentions");
  }

}
