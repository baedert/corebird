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


[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-threads-page.ui")]
class DMThreadsPage : IPage, IMessageReceiver, ScrollWidget {
  private bool initialized = false;
  private int _unread_count = 0;
  public int unread_count {
    get {
      return _unread_count;
    }
    set {
      debug ("Changing unread_count from %d to %d", this._unread_count, value);
      this._unread_count = value;
      radio_button.show_badge = (this._unread_count > 0);
    }
  }
  public unowned MainWindow main_window     { get; set; }
  public unowned Account account            { get; set; }
  public unowned DeltaUpdater delta_updater { get; set; }
  public int id                             { get; set; }
  private BadgeRadioButton radio_button;
  private Gee.HashMap<int64?, unowned DMThreadEntry> thread_map = new Gee.HashMap<int64?, unowned DMThreadEntry>
                              (Utils.int64_hash_func, Utils.int64_equal_func, DMThreadEntry.equal_func);
  private StartConversationEntry start_conversation_entry;
  private int64 max_received_id = -1;
  private int64 max_sent_id = -1;
  [GtkChild]
  private Gtk.ListBox thread_list;
  private Gtk.Spinner progress_spinner;
  private Collect dm_download_collect;


  public DMThreadsPage (int id, Account account, DeltaUpdater delta_updater) {
    this.id = id;
    this.account = account;
    this.delta_updater = delta_updater;
    this.dm_download_collect = new Collect (2);
    thread_list.set_header_func (default_header_func);
    thread_list.set_sort_func (dm_thread_entry_sort_func);

    thread_list.row_activated.connect ((row) => {
      if (row is StartConversationEntry)
        ((StartConversationEntry)row).reveal ();
      else if (row is DMThreadEntry) {
        var entry = (DMThreadEntry) row;
        /* We can withdraw the notification here since
           activating the notification will dismiss it */
        if (entry.notification_id != null) {
          GLib.Application.get_default ().withdraw_notification (entry.notification_id);
          entry.notification_id = null;
        }

        var bundle = new Bundle ();
        bundle.put_int64 ("sender_id", entry.user_id);
        main_window.main_widget.switch_page (Page.DM, bundle);
      }
    });
    start_conversation_entry = new StartConversationEntry (account);
    start_conversation_entry.start.connect((user_id, screen_name, name, avatar_url) => {
      var thread_entry = thread_map.get (user_id);
      if (thread_entry != null) {
        this.unread_count -= thread_entry.unread_count;
      }
      var bundle = new Bundle ();
      bundle.put_int64 ("sender_id", user_id);
      bundle.put_string ("screen_name", screen_name);
      bundle.put_string ("name", name);
      bundle.put_string ("avatar_url", avatar_url);
      main_window.main_widget.switch_page (Page.DM, bundle);
    });

    thread_list.add (start_conversation_entry);
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) {
    if (type == StreamMessageType.DIRECT_MESSAGE) {
      var obj = root.get_object ().get_object_member ("direct_message");
      add_new_thread (obj);
      int64 sender_id = obj.get_int_member ("sender_id");
      if (sender_id != account.id) {
        if (!user_id_visible (sender_id)) {
          this.unread_count ++;
          debug ("Increasing global unread count by 1");
        }
      }
    }
  }


  public void on_join (int page_id, Bundle? args) {
    if (!GLib.NetworkMonitor.get_default ().get_network_available ())
      return;


    if (!initialized) {
      load_cached ();
      load_newest ();
      initialized = true;
    }
  }

  public void on_leave () {
    start_conversation_entry.unreveal ();
  }

  public void load_cached () {
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
      entry.name = vals[5].replace ("&", "&amp;");
      entry.last_message = vals[2];
      entry.last_message_id = int64.parse(vals[3]);
      entry.unread_count = 0;
      entry.avatar_url = vals[4];
      entry.load_avatar ();

      thread_list.add (entry);
      thread_map.set (user_id, entry);
      return true;
    });
    if (n_rows == 0 && GLib.NetworkMonitor.get_default ().get_network_available ()) {
      var row = new Gtk.ListBoxRow ();
      progress_spinner = new Gtk.Spinner ();
      progress_spinner.set_size_request (16, 16);
      progress_spinner.margin = 12;
      progress_spinner.start ();
      row.add (progress_spinner);
      row.activatable = false;
      thread_list.add (row);
    }
  }

  public void load_newest () { // {{{
    dm_download_collect.finished.connect (() => {
      remove_spinner ();
      save_last_messages ();
    });

    var call = account.proxy.new_call ();
    call.set_function ("1.1/direct_messages.json");
    call.set_method ("GET");
    call.add_param ("skip_status", "true");
    call.add_param ("since_id", max_received_id.to_string ());
    call.add_param ("count", "200");
    TweetUtils.load_threaded.begin (call, null, (obj, res) => {
      try {
        Json.Node? root = TweetUtils.load_threaded.end (res);
        on_dm_result (root);
      } catch (GLib.Error e) {
        warning (e.message);
        on_dm_result (null);
      }
    });

    var sent_call = account.proxy.new_call ();
    sent_call.set_function ("1.1/direct_messages/sent.json");
    sent_call.add_param ("skip_status", "true");
    sent_call.add_param ("since_id", max_sent_id.to_string ());
    sent_call.add_param ("count", "200");
    sent_call.set_method ("GET");
    TweetUtils.load_threaded.begin (sent_call, null, (obj, res) => {
      try {
        Json.Node? root = TweetUtils.load_threaded.end (res);
        on_dm_result (root);
      } catch (GLib.Error e) {
        warning (e.message);
        on_dm_result (null);
      }
    });

  } // }}}


  private void on_dm_result (Json.Node? root) {
    dm_download_collect.emit ();

    if (root == null)
      return;

    var root_arr = root.get_array ();
    debug ("sent: %u", root_arr.get_length ());
    if (root_arr.get_length () > 0) {
      account.db.begin_transaction ();
      root_arr.foreach_element ((arr, pos, node) => {
        var dm_obj = node.get_object ();
        if (dm_obj.get_int_member ("sender_id") == account.id)
          save_message (dm_obj);
        else
          add_new_thread (dm_obj);
      });
      account.db.end_transaction ();
    }
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
      }
      t_e.last_message = text;
      t_e.last_message_id = message_id;
      account.db.update ("dm_threads").val ("last_message", text)
                                      .vali64 ("last_message_id", message_id)
                                      .where_eqi ("user_id", sender_id).run ();
      t_e.notification_id = notify_new_dm (t_e, Utils.unescape_html (text));
      thread_list.invalidate_sort ();
      return;
    }

    var urls = dm_obj.get_object_member ("entities").get_array_member ("urls");
    var url_list = new TextEntity[urls.get_length ()];
    urls.foreach_element((arr, index, node) => {
      var url = node.get_object();
      string expanded_url = url.get_string_member("expanded_url");

      Json.Array indices = url.get_array_member ("indices");
      expanded_url = expanded_url.replace("&", "&amp;");
      url_list[index] = TextEntity() {
        from = (int)indices.get_int_element (0),
        to   = (int)indices.get_int_element (1) ,
        display_text = url.get_string_member ("display_url")
      };
    });

    var thread_entry = new DMThreadEntry (sender_id);
    var author = dm_obj.get_string_member ("sender_screen_name");
    string sender_name = dm_obj.get_object_member ("sender").get_string_member ("name").strip ();
    thread_entry.name = sender_name.replace ("&", "&amp;");
    thread_entry.screen_name = author;
    thread_entry.last_message = TextTransform.transform (text,
                                                         url_list,
                                                         TransformFlags.EXPAND_LINKS);
    thread_entry.last_message_id = message_id;
    thread_list.add(thread_entry);
    thread_list.invalidate_sort ();
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

    thread_entry.avatar = Twitter.get ().get_avatar (sender_id, avatar_url, (a) => {
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
      var url_list = new TextEntity[urls.get_length ()];
      urls.foreach_element((arr, index, node) => {
        var url = node.get_object();
        string expanded_url = url.get_string_member("expanded_url");

        Json.Array indices = url.get_array_member ("indices");
        expanded_url = expanded_url.replace("&", "&amp;");
        url_list[index] = TextEntity() {
          from = (int)indices.get_int_element (0),
          to   = (int)indices.get_int_element (1) ,
          target = expanded_url,
          display_text = url.get_string_member ("display_url")
        };
      });
      text = TextTransform.transform (text,
                                      url_list,
                                      0);
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

  private void remove_spinner () {
    if (progress_spinner != null && progress_spinner.parent != null) {
      thread_list.remove (thread_list.get_row_at_index (1));
      progress_spinner = null;
    }
  }

  private string? notify_new_dm (DMThreadEntry thread_entry, string msg_text) {
    if (!Settings.notify_new_dms ())
      return null;

    string sender_screen_name = thread_entry.screen_name;
    int64 sender_id = thread_entry.user_id;


    string id = "new-dm-" + sender_id.to_string ();
    string summary;
    string text;
    if (thread_entry.notification_id != null) {
      GLib.Application.get_default ().withdraw_notification (id);
      summary = ngettext ("%d new Message from %s",
                          "%d new Messages from %s",
                          thread_entry.unread_count).printf (thread_entry.unread_count,
                                                             thread_entry.name);
      text = "";
    } else {
      summary = _("New direct message from %s").printf (sender_screen_name);
      text = msg_text;
    }
    var n = new GLib.Notification (summary);
    n.set_body (text);
    var value = new GLib.Variant.tuple ({new GLib.Variant.int64 (account.id),
                                         new GLib.Variant.int64 (sender_id)});
    n.set_default_action_and_target_value ("app.show-dm-thread", value);

    GLib.Application.get_default ().send_notification (id, n);

    return id;
  }

  public void create_radio_button(Gtk.RadioButton? group) {
    radio_button = new BadgeRadioButton(group, "corebird-dms-symbolic", _("Direct Messages"));
  }

  public Gtk.RadioButton? get_radio_button() {
    return radio_button;
  }

  private bool user_id_visible (int64 sender_id) {
    return (main_window.cur_page_id == Page.DM &&
            ((DMPage)main_window.get_page (Page.DM)).user_id == sender_id);
  }


  public string? get_title () {
    return _("Direct Messages");
  }

  public void adjust_unread_count_for_user_id (int64 user_id) {
    DMThreadEntry? user_entry = thread_map.get (user_id);
    if (user_entry == null) {
      warning ("No DMThreadEntry instance for id %s", user_id.to_string ());
      return;
    }

    this.unread_count -= user_entry.unread_count;
    debug ("unread_count -= %d", user_entry.unread_count);
    user_entry.unread_count = 0;
  }

  public string? get_notification_id_for_user_id (int64 user_id) {
    DMThreadEntry? user_entry = thread_map.get (user_id);
    if (user_entry == null) {
      warning ("No DMThreadEntry instance for id %s", user_id.to_string ());
      return null;
    }

    string id = user_entry.notification_id;
    user_entry.notification_id = null;
    return id;
  }
}
