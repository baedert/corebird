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

class FavoritesTimeline : IMessageReceiver, DefaultTimeline {

  public FavoritesTimeline(int id) {
    base (id);
  }

  private void stream_message_received (StreamMessageType type, Json.Node root) { // {{{
    if (type == StreamMessageType.EVENT_FAVORITE) {
      // TODO: add new tweet to the timeline
      add_tweet (root);
    } else if (type == StreamMessageType.EVENT_UNFAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      toggle_favorite (id, false);
    }
  } // }}}


  private void add_tweet (Json.Node root_node) {

    GLib.DateTime now = new GLib.DateTime.now_local ();
    Tweet t = new Tweet();
    t.load_from_json(root_node, now, account);

    bool auto_scroll = Settings.auto_scroll_on_new_tweets ();

    this.balance_next_upper_change (TOP);
    var entry = new TweetListEntry(t, main_window, account);
    entry.seen = false;

    delta_updater.add (entry);
    tweet_list.add (entry);
    if (this.scrolled_up && (t.user_id == account.id || auto_scroll)) {
      this.scroll_up_next (true, false,
                           main_window.cur_page_id != this.id);
    }

    this.max_id = t.id;

    /* This is for example the case if the timeline=
    has not been initialized yet, but a tweet arrived. */
    if (t.id < lowest_id)
      lowest_id = t.id;

    base.update_tweet_ids ();
  }

  public override void on_leave () {
    GLib.List<unowned Gtk.Widget> children = tweet_list.get_children ();
    foreach (Gtk.Widget w in children) {
      if (!(w is TweetListEntry))
        continue;

      if (!((TweetListEntry)w).tweet.favorited) {
        GLib.Idle.add(() => {tweet_list.remove (w); return false;});
      }
    }
  }


  public override void load_newest () {
    this.loading = true;
    this.load_newest_internal.begin ("1.1/favorites/list.json",  () => {
      this.loading = false;
    });
  }

  public override void load_older () {
    this.balance_next_upper_change (BOTTOM);
    main_window.start_progress ();
    this.loading = true;
    this.load_older_internal.begin ("1.1/favorites/list.json", () => {
      this.loading = false;
      main_window.stop_progress ();
    });
  }

  public override void create_tool_button(RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "corebird-favorite-symbolic");
    tool_button.tooltip_text = _("Favorites");
    tool_button.label = _("Favorites");
  }

  protected override string get_function () {
    return "1.1/favorites/list.json";
  }
}
