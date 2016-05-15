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

  private void stream_message_received (StreamMessageType type, Json.Node root) {
    if (type == StreamMessageType.EVENT_FAVORITE) {
      Json.Node tweet_obj = root.get_object ().get_member ("target_object");
      int64 tweet_id = tweet_obj.get_object ().get_int_member ("id");

      Tweet? existing_tweet = this.tweet_list.model.get_from_id (tweet_id, 0);
      if (existing_tweet != null) {
        /* This tweet is already in the model, so just mark it as favorited */
        existing_tweet.set_flag (TweetState.FAVORITED);
        return;
      }

      Tweet tweet = new Tweet ();
      tweet.load_from_json (tweet_obj, new GLib.DateTime.now_local (), this.account);
      tweet.set_flag (TweetState.FAVORITED);
      this.tweet_list.model.add (tweet);
    } else if (type == StreamMessageType.EVENT_UNFAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      toggle_favorite (id, false);
    }
  }


  public override void on_leave () {
    for (uint i = 0; i < tweet_list.model.get_n_items (); i ++) {
      var tweet = (Tweet) tweet_list.model.get_item (i);
      if (!tweet.is_flag_set (TweetState.FAVORITED)) {
        tweet_list.model.remove_tweet (tweet);
        i --;
      }
    }

    base.on_leave ();
  }

  public override string get_title () {
    return _("Favorites");
  }

  public override void create_radio_button (Gtk.RadioButton? group) {
    radio_button = new BadgeRadioButton(group, "emblem-favorite-symbolic", _("Favorites"));
  }
}
