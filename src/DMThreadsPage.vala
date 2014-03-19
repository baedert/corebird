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
  public int id                             { get; set; }
  private BadgeRadioToolButton tool_button;
  private HashMap<int64?, unowned DMThreadEntry> thread_map = new HashMap<int64?, unowned DMThreadEntry>
                              (Utils.int64_hash_func, Utils.int64_equal_func, DMThreadEntry.equal_func);
  private StartConversationEntry start_conversation_entry;
  private int64 max_received_id = -1;
  private int64 max_sent_id = -1;
  [GtkChild]
  private Gtk.ListBox thread_list;
  private Gtk.Spinner progress_spinner;
  private bool dms_received = false;
  private signal void dm_download_complete ();


  public DMThreadsPage (int id, Account account) {
    this.id = id;
    this.account = account;
    thread_list.set_header_func (header_func);
    thread_list.set_sort_func (dm_thread_entry_sort_func);

    thread_list.row_activated.connect ((row) => {
      if (row is StartConversationEntry)
        ((StartConversationEntry)row).reveal ();
      else {
        var entry = (DMThreadEntry) row;
        this.unread_count -= entry.unread_count;
        entry.unread_count = 0;
        entry.update_unread_count ();
        this.update_unread_count ();
        main_window.switch_page (MainWindow.PAGE_DM,
                                 entry.user_id);
      }
    });
    start_conversation_entry = new StartConversationEntry (account);
    start_conversation_entry.start.connect((user_id, screen_name, name, avatar_url) => {
      var thread_entry = thread_map.get (user_id);
      if (thread_entry != null) {
        this.unread_count -= thread_entry.unread_count;
      }
      main_window.switch_page (MainWindow.PAGE_DM, user_id,
                              screen_name, name, avatar_url);
    });

    thread_list.add (start_conversation_entry);
    load_cached ();
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) {
    if (type == StreamMessageType.DIRECT_MESSAGE) {
      var obj = root.get_object ().get_object_member ("direct_message");
      add_new_thread (obj);
      int64 sender_id = obj.get_int_member ("sender_id");
      if (sender_id != account.id) {
        if (!user_id_visible (sender_id)) {
          this.unread_count ++;
          this.update_unread_count ();
        }
        debug ("Increasing global unread count by 1");
      }
    }
  }


  public void on_join (int page_id, va_list arg_list) {
    if (!initialized) {
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
    int n_rows = account.db.select ("dm_threads")
              .cols ("user_id", "screen_name", "last_message", "last_message_id", "avatar_url", "name")
              .order ("last_message_id")
              .run ((vals) => {
      int64 user_id = int64.parse (vals[0]);

      var entry = new DMThreadEntry (user_id);
      entry.screen_name =  vals[1];
      entry.name = vals[5];
      entry.last_message = vals[2];
      entry.last_message_id = int64.parse(vals[3]);
      entry.unread_count = 0;
      entry.avatar = Twitter.get ().get_avatar (vals[4], (a) => {
        entry.avatar = a;
      });


      thread_list.add (entry);
      thread_map.set (user_id, entry);
      return true;
    });
    if (n_rows == 0) {
      progress_spinner = new Gtk.Spinner ();
      progress_spinner.set_size_request (60, 60);
      progress_spinner.start ();
      thread_list.add (progress_spinner);
    }
  } // }}}

  public void load_newest () { // {{{
    var call = account.proxy.new_call ();
    call.set_function ("1.1/direct_messages.json");
    call.set_method ("GET");
    call.add_param ("skip_status", "true");
    call.add_param ("since_id", max_received_id.to_string ());
    call.add_param ("count", "200");
    call.invoke_async.begin (null, (obj, res) => {
      if (!dms_received) {
        // we are the first one to receive the results
        dms_received = true;
        dm_download_complete.connect (() => {
          on_dm_result (obj, res);
        });
      } else {
        remove_spinner ();
        on_dm_result (obj, res);
        dm_download_complete ();
      }
    });

    var sent_call = account.proxy.new_call ();
    sent_call.set_function ("1.1/direct_messages/sent.json");
    sent_call.add_param ("skip_status", "true");
    sent_call.add_param ("since_id", max_sent_id.to_string ());
    sent_call.add_param ("count", "200");
    sent_call.set_method ("GET");
    sent_call.invoke_async.begin (null, (obj, res) => {
      if (!dms_received) {
        // we are the first one to receive the results
        dms_received = true;
        dm_download_complete.connect (() => {
          on_dm_result (obj, res);
        });
      } else {
        remove_spinner ();
        on_dm_result (obj, res);
        dm_download_complete ();
      }
    });
  } // }}}


  private void on_dm_result (GLib.Object? object, GLib.AsyncResult res) {
    var call = (Rest.ProxyCall) object;
    try {
      call.invoke_async.end (res);
    } catch (GLib.Error e) {
      critical (e.message);
      return;
    }
    var parser = new Json.Parser ();
    try {
      parser.load_from_data (call.get_payload ());
    } catch (GLib.Error e) {
      critical (e.message);
      return;
    }
    var root_arr = parser.get_root ().get_array ();
    message ("sent: %u", root_arr.get_length ());
    account.db.begin_transaction ();
    root_arr.foreach_element ((arr, pos, node) => {
      var dm_obj = node.get_object ();
      if (dm_obj.get_int_member ("sender_id") == account.id)
        save_message (dm_obj);
      else
        add_new_thread (dm_obj);
    });
    account.db.end_transaction ();
    save_last_messages ();
  }


  private void add_new_thread (Json.Object dm_obj) { // {{{
    int64 sender_id  = dm_obj.get_int_member ("sender_id");
    int64 message_id = dm_obj.get_int_member ("id");
    save_message (dm_obj);
    if (sender_id == account.id)
      return;

    string text = dm_obj.get_string_member ("text");

    if (thread_map.has_key(sender_id)) {
      var t_e = thread_map.get (sender_id);
      if (t_e.last_message_id > message_id)
        return;

      if (!user_id_visible (t_e.user_id)) {
        t_e.unread_count ++;
        t_e.update_unread_count ();
      }
      t_e.last_message = text;
      t_e.last_message_id = message_id;
      if (Settings.notify_new_dms ()) {
        NotificationManager.notify_pixbuf( _("New direct message!"), text, t_e.avatar);
      }
      return;
    }

    var urls = dm_obj.get_object_member ("entities").get_array_member ("urls");
    var url_list = new GLib.SList<TweetUtils.Sequence?> ();
    urls.foreach_element((arr, index, node) => {
      var url = node.get_object();
      string expanded_url = url.get_string_member("expanded_url");

      Json.Array indices = url.get_array_member ("indices");
      expanded_url = expanded_url.replace("&", "&amp;");
      url_list.prepend(TweetUtils.Sequence() {
        start = (int)indices.get_int_element (0),
        end   = (int)indices.get_int_element (1) ,
        url   = url.get_string_member ("display_url"),
        visual_display_url = false
      });
    });

    var thread_entry = new DMThreadEntry (sender_id);
    var author = dm_obj.get_string_member ("sender_screen_name");
    string sender_name = dm_obj.get_object_member ("sender").get_string_member ("name");
    thread_entry.name = sender_name;
    thread_entry.screen_name = author;
    thread_entry.last_message = TweetUtils.get_real_text (text, url_list);
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
    account.user_counter.user_seen (sender_id, author, sender_name);

    thread_entry.avatar = Twitter.get ().get_avatar (avatar_url, (a) => {
      thread_entry.avatar = a;
    });
  } // }}}

  private void save_message (Json.Object dm_obj) { // {{{
    Json.Object sender = dm_obj.get_object_member ("sender");
    Json.Object recipient = dm_obj.get_object_member ("recipient");
    int64 sender_id = dm_obj.get_int_member ("sender_id");
    int64 dm_id  = dm_obj.get_int_member ("id");
    string text = dm_obj.get_string_member ("text");
    if (dm_obj.has_member ("entities")) {
      var urls = dm_obj.get_object_member ("entities").get_array_member ("urls");
      var url_list = new GLib.SList<TweetUtils.Sequence?> ();
      urls.foreach_element((arr, index, node) => {
        var url = node.get_object();
        string expanded_url = url.get_string_member("expanded_url");

        Json.Array indices = url.get_array_member ("indices");
        expanded_url = expanded_url.replace("&", "&amp;");
        url_list.prepend(TweetUtils.Sequence() {
          start = (int)indices.get_int_element (0),
          end   = (int)indices.get_int_element (1) ,
          url   = expanded_url,
          display_url = url.get_string_member ("display_url"),
          visual_display_url = false
        });
      });
      text = TweetUtils.get_formatted_text (text, url_list);
    }

    // TODO: Update last_message
    account.db.insert ("dms").vali64 ("id", dm_id)
              .vali64 ("from_id", sender_id)
              .vali64 ("to_id", dm_obj.get_int_member ("recipient_id"))
              .val ("from_screen_name", dm_obj.get_string_member ("sender_screen_name"))
              .val ("to_screen_name", dm_obj.get_string_member ("recipient_screen_name"))
              .val ("from_name", sender.get_string_member ("name"))
              .val ("to_name", recipient.get_string_member ("name"))
              .val ("avatar_url", sender.get_string_member ("profile_image_url"))
              .vali64 ("timestamp", Utils.parse_date (dm_obj.get_string_member ("created_at")).to_unix ())
              .val ("text", text)
              .run ();
    if (sender_id != account.id)
      max_received_id = dm_id;
    else
      max_sent_id = dm_id;
  } // }}}


  private void save_last_messages () {
    account.db.begin_transaction ();
    foreach (var thread_entry in thread_map.values) {
      account.db.update ("dm_threads").val ("last_message", thread_entry.last_message)
                .where_eqi ("user_id", thread_entry.user_id).run ();
    }
    account.db.end_transaction ();
  }

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

  private void remove_spinner () {
    if (progress_spinner != null && progress_spinner.parent != null) {
      thread_list.remove (thread_list.get_row_at_index (1));
      progress_spinner = null;
    }
  }

  public void create_tool_button(RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "corebird-dms-symbolic");
    tool_button.label = _("Direct Messages");
    tool_button.tooltip_text = _("Direct Messages");
  }

  public RadioToolButton? get_tool_button() {
    return tool_button;
  }

  private bool user_id_visible (int64 sender_id) {
    return (main_window.cur_page_id == MainWindow.PAGE_DM &&
            ((DMPage)main_window.get_page (MainWindow.PAGE_DM)).user_id == sender_id);
  }

  private void update_unread_count() {
    tool_button.show_badge = (unread_count > 0);
    tool_button.queue_draw();
  }
}
