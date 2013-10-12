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

[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-page.ui")]
class DMPage : IPage, IMessageReceiver, Box {
  public int unread_count                   { get { return 0; } }
  public unowned MainWindow main_window     { get; set; }
  public unowned Account account            { get; set; }
  public unowned DeltaUpdater delta_updater { get; set; }
  private int id;
  [GtkChild]
  private Button send_button;
  [GtkChild]
  private Entry text_entry;
  [GtkChild]
  private ListBox messages_list;
  [GtkChild]
  private ScrollWidget scroll_widget;

  private int64 user_id;


  public DMPage (int id) {
    this.id = id;
    text_entry.buffer.inserted_text.connect (recalc_length);
    text_entry.buffer.deleted_text.connect (recalc_length);
    messages_list.set_sort_func (ITwitterItem.sort_func_inv);
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) { // {{{
    if (type == StreamMessageType.DIRECT_MESSAGE) {
      // Arriving new dms get already cached in the DMThreadsPage
      var obj = root.get_object ().get_object_member ("direct_message");
      if (obj.get_int_member ("sender_id") != this.user_id)
        return;

      var sender = obj.get_object_member ("sender");
      var new_msg = new DMListEntry ();
      new_msg.text = obj.get_string_member ("text");
      new_msg.name = sender.get_string_member ("name");
      new_msg.screen_name = sender.get_string_member ("screen_name");
      new_msg.avatar_url = sender.get_string_member ("profile_image_url");
      new_msg.timestamp = Utils.parse_date (sender.get_string_member ("created_at")).to_unix ();
      new_msg.load_avatar ();
      delta_updater.add (new_msg);
      messages_list.add (new_msg);
      if (scroll_widget.scrolled_down)
        scroll_widget.scroll_down ();
    }
  } /// }}}


  public void on_join (int page_id, va_list arg_list) { // {{{
    int64 user_id = arg_list.arg<int64> ();
    this.user_id = user_id;

    //Clear list
    messages_list.foreach ((w) => {messages_list.remove (w);});

    var now = new GLib.DateTime.now_local ();
    // Load messages
    int msgs = account.db.select ("dms").cols ("from_id", "to_id", "text", "from_name", "from_screen_name",
                                    "avatar_url", "timestamp")
              .where (@"`from_id`='$user_id' OR `to_id`='$user_id'")
              .order ("timestamp")
              .limit (35)
              .run ((vals) => {
      var entry = new DMListEntry ();
      entry.timestamp = int64.parse (vals[6]);
      entry.text = vals[2];
      entry.name = vals[3];
      entry.screen_name = vals[4];
      entry.avatar_url = vals[5];
      entry.load_avatar ();
      entry.update_time_delta (now);
      delta_updater.add (entry);
      messages_list.add (entry);
      return true;
    });

    // If there are no messages with this user, we insert a placeholder widget
    if (msgs == 0) {
      
    }

    scroll_widget.scroll_down ();
  } // }}}

  public void on_leave () {}

  [GtkCallback]
  private void send_button_clicked_cb () { // {{{
    if (text_entry.buffer.length == 0 || text_entry.buffer.length > 140)
      return;

    // Just add the entry now
    DMListEntry entry = new DMListEntry ();
    entry.screen_name = account.screen_name;
    entry.timestamp = new GLib.DateTime.now_local ().to_unix ();
    entry.text = text_entry.text;
    entry.name = account.name;
    entry.avatar = account.avatar;
    entry.update_time_delta ();
    delta_updater.add (entry);
    messages_list.add (entry);
    var call = account.proxy.new_call ();
    call.set_function ("1.1/direct_messages/new.json");
    call.set_method ("POST");
    call.add_param ("user_id", user_id.to_string ());
    call.add_param ("text", text_entry.text);
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }
    });

    // clear the text entry
    text_entry.text = "";

    // Scroll down
    if (scroll_widget.scrolled_down)
      scroll_widget.scroll_down ();
  } // }}}

  private void recalc_length () {
    uint text_length = text_entry.buffer.length;
    send_button.sensitive = text_length > 0 && text_length < 140;
  }

  public void create_tool_button(RadioToolButton? group) {}
  public RadioToolButton? get_tool_button() {return null;}
  private void update_unread_count() {}

  public int get_id() {
    return id;
  }
}
