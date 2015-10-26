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

class FavoritesTimeline : IMessageReceiver, DefaultTimeline {
  protected override string function {
    get {
      return "1.1/favorites/list.json";
    }
  }

  public FavoritesTimeline (int id, Account account) {
    base (id);
    this.account = account;
    this.tweet_list.account = account;
  }

  private void stream_message_received (StreamMessageType type, Json.Node root) { // {{{
    if (type == StreamMessageType.EVENT_FAVORITE) {
      Json.Node tweet_obj = root.get_object ().get_member ("target_object");
      int64 tweet_id = tweet_obj.get_object ().get_int_member ("id");
      foreach (Gtk.Widget w in tweet_list.get_children ()) {
        if (!(w is TweetListEntry))
          continue;

        var tle = (TweetListEntry) w;
        if (tle.tweet.id == tweet_id) {
          tle.tweet.favorited = true;
          return;
        }
      }
      Tweet tweet = new Tweet ();
      tweet.load_from_json (tweet_obj,
                            new GLib.DateTime.now_local (),
                            this.account);
      tweet.favorited = true;
      var tle = new TweetListEntry (tweet, this.main_window, this.account);
      this.delta_updater.add (tle);
      this.tweet_list.add (tle);
    } else if (type == StreamMessageType.EVENT_UNFAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      toggle_favorite (id, false);
    }
  } // }}}


  public override void on_leave () {
    GLib.List<unowned Gtk.Widget> children = tweet_list.get_children ();
    foreach (Gtk.Widget w in children) {
      if (!(w is TweetListEntry))
        continue;

      if (!((TweetListEntry)w).tweet.favorited) {
        GLib.Idle.add(() => {tweet_list.remove (w); return false;});
      }
    }

    base.on_leave ();
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



  public override string? get_title () {
    return _("Favorites");
  }

  public override void create_radio_button (Gtk.RadioButton? group) {
    radio_button = new BadgeRadioButton(group, "starred-symbolic", _("Favorites"));
  }
}
