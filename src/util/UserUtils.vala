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

const uint FRIENDSHIP_FOLLOWED_BY   = 1 << 0;
const uint FRIENDSHIP_FOLLOWING     = 1 << 1;
const uint FRIENDSHIP_WANT_RETWEETS = 1 << 2;
const uint FRIENDSHIP_BLOCKING      = 1 << 3;
const uint FRIENDSHIP_CAN_DM        = 1 << 4;

struct Cursor {
  int64 next_cursor;
  bool full;
  Json.Node? json_object;
}


namespace UserUtils {
  // TODO: Remove screen_name parameter, won't work.
  async uint load_friendship (Account account,
                              int64   user_id,
                              string  screen_name)
  {
    var call = account.proxy.new_call ();
    call.add_header ("Authorization", "Bearer " + account.proxy.get_access_token ());
    call.set_function ("api/v1/accounts/relationships");
    call.set_method ("GET");
    call.add_param ("id[]", user_id.to_string ());

    Json.Node? root = null;
    try {
      root = yield Cb.Utils.load_threaded_async (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return 0;
    }

    var relationships = root.get_array ();
    if (relationships.get_length () == 0)
      return 0;

    var relationship = relationships.get_element (0).get_object ();

    uint friendship = 0;

    if (relationship.get_boolean_member ("following"))
      friendship |= FRIENDSHIP_FOLLOWING;

    if (relationship.get_boolean_member ("followed_by"))
      friendship |= FRIENDSHIP_FOLLOWED_BY;

    if (relationship.get_boolean_member ("showing_reblogs"))
      friendship |= FRIENDSHIP_WANT_RETWEETS;

    if (relationship.get_boolean_member ("blocking"))
      friendship |= FRIENDSHIP_BLOCKING;

    // TODO: CAN_DM not checked here. Remove.

    return friendship;
  }

  async Cursor? load_followers (Account account,
                                int64   user_id,
                                Cursor? old_cursor)
  {
    const int requested = 25;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/followers/list.json");
    call.set_method ("GET");
    call.add_param ("user_id", user_id.to_string ());
    call.add_param ("count", requested.to_string ());
    call.add_param ("skip_status", "true");
    call.add_param ("include_user_entities", "false");

    if (old_cursor != null)
      call.add_param ("cursor", old_cursor.next_cursor.to_string ());

    Json.Node? root = null;
    try {
      root = yield Cb.Utils.load_threaded_async (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return null;
    }

    var root_obj = root.get_object ();

    var user_array = root_obj.get_array_member ("users");

    Cursor cursor = Cursor ();
    cursor.next_cursor = root_obj.get_int_member ("next_cursor");
    cursor.full = (user_array.get_length () < requested);
    cursor.json_object = root_obj.get_member ("users");

    return cursor;
  }

  async Cursor? load_following (Account account,
                                int64   user_id,
                                Cursor? old_cursor)
  {
    const int requested = 25;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/friends/list.json");
    call.set_method ("GET");
    call.add_param ("user_id", user_id.to_string ());
    call.add_param ("count", requested.to_string ());
    call.add_param ("skip_status", "true");
    call.add_param ("include_user_entities", "false");

    if (old_cursor != null)
      call.add_param ("cursor", old_cursor.next_cursor.to_string ());

    Json.Node? root = null;
    try {
      root = yield Cb.Utils.load_threaded_async (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return null;
    }

    var root_obj = root.get_object ();

    var user_array = root_obj.get_array_member ("users");

    Cursor cursor = Cursor ();
    cursor.next_cursor = root_obj.get_int_member ("next_cursor");
    cursor.full = (user_array.get_length () < requested);
    cursor.json_object = root_obj.get_member ("users");

    return cursor;
  }

  async void mute_user (Account account,
                        int64   to_block,
                        bool    setting) {
    var call = account.proxy.new_call ();
    call.set_method ("POST");
    if (setting)
      call.set_function ("1.1/mutes/users/create.json");
    else
      call.set_function ("1.1/mutes/users/destroy.json");

    call.add_param ("user_id", to_block.to_string ());

    try {
      yield call.invoke_async (null);
    } catch (GLib.Error e) {
      critical (e.message);
    }
  }
}
