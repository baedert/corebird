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

class DMThreadsPage : IPage, Cb.MessageReceiver, Cb.ScrollWidget {
  private bool initialized = false;
  private int _unread_count = 0;
  public int unread_count {
    get {
      return _unread_count;
    }
    set {
      //debug ("Changing unread_count from %d to %d", this._unread_count, value);
      this._unread_count = value;
      radio_button.show_badge = (this._unread_count > 0);
    }
  }
  private unowned Cb.MainWindow _main_window;
  public unowned Cb.MainWindow main_window {
    set {
      _main_window = value;
    }
  }
  public unowned Account account;
  public int id                             { get; set; }
  private BadgeRadioButton radio_button;
  private StartConversationEntry start_conversation_entry;
  private Gtk.ListBox thread_list;
  private Gtk.ListBox top_list;
  private Gtk.ListBoxRow? progress_row = null;

  private DMManager manager;


  public DMThreadsPage (int id, Account account) {
    this.id = id;
    this.account = account;
    this.manager = new DMManager.for_account (account);
    this.manager.message_received.connect (dm_received_cb);
    this.manager.thread_changed.connect (thread_changed_cb);

    /* Create UI */
    this.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
    var frame = new Gtk.Frame (null);
    frame.margin = 25;
    frame.set_valign (Gtk.Align.START);
    frame.set_shadow_type (Gtk.ShadowType.IN);
    frame.show ();
    var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
    frame.add (box);
    box.show ();
    this.top_list = new Gtk.ListBox ();
    top_list.show ();
    top_list.set_selection_mode (Gtk.SelectionMode.NONE);
    top_list.keynav_failed.connect (top_list_keynav_failed_cb);
    box.add (top_list);
    var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
    sep.show ();
    box.add (sep);
    thread_list = new Gtk.ListBox ();
    thread_list.set_valign (Gtk.Align.START);
    thread_list.set_selection_mode (Gtk.SelectionMode.NONE);
    thread_list.keynav_failed.connect (thread_list_keynav_failed_cb);
    thread_list.set_header_func (default_header_func);
    box.add (thread_list);
    this.add (frame);


    top_list.row_activated.connect ((row) => {
      if (row is StartConversationEntry) {
        ((StartConversationEntry)row).reveal ();
      }
    });

    thread_list.row_activated.connect ((row) => {
      if (row is DMThreadEntry) {
        var entry = (DMThreadEntry) row;
        /* We can withdraw the notification here since
           activating the notification will dismiss it */
        if (manager.has_thread (entry.user_id)) {
          string? notification_id = manager.reset_notification_id (entry.user_id);
          if (notification_id != null)
            GLib.Application.get_default ().withdraw_notification (notification_id);
        }

        var bundle = new Cb.Bundle ();
        bundle.put_int64 (DMPage.KEY_SENDER_ID, entry.user_id);
        _main_window.main_widget.switch_page (Page.DM, bundle);
      } else
        warning ("activated row is not a DMThreadEntry");
    });
    start_conversation_entry = new StartConversationEntry (account);
    start_conversation_entry.start.connect((user_id, screen_name, name, avatar_url) => {
      if (manager.has_thread (user_id)) {
        this.unread_count -= manager.reset_unread_count (user_id);
      }
      var bundle = new Cb.Bundle ();
      bundle.put_int64 (DMPage.KEY_SENDER_ID, user_id);
      bundle.put_string (DMPage.KEY_SCREEN_NAME, screen_name);
      bundle.put_string (DMPage.KEY_USER_NAME, name);
      bundle.put_string (DMPage.KEY_AVATAR_URL, avatar_url);
      _main_window.main_widget.switch_page (Page.DM, bundle);
    });


    Cb.Utils.bind_model (thread_list, manager.get_threads_model (), thread_widget_func);

    top_list.add (start_conversation_entry);

    /* We need to do this here so we know which threads we already have cached */
    manager.load_cached_threads ();
  }

  private Gtk.Widget thread_widget_func (GLib.Object item) {
    DMThread thread = (DMThread) item;

    var row = new DMThreadEntry (thread.user.id);
    row.screen_name = thread.user.screen_name;
    row.name = thread.user.user_name;
    row.last_message = thread.last_message;
    row.unread_count = thread.unread_count;
    thread.load_avatar.begin (this.account, this.get_scale_factor (), () => {
      row.avatar = thread.avatar_texture;
    });

    return row;
  }

  void dm_received_cb (DMThread thread, string text, bool initial) {
    assert (thread.user.id != account.id);

    if (thread.user.id != account.id) {
      if (!user_id_visible (thread.user.id)) {
        this.unread_count ++;
        debug ("Increasing global unread count by 1");
      }
    }

    if (!initial) {
      this.notify_new_dm (thread, text);
    }
  }

  void thread_changed_cb (DMThread thread) {
    foreach (Gtk.Widget w in this.thread_list.get_children ()) {
      if (w is DMThreadEntry) {
        var entry = (DMThreadEntry) w;
        if (entry.user_id == thread.user.id) {
          entry.last_message = thread.last_message;
          entry.unread_count = thread.unread_count;
          break;
        }
      }
    }
  }
  public void stream_message_received (Cb.StreamMessageType type, Json.Node root) {
    if (type == Cb.StreamMessageType.DIRECT_MESSAGE) {
      var obj = root.get_object ().get_object_member ("direct_message");
      this.manager.insert_message (obj);
    }
  }

  public void on_join (int page_id, Cb.Bundle? args) {
    if (!GLib.NetworkMonitor.get_default ().get_network_available ())
      return;


    if (!initialized) {
      bool was_empty = manager.empty;
      if (was_empty) {
        top_list.hide ();
        this.progress_row = new Gtk.ListBoxRow ();
        var spinner = new Gtk.Spinner ();
        spinner.set_size_request (16, 16);
        spinner.margin = 12;
        spinner.visible = true;
        spinner.start ();
        progress_row.add (spinner);
        progress_row.activatable = false;
        progress_row.visible = true;
        thread_list.add (progress_row);
      }
      this.manager.load_newest_dms.begin (() => {
        if (was_empty) {
          if (this.progress_row != null) {
            thread_list.remove (progress_row);
            this.progress_row = null;
          }

          top_list.show ();

          foreach (Gtk.Widget w in thread_list.get_children ()) {
            w.show ();
          }
        }
      });
      this.initialized = true;
    }
  }

  public void on_leave () {
    start_conversation_entry.unreveal ();
  }

  private void notify_new_dm (DMThread thread, string msg_text) {
    if (!Settings.notify_new_dms ())
      return;

    string sender_screen_name = thread.user.screen_name;
    int64 sender_id = thread.user.id;

    string summary;
    string text;
    if (thread.notification_id != null) {
      summary = ngettext ("%d new Message from %s",
                          "%d new Messages from %s",
                          thread.unread_count).printf (thread.unread_count,
                                                       thread.user.user_name);
      text = "";
    } else {
      summary = _("New direct message from %s").printf (sender_screen_name);
      text = msg_text;
    }
    thread.notification_id = account.notifications.send_dm (sender_id,
                                                            thread.notification_id,
                                                            summary,
                                                            text);
  }

  public void create_radio_button(Gtk.RadioButton? group) {
    radio_button = new BadgeRadioButton(group, "corebird-dms-symbolic", _("Direct Messages"));
  }

  public BadgeRadioButton? get_radio_button() {
    return radio_button;
  }

  private bool user_id_visible (int64 sender_id) {
    return (_main_window.get_cur_page_id () == Page.DM &&
            ((DMPage)_main_window.get_page (Page.DM)).user_id == sender_id);
  }


  public string get_title () {
    return _("Direct Messages");
  }

  public void adjust_unread_count_for_user_id (int64 user_id) {
    int unread_count = manager.reset_unread_count (user_id);
    this.unread_count -= unread_count;
    debug ("unread_count -= %d", unread_count);
  }

  public string? get_notification_id_for_user_id (int64 user_id) {
    if (!manager.has_thread (user_id)) {
      warning ("No thread for user id %s", user_id.to_string ());
      return null;
    }

    string? id = manager.reset_notification_id (user_id);
    return id;
  }

  private bool top_list_keynav_failed_cb (Gtk.DirectionType direction) {
    if (direction == Gtk.DirectionType.DOWN) {
      if (thread_list.visible) {
        thread_list.child_focus (direction);
      }
      return true;
    }
    return false;
  }

  private bool thread_list_keynav_failed_cb (Gtk.DirectionType direction) {
    if (direction == Gtk.DirectionType.UP) {
      top_list.child_focus (direction);
      return true;
    }
    return false;
  }
}
