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
  public int unread_count                   { get; set; }
  public unowned MainWindow main_window     { get; set; }
  public unowned Account account            { get; set; }
  public unowned DeltaUpdater delta_updater { get; set; }
  private int id;
  private BadgeRadioToolButton tool_button;
  private HashMap<int64?, unowned DMThreadEntry> thread_map = new HashMap<int64?, unowned DMThreadEntry>
                              (Utils.int64_hash_func, Utils.int64_equal_func, DMThreadEntry.equal_func);
  private StartConversationEntry start_conversation_entry;
  private int64 max_received_id = -1;
  private int64 max_sent_id = -1;
  [GtkChild]
  private Gtk.ListBox thread_list;


  public DMThreadsPage (int id, Account account) {
    this.id = id;
    this.account = account;
    thread_list.set_header_func (header_func);

    thread_list.row_activated.connect ((row) => {
      if (row is StartConversationEntry)
        ((StartConversationEntry)row).reveal ();
      else {
        var entry = (DMThreadEntry) row;
        this.unread_count -= entry.unread_count;
        entry.unread_count = 0;
        entry.update_unread_count ();
        main_window.switch_page (MainWindow.PAGE_DM,
                                 entry.user_id);
      }
    });
    start_conversation_entry = new StartConversationEntry (account);
    start_conversation_entry.start.connect((user_id) => {

    });
//    start_conversation_entry.activated.connect (() => {
//      main_window.switch_page (MainWindow.PAGE_DM,
//                               5);
//    });
    thread_list.add (start_conversation_entry);
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) {
    if (type == StreamMessageType.DIRECT_MESSAGE) {
      var obj = root.get_object ().get_object_member ("direct_message");
      add_new_thread (obj);
      if (obj.get_int_member ("sender_id") != account.id) {
        update_unread_count ();
        unread_count ++;
      }
    }
  }


  public void on_join (int page_id, va_list arg_list) {
    if (!initialized) {
      load_cached ();
      load_newest ();
      initialized = true;
    }
  }

  public void on_leave () {
    start_conversation_entry.unreveal ();
  }

  public void load_cached () { // {{{
    //Load max message id

    max_received_id = account.db.select ("dms").cols ("id")
                      .where_eqi ("to_id", account.id).order ("id DESC").limit (1).once_i64 ();
    max_sent_id = account.db.select ("dms").cols ("id")
                  .where_eqi ("from_id", account.id).order ("id DESC").limit (1).once_i64 ();
    account.db.select ("dm_threads")
              .cols ("user_id", "screen_name", "last_message", "last_message_id", "avatar_url", "name")
              .order ("last_message_id")
              .run ((vals) => {
      int64 user_id = int64.parse (vals[0]);
      var entry = new DMThreadEntry (user_id);
      entry.screen_name =  vals[1];
      entry.name = vals[5];
      entry.last_message = vals[2];
      entry.last_message_id = int64.parse(vals[3]);
      Gdk.Pixbuf avatar = TweetUtils.load_avatar (vals[4]);
      if (avatar == null) {
        TweetUtils.download_avatar.begin (vals[4], (obj, res) => {
          avatar = TweetUtils.download_avatar.end (res);
          TweetUtils.load_avatar (vals[4], avatar);
          entry.avatar = avatar;
        });
      } else
        entry.avatar = avatar;

      thread_list.add (entry);
      thread_map.set (user_id, entry);
      return true;
    });
  } // }}}

  public void load_newest () { // {{{
    var call = account.proxy.new_call ();
    call.set_function ("1.1/direct_messages.json");
    call.set_method ("GET");
    call.add_param ("skip_status", "true");
    call.add_param ("since_id", max_received_id.to_string ());
    call.invoke_async.begin (null, () => {
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }
      var root_arr = parser.get_root ().get_array ();
      root_arr.foreach_element ((arr, pos, node) => {
        add_new_thread (node.get_object ());
      });
    });

    var rec_call = account.proxy.new_call ();
    rec_call.set_function ("1.1/direct_messages/sent.json");
    rec_call.add_param ("skip_status", "true");
    rec_call.add_param ("since_id", max_sent_id.to_string ());
    rec_call.set_method ("GET");
    rec_call.invoke_async.begin (null, () => {
      var parser = new Json.Parser ();
      try {
      stdout.printf (rec_call.get_payload ());
        parser.load_from_data (rec_call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }
      var root_arr = parser.get_root ().get_array ();
      root_arr.foreach_element ((arr, pos, node) => {
        // This won't really add a new thread, but it'll call save_message
        add_new_thread (node.get_object ());
      });
    });
  } // }}}

  private void add_new_thread (Json.Object dm_obj) { // {{{
    int64 sender_id  = dm_obj.get_int_member ("sender_id");
    int64 message_id = dm_obj.get_int_member ("id");
    save_message (dm_obj);
    if (sender_id == account.id)
      return;
    if (thread_map.has_key(sender_id)) {
      var t_e = thread_map.get (sender_id);
      t_e.unread_count ++;
      t_e.update_unread_count ();
      t_e.last_message = dm_obj.get_string_member ("text");
      return;
    }

    var thread_entry = new DMThreadEntry (sender_id);
    var author = dm_obj.get_string_member ("sender_screen_name");
    string sender_name = dm_obj.get_object_member ("sender").get_string_member ("name");
    thread_entry.name = sender_name;
    thread_entry.screen_name = author;
    thread_entry.last_message = dm_obj.get_string_member("text");
    thread_entry.last_message_id = message_id;
    thread_list.add(thread_entry);
    thread_map.set(sender_id, thread_entry);
    string avatar_url = dm_obj.get_object_member ("sender").get_string_member ("profile_image_url");
    account.db.insert( "dm_threads")
              .vali64 ("user_id", sender_id)
              .val ("name", sender_name)
              .val ("screen_name", author)
              .val ("last_message", thread_entry.last_message)
              .vali64 ("last_message_id", message_id)
              .val ("avatar_url", avatar_url)
              .run ();


    Gdk.Pixbuf avatar = TweetUtils.load_avatar (avatar_url);
    if (avatar == null) {
      TweetUtils.download_avatar.begin (avatar_url, (obj, res) => {
        avatar = TweetUtils.download_avatar.end (res);
        TweetUtils.load_avatar (avatar_url, avatar);
        thread_entry.avatar = avatar;
      });
    } else
      thread_entry.avatar = avatar;
  } // }}}

  private void save_message (Json.Object dm_obj) { // {{{
    Json.Object sender = dm_obj.get_object_member ("sender");
    Json.Object recipient = dm_obj.get_object_member ("recipient");
    account.db.insert ("dms").vali64 ("id", dm_obj.get_int_member ("id"))
              .vali64 ("from_id", dm_obj.get_int_member ("sender_id"))
              .vali64 ("to_id", dm_obj.get_int_member ("recipient_id"))
              .val ("from_screen_name", dm_obj.get_string_member ("sender_screen_name"))
              .val ("to_screen_name", dm_obj.get_string_member ("recipient_screen_name"))
              .val ("from_name", sender.get_string_member ("name"))
              .val ("to_name", recipient.get_string_member ("name"))
              .val ("avatar_url", sender.get_string_member ("profile_image_url"))
              .vali64 ("timestamp", Utils.parse_date (dm_obj.get_string_member ("created_at")).to_unix ())
              .val ("text", dm_obj.get_string_member ("text"))
              .run ();
  } // }}}

  private void header_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? row_before) { //{{{
    if (row_before == null)
      return;

    Widget header = row.get_header ();
    if (header == null) {
      header = new Gtk.Separator (Orientation.HORIZONTAL);
      header.show ();
      row.set_header (header);
    }
  } //}}}

  public void create_tool_button(RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "corebird-dms-symbolic");
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
