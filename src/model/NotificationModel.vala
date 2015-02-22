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

/*

  Events:

   - EVENT_FAVORITE: Whenever someone favorites one of the user's tweets
   - Tweets from the user themselves are retweets from people they follow.
     No events from people they don't follow exist
   - EVENT_FOLLOW: A user followed you

   */


// TODO: Write unit tests
class NotificationModel : GLib.Object, GLib.ListModel {
  private static const int N_MAX = 8;

  private NotificationItem[] items = new NotificationItem[N_MAX];
  private uint n_items = 0;


  public GLib.Type get_item_type () {
    return typeof (NotificationItem);
  }

  public uint get_n_items () {
    return n_items;
  }

  public GLib.Object? get_item (uint index) {
    return items[index];
  }

  private void push_to_front (int index) {
    NotificationItem item = items[index];
    for (int i = index - 1; i >= 0; i --) {
      if (i + 1 < N_MAX) {
        items[i + 1] = items[i];
      }
    }
    items[0] = item;
  }

  private void prepend (NotificationItem item) {
    if (n_items == N_MAX)
      this.items_changed (N_MAX - 1, 1, 0);

    items[N_MAX - 1] = item;
    n_items ++;

    if (n_items > N_MAX)
      n_items = N_MAX;

    push_to_front (N_MAX - 1);
    this.items_changed (0, 0, n_items);
    if (n_items > 1) {
      this.items_changed (1, n_items - 1, 0);
    }
  }


  private void add_multiuser_item (MultipleUserNotificationItem item,
                                   string                       screen_name,
                                   string                       body) {
    for (int i = 0; i < n_items; i ++) {
      if (items[i].type == item.type &&
          items[i].id   == item.id) {
        var rt_n = (MultipleUserNotificationItem) (items[i]);
        rt_n.screen_names.add (screen_name);
        rt_n.body = body;
        rt_n.build_heading ();

        if (i != 0) {
          // Move this item to the front
          this.push_to_front (i);
          this.items_changed (0, n_items, n_items);
        }
        return;
      }
    }

    this.prepend (item);
  }

  public void add_rt_item (int64  tweet_id,
                           string tweet_text,
                           string screen_name) {
    var item = new RTNotificationItem ();
    item.id = tweet_id;
    item.body = tweet_text;
    item.type = NotificationItem.TYPE_RETWEET;
    item.screen_names.add (screen_name);
    item.build_heading ();
    add_multiuser_item (item,
                        screen_name,
                        tweet_text);
  }

  public void add_fav_item (int64  tweet_id,
                            string tweet_text,
                            string screen_name) {
    var item = new RTNotificationItem ();
    item.id = tweet_id;
    item.body = tweet_text;
    item.type = NotificationItem.TYPE_FAVORITE;
    item.screen_names.add (screen_name);
    item.build_heading ();
    add_multiuser_item (item,
                        screen_name,
                        tweet_text);

  }


  public void add_follow_item (int64 user_id,
                               string screen_name) {
    var item = new RTNotificationItem ();
    item.id = user_id;
    item.type = NotificationItem.TYPE_FOLLOW;
    item.screen_names.add (screen_name);
    item.build_heading ();
    add_multiuser_item (item,
                        screen_name,
                        "");
  }

}
