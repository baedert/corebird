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

class DMPage : IPage, Cb.MessageReceiver, Gtk.Box {
  public const int KEY_SENDER_ID   = 0;
  public const int KEY_SCREEN_NAME = 1;
  public const int KEY_USER_NAME   = 2;
  public const int KEY_AVATAR_URL  = 3;

  public int unread_count                   { get { return 0; } }
  private unowned Cb.MainWindow _main_window;
  public unowned Cb.MainWindow main_window {
    set {
      _main_window = value;
    }
  }
  public unowned Account account;
  public int id                             { get; set; }
  private Gtk.Button send_button;
  private Cb.TextView text_view;
  private Gtk.ListBox messages_list;
  private ScrollWidget scroll_widget;
  private DMPlaceholderBox placeholder_box;

  public int64 user_id;
  private int64 lowest_id = int64.MAX;

  public DMPage (int id, Account account) {
    this.id = id;
    this.account = account;

    /* Set up UI */
    this.set_orientation (Gtk.Orientation.VERTICAL);

    this.scroll_widget = new ScrollWidget ();
    scroll_widget.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
    scroll_widget.set_vexpand (true);
    scroll_widget.scrolled_to_start.connect (load_older);
    this.messages_list = new Gtk.ListBox ();
    messages_list.set_selection_mode (Gtk.SelectionMode.NONE);
    messages_list.set_sort_func (twitter_item_sort_func_inv);
    this.placeholder_box = new DMPlaceholderBox ();
    messages_list.set_placeholder (placeholder_box);
    scroll_widget.add (messages_list);
    this.add (scroll_widget);

    var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
    this.text_view = new Cb.TextView ();
    text_view.set_hexpand (true);
    text_view.changed.connect (recalc_length);
    text_view.send.connect (send_button_clicked_cb);
    text_view.set_account (account);
    bottom_box.add (text_view);

    this.send_button = new Gtk.Button.with_label (_("Send"));
    send_button.set_receives_default (true);
    send_button.set_valign (Gtk.Align.START);
    send_button.get_style_context ().add_class ("suggested-action");
    send_button.clicked.connect (send_button_clicked_cb);
    bottom_box.add (send_button);
    this.add (bottom_box);
  }

  public void stream_message_received (Cb.StreamMessageType type, Json.Node root) {
    if (type == Cb.StreamMessageType.DIRECT_MESSAGE) {
      // Arriving new dms get already cached in the DMThreadsPage
      var obj = root.get_object ().get_object_member ("direct_message");


      /* XXX Replace this with local entity parsing */
      if (obj.get_int_member ("sender_id") == account.id &&
          obj.has_member ("entities")) {
        var entries = messages_list.get_children ();

        int64 dm_id = obj.get_int_member ("id");

        foreach (var entry in entries) {
          var e = (DMListEntry) entry;
          if (e.user_id == account.id &&
              e.id == -1) {

            var text = obj.get_string_member ("text");
            var urls = obj.get_object_member ("entities").get_array_member ("urls");
            var url_list = new Cb.TextEntity[urls.get_length ()];
            urls.foreach_element((arr, index, node) => {
              var url = node.get_object();
              string expanded_url = url.get_string_member("expanded_url");

              Json.Array indices = url.get_array_member ("indices");
              expanded_url = expanded_url.replace("&", "&amp;");
              url_list[index] = Cb.TextEntity() {
                from = (int)indices.get_int_element (0),
                to   = (int)indices.get_int_element (1) ,
                target = expanded_url,
                display_text = url.get_string_member ("display_url")
              };
            });
            e.text = Cb.TextTransform.text (text,
                                            url_list,
                                            0, 0, 0);

            e.id = dm_id;
            break;
          }
        }
      }


      /* Only handle DMs from the user we are currently chatting with */
      if (obj.get_int_member ("sender_id") != this.user_id)
        return;

      /* Writing with ourselves, we have the message already */
      if (this.user_id == this.account.id)
        return;

      var text = obj.get_string_member ("text");
      if (obj.has_member ("entities")) {
        var urls = obj.get_object_member ("entities").get_array_member ("urls");
        var url_list = new Cb.TextEntity[urls.get_length ()];
        urls.foreach_element((arr, index, node) => {
          var url = node.get_object();
          string expanded_url = url.get_string_member("expanded_url");

          Json.Array indices = url.get_array_member ("indices");
          url_list[index] = Cb.TextEntity() {
            from = (uint)indices.get_int_element (0),
            to   = (uint)indices.get_int_element (1) ,
            target = expanded_url.replace ("&", "&amp;"),
            tooltip_text = expanded_url,
            display_text = url.get_string_member ("display_url")
          };
        });
        text = Cb.TextTransform.text (text,
                                      url_list,
                                      0, 0, 0);
      }

      var sender = obj.get_object_member ("sender");
      var new_msg = new DMListEntry ();
      new_msg.text = text;
      new_msg.name = sender.get_string_member ("name");
      new_msg.screen_name = sender.get_string_member ("screen_name");
      new_msg.timestamp = Cb.Utils.parse_date (obj.get_string_member ("created_at")).to_unix ();
      new_msg.main_window = _main_window;
      new_msg.user_id = sender.get_int_member ("id");
      new_msg.update_time_delta ();
      new_msg.load_avatar (sender.get_string_member ("profile_image_url"));
      messages_list.add (new_msg);
      if (scroll_widget.scrolled_down)
        scroll_widget.scroll_down_next ();
    }
  }

  private void load_older () {
    var now = new GLib.DateTime.now_local ();
    scroll_widget.balance_next_upper_change (TOP);
    // Load messages
    // TODO: Fix code duplication
    var query = account.db.select ("dms")
                          .cols ("from_id", "to_id", "text", "from_name", "from_screen_name",
                                 "timestamp", "id");

    if (user_id == account.id)
      query.where (@"`from_id`='$user_id' AND `to_id`='$user_id' AND `id` < '$lowest_id'");
    else
      query.where (@"(`from_id`='$user_id' OR `to_id`='$user_id') AND `id` < '$lowest_id'");

      query.order ("timestamp DESC")
           .limit (35)
           .run ((vals) => {
      int64 id = int64.parse (vals[6]);
      if (id < lowest_id)
        lowest_id = id;

      var entry = new DMListEntry ();
      entry.id = id;
      entry.user_id = int64.parse (vals[0]);
      entry.timestamp = int64.parse (vals[5]);
      entry.text = vals[2];
      entry.name = vals[3];
      entry.screen_name = vals[4];
      entry.main_window = _main_window;
      entry.update_time_delta (now);
      Twitter.get ().load_avatar_for_user_id.begin (account,
                                                    entry.user_id,
                                                    48 * this.get_scale_factor (),
                                                    (obj, res) => {
        Gdk.Texture? s = Twitter.get ().load_avatar_for_user_id.end (res);
        entry.avatar = s;
      });
      messages_list.add (entry);
      return true;
    });

  }

  public void on_join (int page_id, Cb.Bundle? args) {
    int64 user_id = args.get_int64 (KEY_SENDER_ID);
    if (user_id == 0)
      return;

    this.lowest_id = int64.MAX;
    this.user_id = user_id;
    string screen_name;
    string name = null;
    if ((screen_name = args.get_string (KEY_SCREEN_NAME)) != null) {
      name = args.get_string (KEY_USER_NAME);
      placeholder_box.user_id = user_id;
      placeholder_box.screen_name = screen_name;
      placeholder_box.name = name;
      placeholder_box.avatar_url = args.get_string (KEY_AVATAR_URL);
      placeholder_box.load_avatar ();
    }

    // Clear list
    messages_list.foreach ((w) => {messages_list.remove (w);});

    // Update unread count
    DMThreadsPage threads_page = ((DMThreadsPage)_main_window.get_page (Page.DM_THREADS));
    threads_page.adjust_unread_count_for_user_id (user_id);

    var now = new GLib.DateTime.now_local ();
    // Load messages
    var query = account.db.select ("dms")
                           .cols ("from_id", "to_id", "text", "from_name", "from_screen_name",
                                  "timestamp", "id");
    if (user_id == account.id)
      query.where (@"`from_id`='$user_id' AND `to_id`='$user_id'");
    else
      query.where (@"`from_id`='$user_id' OR `to_id`='$user_id'");

    query.order ("timestamp DESC")
         .limit (35)
         .run ((vals) => {
      int64 id = int64.parse (vals[6]);
      if (id < lowest_id)
        lowest_id = id;

      var entry = new DMListEntry ();
      entry.id = id;
      entry.user_id = int64.parse (vals[0]);
      entry.timestamp = int64.parse (vals[5]);
      entry.text = vals[2];
      entry.name = vals[3];
      name = vals[3];
      entry.screen_name = vals[4];
      screen_name = vals[4];
      entry.main_window = _main_window;
      entry.update_time_delta (now);
      Twitter.get ().load_avatar_for_user_id.begin (account,
                                                    entry.user_id,
                                                    48 * this.get_scale_factor (),
                                                    (obj, res) => {
        Gdk.Texture? s = Twitter.get ().load_avatar_for_user_id.end (res);
        entry.avatar = s;
      });
      messages_list.add (entry);
      return true;
    });

    account.user_counter.user_seen (user_id, screen_name, name);

    scroll_widget.scroll_down_next (false, true);

    // Focus the text entry
    text_view.grab_focus ();
  }

  public void on_leave () {}

  private void send_button_clicked_cb () {
    if (text_view.get_text ().length == 0)
      return;

    // Withdraw the notification if there is one
    DMThreadsPage threads_page = ((DMThreadsPage)_main_window.get_page (Page.DM_THREADS));
    string notification_id = threads_page.get_notification_id_for_user_id (this.user_id);
    if (notification_id != null)
      GLib.Application.get_default ().withdraw_notification (notification_id);


    // Just add the entry now
    DMListEntry entry = new DMListEntry ();
    entry.id = -1;
    entry.user_id = account.id;
    entry.screen_name = account.screen_name;
    entry.timestamp = new GLib.DateTime.now_local ().to_unix ();
    entry.text = GLib.Markup.escape_text (text_view.get_text ());
    entry.name = account.name;
    entry.avatar = account.avatar;
    entry.update_time_delta ();
    messages_list.add (entry);
    var call = account.proxy.new_call ();
    call.set_function ("1.1/direct_messages/new.json");
    call.set_method ("POST");
    call.add_param ("user_id", user_id.to_string ());
    call.add_param ("text", text_view.get_text ());
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE, this._main_window);
        return;
      }
    });

    // clear the text entry
    text_view.set_text ("");

    // Scroll down
    if (scroll_widget.scrolled_down)
      scroll_widget.scroll_down_next ();
  }

  private void recalc_length () {
    uint text_length = text_view.get_text ().length;
    send_button.sensitive = text_length > 0;
  }


  public string get_title () {
    return _("Direct Conversation");
  }

  public void create_radio_button (Gtk.RadioButton? group) {}
  public BadgeRadioButton? get_radio_button() {return null;}
}
