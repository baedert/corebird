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

class FavoritesTimeline : Cb.MessageReceiver, DefaultTimeline {
  protected override string function {
    get {
      return "1.1/favorites/list.json";
    }
  }

  public FavoritesTimeline (int id, Account account) {
    base (id);
    this.account = account;
    //this.tweet_list.account = account;
  }

  private void stream_message_received (Cb.StreamMessageType type, Json.Node root) {
    if (type == Cb.StreamMessageType.EVENT_FAVORITE) {
      Json.Node tweet_obj = root.get_object ().get_member ("target_object");
      int64 tweet_id = tweet_obj.get_object ().get_int_member ("id");

      // the source object is a user object indicating who made the favorite
      Json.Object source_obj = root.get_object ().get_object_member ("source");
      if (source_obj.get_int_member ("id") != account.id)
        return;

      Cb.Tweet? existing_tweet = this.tweet_list.model.get_for_id (tweet_id, 0);
      if (existing_tweet != null) {
        /* This tweet is already in the model, so just mark it as favorited */
        tweet_list.model.set_tweet_flag (existing_tweet, Cb.TweetState.FAVORITED);
        return;
      }

      var tweet = new Cb.Tweet ();
      tweet.load_from_json (tweet_obj, account.id, new GLib.DateTime.now_local ());
      tweet.set_flag (Cb.TweetState.FAVORITED);
      this.tweet_list.model.add (tweet);
    } else if (type == Cb.StreamMessageType.EVENT_UNFAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      toggle_favorite (id, false);
    }
  }


  public override void on_leave () {
    for (uint i = 0; i < tweet_list.model.get_n_items (); i ++) {
      var tweet = (Cb.Tweet) tweet_list.model.get_item (i);
      if (!tweet.is_flag_set (Cb.TweetState.FAVORITED)) {
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
    radio_button = new Cb.BadgeRadioButton(group, "corebird-favorite-symbolic", _("Favorites"));
  }
}
