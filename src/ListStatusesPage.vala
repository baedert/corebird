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

[GtkTemplate (ui = "/org/baedert/corebird/ui/list-statuses-page.ui")]
class ListStatusesPage : ScrollWidget, IPage {
  public int id                             { get; set; }
  private unowned MainWindow main_window;
  public unowned MainWindow window {
    set {
      main_window = value;
    }
  }
  public unowned Account account;
  private int64 list_id;
  private uint tweet_remove_timeout = 0;
  [GtkChild]
  private TweetListBox tweet_list;
  [GtkChild]
  private MaxSizeContainer max_size_container;
  [GtkChild]
  private Gtk.MenuButton delete_button;
  [GtkChild]
  private Gtk.Button edit_button;
  [GtkChild]
  private Gtk.Label description_label;
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
  private Gtk.Label creator_label;
  [GtkChild]
  private Gtk.Label subscribers_label;
  [GtkChild]
  private Gtk.Label members_label;
  [GtkChild]
  private Gtk.Label created_at_label;
  [GtkChild]
  private Gtk.Stack name_stack;
  [GtkChild]
  private Gtk.Entry name_entry;
  [GtkChild]
  private Gtk.Stack description_stack;
  [GtkChild]
  private Gtk.Entry description_entry;
  [GtkChild]
  private Gtk.Stack delete_stack;
  [GtkChild]
  private Gtk.Button cancel_button;
  [GtkChild]
  private Gtk.Stack edit_stack;
  [GtkChild]
  private Gtk.Button save_button;
  [GtkChild]
  private Gtk.Stack mode_stack;
  [GtkChild]
  private Gtk.Label mode_label;
  [GtkChild]
  private Gtk.ComboBoxText mode_combo_box;
  [GtkChild]
  private Gtk.Button refresh_button;
  private bool loading = false;


  public ListStatusesPage (int id, Account account, DeltaUpdater delta_updater) {
    this.id = id;
    this.account = account;
    this.tweet_list.account = account;
    this.tweet_list.delta_updater = delta_updater;
    this.scroll_event.connect (scroll_event_cb);
    this.scrolled_to_end.connect (load_older);
    this.scrolled_to_start.connect (handle_scrolled_to_start);
    tweet_list.set_adjustment (this.get_vadjustment ());
  }

  private bool scroll_event_cb (Gdk.EventScroll evt) {
    if (evt.delta_y < 0 && this.vadjustment.value == 0) {
      int inc = (int)(vadjustment.step_increment * (-evt.delta_y));
      max_size_container.max_size += inc;
      return Gdk.EVENT_STOP;
    }
    return Gdk.EVENT_PROPAGATE;
  }

  /**
   * va_list params:
   *  - int64 list_id - The id of the list to show
   *  - string name - The lists's name
   *  - bool user_list - true if the list belongs to the user, false otherwise
   *  - string description - the lists's description
   *  - string creator
   *  - int subscribers_count
   *  - int memebers_count
   *  - int64 created_at
   *  - string mode
   */
  public void on_join (int page_id, Bundle? args) {
    int64 list_id = args.get_int64 ("list_id");
    if (list_id == 0) {
      list_id = this.list_id;
      return;
      // Continue
    }

    string? list_name = args.get_string ("name");
    if (list_name != null) {
      bool user_list = args.get_bool ("user_list", false);
      string description = args.get_string ("description");
      string creator = args.get_string ("creator");
      int n_subscribers = args.get_int ("n_subscribers");
      int n_members = args.get_int ("n_members");
      int64 created_at = args.get_int64 ("created_at");
      string mode = args.get_string ("mode");

      delete_button.sensitive = user_list;
      edit_button.sensitive = user_list;

      name_label.label = list_name;
      description_label.label = description;
      creator_label.label = creator;
      members_label.label = "%'d".printf (n_members);
      subscribers_label.label = "%'d".printf (n_subscribers);
      created_at_label.label = new GLib.DateTime.from_unix_local (created_at).format ("%x, %X");
      mode_label.label = Utils.capitalize (mode);
    }

    debug (@"Showing list with id $list_id");
    if (list_id == this.list_id) {
      this.list_id = list_id;
      load_newer.begin ();
    } else {
      max_size_container.max_size = 0;
      this.list_id = list_id;
      tweet_list.model.clear ();
      load_newest.begin ();
    }

  }

  public void on_leave () {}

  private async void load_newest () {
    loading = true;
    tweet_list.set_unempty ();
    uint requested_tweet_count = 25;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/statuses.json");
    call.set_method ("GET");
    debug ("USING LIST ID %s", list_id.to_string ());
    call.add_param ("list_id", list_id.to_string ());
    call.add_param ("count", requested_tweet_count.to_string ());

    Json.Node? root = null;
    try {
      root = yield TweetUtils.load_threaded (call, null);
    } catch (GLib.Error e) {
      if (e.message.down () == "not found") {
        tweet_list.set_empty ();
      }
      warning (e.message);
      loading = false;
      return;
    }

    var root_array = root.get_array ();
    if (root_array.get_length () == 0) {
      tweet_list.set_empty ();
      loading = false;
      return;
    }
    yield TweetUtils.work_array (root_array,
                                 tweet_list,
                                 account);

    loading = false;
  }

  private async void load_older () {
    if (loading)
      return;

    loading = true;
    uint requested_tweet_count = 25;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/statuses.json");
    call.set_method ("GET");
    call.add_param ("list_id", list_id.to_string ());
    call.add_param ("max_id", (tweet_list.model.lowest_id -1).to_string ());
    call.add_param ("count", requested_tweet_count.to_string ());

    Json.Node? root = null;
    try {
      root = yield TweetUtils.load_threaded (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }

    var root_array = root.get_array ();
    yield TweetUtils.work_array (root_array,
                                 tweet_list,
                                 account);
    loading = false;
  }

  [GtkCallback]
  private void edit_button_clicked_cb () {
    name_stack.visible_child = name_entry;
    description_stack.visible_child = description_entry;
    delete_stack.visible_child = cancel_button;
    edit_stack.visible_child = save_button;
    mode_stack.visible_child = mode_combo_box;

    name_entry.text = real_list_name ();
    description_entry.text = description_label.label;
    mode_combo_box.active_id = mode_label.label;
  }

  [GtkCallback]
  private void cancel_button_clicked_cb () {
    name_stack.visible_child = name_label;
    description_stack.visible_child = description_label;
    delete_stack.visible_child = delete_button;
    edit_stack.visible_child = edit_button;
    mode_stack.visible_child = mode_label;
  }

  [GtkCallback]
  private void save_button_clicked_cb () {
    // Make everything go back to normal
    name_label.label = "@%s/%s".printf(creator_label.label, name_entry.get_text ());
    description_label.label = description_entry.text;
    mode_label.label = mode_combo_box.active_id;
    cancel_button_clicked_cb ();
    edit_button.sensitive = false;
    delete_button.sensitive = false;
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/update.json");
    call.set_method ("POST");
    call.add_param ("list_id", list_id.to_string ());
    call.add_param ("name", real_list_name ());
    call.add_param ("mode", mode_label.label.down ());
    call.add_param ("description", description_label.label);

    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE, this.main_window);
      }
      edit_button.sensitive = true;
      delete_button.sensitive = true;
    });
  }

  private string real_list_name () {
    string cur_name = name_label.label;
    int slash_index = cur_name.index_of ("/");
    return cur_name.substring (slash_index + 1);
  }

  [GtkCallback]
  private void delete_confirmation_item_clicked_cb () {
    var call = account.proxy.new_call ();
    call.set_function("1.1/lists/destroy.json");
    call.add_param ("list_id", list_id.to_string ());
    call.set_method ("POST");
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE, this.main_window);
      }
    });
    // Go back to the ListsPage and tell it to remove this list
    var bundle = new Bundle ();
    bundle.put_int ("mode", ListsPage.MODE_DELETE);
    bundle.put_int64 ("list_id", list_id);
    main_window.main_widget.switch_page (Page.LISTS, bundle);
  }

  [GtkCallback]
  private void refresh_button_clicked_cb () {
    refresh_button.sensitive = false;
    load_newer.begin (() => {
      refresh_button.sensitive = true;
    });
  }

  [GtkCallback]
  private void tweet_activated_cb (Gtk.ListBoxRow row) {
    if (row is TweetListEntry) {
      var bundle = new Bundle ();
      bundle.put_int ("mode", TweetInfoPage.BY_INSTANCE);
      bundle.put_object ("tweet", ((TweetListEntry)row).tweet);
      main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
    } else
      warning ("row is of unknown type");
  }

  private async void load_newer () {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/statuses.json");
    call.set_method ("GET");
    call.add_param ("list_id", list_id.to_string ());
    call.add_param ("count", "30");
    int64 since_id = tweet_list.model.greatest_id;
    if (since_id < 0)
      since_id = 1;

    call.add_param ("since_id", since_id.to_string ());
    debug ("Getting statuses since %s for list_id %s",
           since_id.to_string (), list_id.to_string ());

    Json.Node? root = null;
    try {
      root = yield TweetUtils.load_threaded (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }

    var root_array = root.get_array ();
    if (root_array.get_length () > 0) {
      yield TweetUtils.work_array (root_array,
                                   tweet_list,
                                   account);
    }
  }

  protected void handle_scrolled_to_start() {
    if (tweet_remove_timeout != 0)
      return;

    if (tweet_list.model.get_n_items () > DefaultTimeline.REST) {
      tweet_remove_timeout = GLib.Timeout.add (500, () => {
        if (!scrolled_up) {
          tweet_remove_timeout = 0;
          return false;
        }

        tweet_list.model.remove_last_n_visible (tweet_list.model.get_n_items () - DefaultTimeline.REST);
        tweet_remove_timeout = 0;
        return GLib.Source.REMOVE;
      });
    } else if (tweet_remove_timeout != 0) {
      GLib.Source.remove (tweet_remove_timeout);
      tweet_remove_timeout = 0;
    }
  }

  public string get_title () {
    return _("List");
  }

  public void create_radio_button (Gtk.RadioButton? group) {}
  public Gtk.RadioButton? get_radio_button () {return null;}
}
