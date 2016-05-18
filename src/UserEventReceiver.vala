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
        } else {
          warning ("USER_UPDATE: ids don't match");
        }
        break;

      case StreamMessageType.DIRECT_MESSAGE:
        var cb = (Corebird) GLib.Application.get_default ();
        if (!cb.is_window_open_for_user_id (account.id) &&
            Settings.notify_new_dms ()) {
          var dm_obj = root_node.get_object ().get_object_member ("direct_message");
          var sender_obj = dm_obj.get_object_member ("sender");
          int64 sender_id = sender_obj.get_int_member ("id");
          string sender_name = sender_obj.get_string_member ("name");
          string dm_text = dm_obj.get_string_member ("text");

          account.notifications.send_dm (sender_id,
                                         null,
                                         _("New direct message from %s").printf (sender_name),
                                         Utils.unescape_html (dm_text));
        }
        break;

      case StreamMessageType.TWEET:
        var cb = (Corebird) GLib.Application.get_default ();
        if (!cb.is_window_open_for_user_id (account.id) &&
            Settings.notify_new_mentions ()) {
          var tweet_obj = root_node.get_object ();
          string text = tweet_obj.get_string_member ("text");
          if (text.contains ("@" + account.screen_name)) {
            var author_obj = tweet_obj.get_object_member ("user");
            // TODO: Care about retweets/quotes!
            // XXX : And media?

            string author_name = author_obj.get_string_member ("name");
            string summary = _("%s mentioned %s").printf (author_name,
                                                          account.name);

            account.notifications.send (summary, text);
          }
        }
        break;
    }
  }

}
