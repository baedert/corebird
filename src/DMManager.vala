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

class DMManager : GLib.Object {
  private unowned Account account;
  private DMThreadsModel threads_model;
  public bool empty {
    get {
      return threads_model.get_n_items () == 0;
    }
  }

  public signal void message_received (DMThread thread, string text, bool initial);
  public signal void thread_changed (DMThread thread);

  public DMManager.for_account (Account account) {
    this.account = account;
    this.threads_model = new DMThreadsModel ();
  }

  public void load_cached_threads () {
    account.db.select ("dm_threads")
              .cols ("user_id", "screen_name", "name", "last_message",
                     "last_message_id")
              .order ("last_message_id")
              .run ((vals) => {
      DMThread thread = new DMThread ();
      thread.user.id = int64.parse (vals[0]);
      thread.user.screen_name = vals[1];
      thread.user.user_name = vals[2];
      thread.last_message_id = int64.parse (vals[4]);
      thread.last_message = vals[3];

      threads_model.add (thread);
      return true;
    });
  }

  public GLib.ListModel get_threads_model () {
    return this.threads_model;
  }

  public bool has_thread (int64 user_id) {
    return this.threads_model.has_thread (user_id);
  }

  public int reset_unread_count (int64 user_id) {
    if (!threads_model.has_thread (user_id)) {
      debug ("No thread found for user id %s", user_id.to_string ());
      return 0;
    }

    int prev_count = threads_model.reset_unread_count (user_id);

    this.thread_changed (threads_model.get_thread (user_id));

    return prev_count;
  }

  public string? reset_notification_id (int64 user_id) {
    if (!threads_model.has_thread (user_id)) {
      debug ("No thread found for user id %s", user_id.to_string ());
      return null;
    }

    return threads_model.reset_notification_id (user_id);
  }

  public async void load_newest_dms () {
    var collect_obj = new Collect (2);
    collect_obj.finished.connect (() => {
      load_newest_dms.callback ();
    });

    int64 max_received_id = account.db.select ("dms").cols ("id")
                               .where_eqi ("to_id", account.id)
                               .order ("id DESC").limit (1).once_i64 ();
    int64 max_sent_id = account.db.select ("dms").cols ("id")
                               .where_eqi ("from_id", account.id)
                               .order ("id DESC").limit (1).once_i64 ();


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
      }
      collect_obj.emit ();
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
      }
      collect_obj.emit ();
    });

    yield;
  }

  private void on_dm_result (Json.Node? root) {
    var root_arr = root.get_array ();
    debug ("sent: %u", root_arr.get_length ());
    if (root_arr.get_length () > 0) {
      account.db.begin_transaction ();
      root_arr.foreach_element ((arr, pos, node) => {
        var dm_obj = node.get_object ();
        if (dm_obj.get_int_member ("sender_id") == account.id) {
          save_message (dm_obj, true);
        } else {
          update_thread (dm_obj, true);
        }
      });
      account.db.end_transaction ();
    }
  }

  public void insert_message (Json.Object dm_obj) {
    if (dm_obj.get_int_member ("sender_id") == account.id) {
      save_message (dm_obj, false);
    } else {
      update_thread (dm_obj, false);
    }
  }

  /* We are ONLY calling this for RECEIVED messages, not sent ones. */
  private void update_thread (Json.Object dm_obj, bool initial) {
    int64 sender_id  = dm_obj.get_int_member ("sender_id");
    int64 message_id = dm_obj.get_int_member ("id");
    assert (sender_id != account.id);

    string source_text = dm_obj.get_string_member ("text");

    var urls = dm_obj.get_object_member ("entities").get_array_member ("urls");
    var url_list = new TextEntity[urls.get_length ()];
    urls.foreach_element((arr, index, node) => {
      var url = node.get_object();
      string expanded_url = url.get_string_member("expanded_url");

      Json.Array indices = url.get_array_member ("indices");
      url_list[index] = TextEntity() {
        from = (int)indices.get_int_element (0),
        to   = (int)indices.get_int_element (1) ,
        display_text = url.get_string_member ("display_url"),
        target = expanded_url.replace ("&", "&amp;"),
        tooltip_text = expanded_url
      };
    });

    string text = TextTransform.transform (source_text,
                                           url_list,
                                           TransformFlags.EXPAND_LINKS);
    string sender_screen_name = dm_obj.get_string_member ("sender_screen_name");
    string sender_name = dm_obj.get_object_member ("sender").get_string_member ("name")
                                                            .strip ().replace ("&", "&amp;");

    if (!threads_model.has_thread (sender_id)) {
      DMThread thread = new DMThread ();
      thread.user.id = sender_id;
      thread.user.screen_name = sender_screen_name;
      thread.user.user_name = sender_name;
      thread.last_message = text;
      thread.last_message_id = message_id;
      this.threads_model.add (thread);

      account.db.insert ("dm_threads")
             .vali64 ("user_id", sender_id)
             .val ("screen_name", sender_screen_name)
             .val ("name", sender_name)
             .val ("last_message", text)
             .vali64 ("last_message_id", message_id)
             .run ();
    } else {
      DMThread thread = threads_model.get_thread (sender_id);
      if (message_id > thread.last_message_id) {
        this.threads_model.update_last_message (sender_id, message_id, text);
        account.db.update ("dm_threads").val ("last_message", text)
                                        .vali64 ("last_message_id", message_id)
                                        .where_eqi ("user_id", sender_id).run ();

        this.thread_changed (thread);
      }
    }

    account.user_counter.user_seen (sender_id, sender_screen_name, sender_name);

    /* This will exctract the json data again, etc. but it's still easier than
     * replacing entities here... */
    save_message (dm_obj, initial);
  }


  private void save_message (Json.Object dm_obj, bool initial) {
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
        url_list[index] = TextEntity() {
          from = (int)indices.get_int_element (0),
          to   = (int)indices.get_int_element (1) ,
          target = expanded_url.replace ("&", "&amp;"),
          tooltip_text = expanded_url,
          display_text = url.get_string_member ("display_url")
        };
      });
      text = TextTransform.transform (text,
                                      url_list,
                                      0);
    }

    account.db.insert ("dms").vali64 ("id", dm_id)
              .vali64 ("from_id", sender_id)
              .vali64 ("to_id", dm_obj.get_int_member ("recipient_id"))
              .val ("from_screen_name", dm_obj.get_string_member ("sender_screen_name"))
              .val ("to_screen_name", dm_obj.get_string_member ("recipient_screen_name"))
              .val ("from_name", sender.get_string_member ("name"))
              .val ("to_name", recipient.get_string_member ("name"))
              .vali64 ("timestamp", Utils.parse_date (dm_obj.get_string_member ("created_at")).to_unix ())
              .val ("text", text)
              .run ();

    /* We do NOT update last_message of the maybe-existing thread here, since
       we are already doing that for received messages and don't need to do it
       for sent ones. */

    /* Update unread count for the thread */
    if (sender_id != account.id && threads_model.has_thread (sender_id)) {
      DMThread thread = threads_model.get_thread (sender_id);
      threads_model.increase_unread_count (sender_id);
      this.message_received (thread, text, initial);
      this.thread_changed (thread);
    }
  }
}
