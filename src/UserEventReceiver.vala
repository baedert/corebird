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
    if (type == StreamMessageType.EVENT_FOLLOW) {
      int64 user_id = root_node.get_object ().get_object_member ("target")
                               .get_int_member ("id");
      account.follow_id (user_id);
    } else if (type == StreamMessageType.EVENT_UNFOLLOW) {
      int64 user_id = root_node.get_object ().get_object_member ("target")
                               .get_int_member ("id");
      account.unfollow_id (user_id);
    }
  }

}
