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


struct Friendship {
  bool followed_by;
  bool following;
  bool want_retweets;
  bool blocking;
}


namespace UserUtils {
  async Friendship? load_friendship (Account account,
                                     int64   user_id)
  {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/friendships/show.json");
    call.set_method ("GET");
    call.add_param ("source_id", account.id.to_string ());
    call.add_param ("target_id", user_id.to_string ());

    Json.Node? root = yield TweetUtils.load_threaded (call);
    if (root == null)
      return null;

    var relationship = root.get_object ().get_object_member ("relationship");
    var target = relationship.get_object_member ("target");
    var source = relationship.get_object_member ("source");

    var friendship = Friendship ();
    friendship.followed_by   = target.get_boolean_member ("following");
    friendship.following     = target.get_boolean_member ("followed_by");
    friendship.want_retweets = source.get_boolean_member ("want_retweets");
    friendship.blocking      = source.get_boolean_member ("blocking");

    // XXX This gets copied and I just want to rewrite this in C.
    return friendship;
  }
}
