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
  So, here's how we handle direct messages and their threads/conversations:

  When the user opens the page for the very first time, we try to get as many
  messages from twitter as possible in one api call(i.e. 300 + leonidas currently).
  This gives us up to 300 RECEIVED messages. Whenever we encounter a sender_id we have
  not yet seen, we create a new DMThreadEntry and append it to the thread_list.
  When the sender_id WAS already seen, we just take the dm's ID and set it as the
  last/first (depending on its value) message id of that conversation.
  Note that this potentially means that we are NOT see ALL conversations, but whatever.

  Now, if the user opens a thread, we probably have a few received messages from the
  thread building, but we still need to get the ones he sent(if not cached). YAY.
  So, we need to cache both of them and then make sure that they are properly sorted, etc.
  Now when the user scrolls up, we need to either just load more cached messages from the
  database OR make 2(TWO!) API calls to twitter(for sent and received messages), then
  display them, cache them, etc.
  Of course we also always need to update the first/last message id of the conversation
  each and every single time we get a new message, update or query anything.
  We can however use these ids to somewhat optimize the calls we make to twitter by
  setting them as since_id and max_id parameter.

  Now it gets interesting: Since both parties in a conversation can delete messages
  of both parties and we cannot be sure that the user didn't delete some message on
  another client, we cannot really cache anything and just need to rely on twitter
  sending us the same shit every single time.
  This is basically the same dilemma with tweets, but worse because of conversations
  and the weird api.





*/

using Gtk;
using Gee;

[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-threads-page.ui")]
class DMThreadsPage : IPage, IMessageReceiver, ScrollWidget {
  private bool initialized = false;
  public int unread_count               { get; set; }
  public unowned MainWindow main_window { get; set; }
  public unowned Account account        { get; set; }
  private int id;
  private BadgeRadioToolButton tool_button;
  private HashMap<int64?, unowned DMThreadEntry> thread_map = new HashMap<int64?, unowned DMThreadEntry>
                              (Utils.int64_hash_func, Utils.int64_equal_func, DMThreadEntry.equal_func);
  private StartConversationEntry start_conversation_entry = new StartConversationEntry ();
  [GtkChild]
  private Gtk.ListBox thread_list;


  public DMThreadsPage (int id) {
    this.id = id;
    thread_list.set_header_func (header_func);

    thread_list.row_activated.connect ((row) => {
      if (!(row is DMThreadEntry))
        return;
      main_window.switch_page (MainWindow.PAGE_DM,
                               ((DMThreadEntry)row).user_id);
    });
    thread_list.add (start_conversation_entry);
    start_conversation_entry.clicked.connect (() => {
      main_window.switch_page (MainWindow.PAGE_DM, 0);
    });
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

  public void on_leave () {}

  public void load_cached () { // {{{
    account.db.select ("dm_threads")
              .cols ("user_id", "screen_name", "last_message", "last_message_id", "avatar_url")
              .order ("last_message_id")
              .run ((vals) => {
      int64 user_id = int64.parse (vals[0]);
      var entry = new DMThreadEntry (user_id);
      entry.screen_name =  vals[1];
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
  } // }}}

  private void add_new_thread (Json.Object dm_obj) { // {{{
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
    account.db.insert( "dm_threads")
              .vali64 ("user_id", sender_id)
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

[GtkTemplate (ui = "/org/baedert/corebird/ui/start-conversation-entry.ui")]
class StartConversationEntry : Gtk.ListBoxRow {
  [GtkChild]
  private Gtk.Button start_conversation_button;
  public signal void clicked ();
  construct {
    start_conversation_button.clicked.connect (() => {
      clicked ();
    });
  }
}
