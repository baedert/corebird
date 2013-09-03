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
using Gee;

[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-threads-page.ui")]
class DMThreadsPage : IPage, IMessageReceiver, ScrollWidget {
  private bool initialized = false;
  public int unread_count               {get; set;}
  public unowned MainWindow main_window {set; get;}
  protected Gtk.ListBox tweet_list      {set; get;}
  public unowned Account account        {get; set;}
  private int id;
  private BadgeRadioToolButton tool_button;
  private HashMap<int64?, unowned DMThreadEntry> thread_map = new HashMap<int64?, unowned DMThreadEntry>
                              (Utils.int64_hash_func, Utils.int64_equal_func, DMThreadEntry.equal_func);
  [GtkChild]
  private Gtk.ListBox thread_list;


  public DMThreadsPage (int id) {
    this.id = id;
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) {
    if (type == StreamMessageType.DIRECT_MESSAGE) {
      unread_count ++;
      var obj = root.get_object ().get_object_member ("direct_message");
      add_new_thread (obj);
      update_unread_count ();
    }
  }


  public void on_join (int page_id, va_list arg_list) {
    if (!initialized) {
      load_cached ();
      load_newest ();
      initialized = true;
    }
  }

  public void load_cached () {
    account.db.exec ("SELECT user_id, screen_name, last_message, last_message_id
                      FROM dm_threads ORDER BY last_message_id",
                     (n_cols, vals) => {
      int64 user_id = int64.parse (vals[0]);
      var entry = new DMThreadEntry (user_id);
      entry.screen_name =  vals[1];
      entry.last_message = vals[2];
      entry.last_message_id = int64.parse(vals[3]);
      thread_list.add (entry);
      thread_map.set (user_id, entry);
      return 0; //go on
    });
  }

  public void load_newest () {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/direct_messages.json");
    call.set_method ("GET");
    call.add_param ("skip_status", "true");
    call.invoke_async.begin (null, () => {
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
      }
      var root_arr = parser.get_root ().get_array ();
      root_arr.foreach_element ((arr, pos, node) => {
        add_new_thread (node.get_object ());
      });
    });

  }

  private void add_new_thread (Json.Object dm_obj) {
    int64 sender_id  = dm_obj.get_int_member ("sender_id");
    int64 message_id = dm_obj.get_int_member ("id");
    if (thread_map.has_key(sender_id)) {
      // TODO: Update last_message_label
      return;
    }

    var thread_entry = new DMThreadEntry (sender_id);
    var author = dm_obj.get_string_member ("sender_screen_name");
    thread_entry.screen_name = author;
    thread_entry.last_message = dm_obj.get_string_member("text");
    thread_entry.last_message_id = message_id;
    thread_list.add(thread_entry);
    thread_map.set(sender_id, thread_entry);
    string avatar_url = dm_obj.get_object_member ("sender").get_string_member ("profile_image_url");
    Gdk.Pixbuf avatar = TweetUtils.load_avatar (avatar_url);
    account.db.exec (@"INSERT INTO `dm_threads`
                      (user_id, screen_name, last_message, last_message_id) VALUES
                      ('$sender_id', '$author', '$(thread_entry.last_message)', '$message_id');");
    if (avatar == null) {
      TweetUtils.download_avatar.begin (avatar_url, (obj, res) => {
        avatar = TweetUtils.download_avatar.end (res);
        TweetUtils.load_avatar (avatar_url, avatar);
        thread_entry.avatar = avatar;
      });
    } else
      thread_entry.avatar = avatar;
  }



  public void create_tool_button(RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "dms");
    tool_button.label = "Direct Messages";
  }

  public RadioToolButton? get_tool_button() {
    return tool_button;
  }

  public int get_id() {
    return id;
  }

  private void update_unread_count() {
    tool_button.show_badge = (unread_count > 0);
    tool_button.queue_draw();
  }

}
