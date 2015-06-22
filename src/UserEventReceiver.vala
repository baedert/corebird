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

class UserEventReceiver : GLib.Object, IMessageReceiver {
  private unowned Account account;

  public UserEventReceiver (Account account) {
    this.account = account;
  }

  public void stream_message_received (StreamMessageType type,
                                       Json.Node         root_node) {
    switch (type) {
      case StreamMessageType.EVENT_FOLLOW:
        int64 user_id = root_node.get_object ().get_object_member ("target")
                                 .get_int_member ("id");
        account.follow_id (user_id);
        break;

      case StreamMessageType.EVENT_UNFOLLOW:
        int64 user_id = root_node.get_object ().get_object_member ("target")
                                 .get_int_member ("id");
        account.unfollow_id (user_id);
        break;

      case StreamMessageType.EVENT_MUTE:
        int64 user_id = root_node.get_object ().get_object_member ("target")
                                 .get_int_member ("id");
        account.mute_id (user_id);
        break;

      case StreamMessageType.EVENT_UNMUTE:
        int64 user_id = root_node.get_object ().get_object_member ("target")
                                 .get_int_member ("id");
        account.unmute_id (user_id);
        break;

      case StreamMessageType.EVENT_BLOCK:
        int64 user_id = root_node.get_object ().get_object_member ("target")
                                 .get_int_member ("id");
        account.block_id (user_id);
        break;

      case StreamMessageType.EVENT_UNBLOCK:
        int64 user_id = root_node.get_object ().get_object_member ("target")
                                 .get_int_member ("id");
        account.unblock_id (user_id);
        break;

      case StreamMessageType.EVENT_USER_UPDATE:
        var user_obj = root_node.get_object ().get_object_member ("target");
        if (user_obj.get_int_member ("id") == account.id) {
          string old_screen_name = account.screen_name;
          account.name = user_obj.get_string_member ("name");
          account.description = user_obj.get_string_member ("description");
          account.screen_name = user_obj.get_string_member ("screen_name");
          account.info_changed (account.screen_name,
                                account.name,
                                account.avatar_small,
                                account.avatar);
          account.save_info ();
          Utils.update_startup_account (old_screen_name, account.screen_name);
        } else
          warning ("USER_UPDATE: ids don't match");
        break;

      case StreamMessageType.EVENT_FOLLOWED:
        var target = root_node.get_object ().get_object_member ("target");
        var source = root_node.get_object ().get_object_member ("source");
        int64 id = source.get_int_member ("id");
        var identity = new UserIdentity ();
        identity.screen_name = source.get_string_member ("screen_name");
        identity.user_id = source.get_int_member ("id");
        identity.name = source.get_string_member ("name");
        account.notification_received (id,
                                       NotificationItem.TYPE_FOLLOWED,
                                       "",
                                       identity);
        break;

      case StreamMessageType.TWEET:
        Json.Object user_obj = root_node.get_object ().get_object_member ("user");
        bool is_rt = root_node.get_object ().has_member ("retweeted_status");
        int64 user_id = user_obj.get_int_member ("id");
        if (user_id != account.id && is_rt) {
          var rt = root_node.get_object ().get_object_member ("retweeted_status");
          var rt_user = rt.get_object_member ("user");
          int64 retweeted_user = rt_user.get_int_member ("id");
          if (retweeted_user == account.id) {
            int64 rt_id = rt.get_int_member ("id");
            var user = root_node.get_object ().get_object_member ("user");
            var identity = new UserIdentity ();
            identity.user_id = user.get_int_member ("id");
            identity.screen_name = user.get_string_member ("screen_name");
            identity.name = user.get_string_member ("name");
            string text = rt.get_string_member ("text"); // XXX Urls not replaced...
            account.notification_received (rt_id,
                                           NotificationItem.TYPE_RETWEET,
                                           text,
                                           identity);
          }
        }
        break;

      case StreamMessageType.EVENT_FAVORITE:
        error ("Implement!");
        break;
    }
  }

}
