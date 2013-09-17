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
  public unowned MainWindow main_window {set; get;}
  public unowned Account account        {get; set;}
  private int id;
  [GtkChild]
  private Button send_button;
  [GtkChild]
  private Entry text_entry;
  [GtkChild]
  private ListBox message_list;


  public DMPage (int id) {
    this.id = id;
    this.button_press_event.connect (button_pressed_event_cb);
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) {
    if (type == StreamMessageType.DIRECT_MESSAGE) {
      unread_count ++;
      var obj = root.get_object ().get_object_member ("direct_message");
      update_unread_count ();
    }
  }


  public void on_join (int page_id, va_list arg_list) {
    if (!initialized) {
//      load_cached ();
//      load_newest ();
      initialized = true;
    }
  }

  public void on_leave () {

  }


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
