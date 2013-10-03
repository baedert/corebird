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
  private bool initialized = false;
  public int unread_count               {get; set;}
  public unowned MainWindow main_window {get; set;}
  public unowned Account account        {get; set;}
  private int id;
  [GtkChild]
  private Button send_button;
  [GtkChild]
  private Entry text_entry;
  [GtkChild]
  private ListBox messages_list;

  private int64 user_id;


  public DMPage (int id) {
    this.id = id;
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) {
    if (type == StreamMessageType.DIRECT_MESSAGE) {
      unread_count ++;
      var obj = root.get_object ().get_object_member ("direct_message");
      update_unread_count ();
    }
  }


  public void on_join (int page_id, va_list arg_list) {
    int64 user_id = arg_list.arg<int64> ();
    if (user_id == this.user_id)
      return;

    this.user_id = user_id;

    //Clear list
    messages_list.foreach ((w) => {messages_list.remove (w);});

    // Load messages
    account.db.select ("dms").cols ("from_id", "to_id", "text", "from_name", "from_screen_name")
              .where (@"`from_id`='$user_id' OR `to_id`='$user_id'")
              .order ("timestamp")
              .run ((vals) => {
      var entry = new DMListEntry ();
      entry.text = vals[2];
      entry.name = vals[3];
      entry.screen_name = vals[4];
      messages_list.add (entry);
      return true;
    });


    if (!initialized) {
//      load_cached ();
//      load_newest ();
      initialized = true;
    }
  }

  public void on_leave () {}

  [GtkCallback]
  private void send_button_clicked_cb () {
    message ("SEND MESSAGE");
  }



  public void create_tool_button(RadioToolButton? group) {}
  public RadioToolButton? get_tool_button() {return null;}
  private void update_unread_count() {}

  public int get_id() {
    return id;
  }
}
