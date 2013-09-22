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

// TODO: Add timeout that removes all entries after X seconds when switched away
[GtkTemplate (ui = "/org/baedert/corebird/ui/search-page.ui")]
class SearchPage : IPage, Box {
  private static const int TYPE_TWEET = 1;
  private static const int TYPE_USER  = 2;
  private int id;
  /** The unread count here is always zero */
  public int unread_count {
    get { return 0; }
    set {;}
  }
  public unowned Account account        { get; set; }
  public unowned MainWindow main_window { set; get; }
  [GtkChild]
  private SearchEntry search_entry;
  [GtkChild]
  private Button search_button;
  [GtkChild]
  private ListBox tweet_list; // TODO: Rename tweet_list
  [GtkChild]
  private Label users_header;
  [GtkChild]
  private Label tweets_header;
  private RadioToolButton tool_button;
  private DeltaUpdater delta_updater;
  private Gtk.Spinner placeholder = new Gtk.Spinner ();


  public SearchPage (int id) {
    this.id = id;

    tweet_list.set_header_func (header_func);
    placeholder.start ();
    placeholder.show ();
    tweet_list.set_placeholder (placeholder);
    tweet_list.set_sort_func (sort_search_entries);
    tweet_list.row_activated.connect (row_activated_cb);
    search_button.clicked.connect (() => {
      search_for (search_entry.get_text());
    });
    this.button_press_event.connect (button_pressed_event_cb);
  }

  [GtkCallback]
  private void search_entry_activate_cb () {
    search_for (search_entry.get_text ());
  }

  /**
   * see IPage#onJoin
   */
  public void on_join (int page_id, va_list arg_list) {
    string term = arg_list.arg<string>();
    if(term != null)
      search_for (term, true);
  }

  public void on_leave () {}

  public void search_for (string search_term, bool set_text = false) { //{{{
    if(search_term.length == 0)
      return;

    // clear the list
    tweet_list.foreach ((w) => {
      tweet_list.remove (w);
    });


    if (set_text)
      search_entry.set_text(search_term);

    string q = GLib.Uri.escape_string (search_term);

    var call = account.proxy.new_call ();
    call.set_function ("1.1/search/tweets.json");
    call.set_method ("GET");
    call.add_param ("q", q);
    call.invoke_async.begin (null, (obj, res) => {
      try{
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }
      string back = call.get_payload ();
      Json.Parser parser = new Json.Parser ();
      try {
        parser.load_from_data (back);
      } catch (GLib.Error e) {
        critical(" %s\nDATA:\n%s", e.message, back);
      }
      var now = new GLib.DateTime.now_local ();
      var statuses = parser.get_root().get_object().get_array_member("statuses");
      statuses.foreach_element ((array, index, node) => {
        var tweet = new Tweet ();
        tweet.load_from_json (node, now);
        var entry = new TweetListEntry (tweet, main_window, account);
        tweet_list.add (entry);
      });
    });


    var user_call = account.proxy.new_call ();
    user_call.set_method ("GET");
    user_call.set_function ("1.1/users/search.json");
    user_call.add_param ("q", q);
    user_call.add_param ("count", "5");
    user_call.invoke_async.begin (null, (obj, res) => {
      try {
        user_call.invoke_async.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (user_call.get_payload ());
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }

      var users = parser.get_root ().get_array ();
      users.foreach_element ((array, index, node) => {
        var user_obj = node.get_object ();
        var entry = new UserListEntry ();
        entry.screen_name = "@" + user_obj.get_string_member ("screen_name");
        entry.name = user_obj.get_string_member ("name");
        entry.avatar = user_obj.get_string_member ("profile_image_url");
        entry.user_id = user_obj.get_int_member ("id");
        tweet_list.add (entry);
      });
    });
  } //}}}

  private void row_activated_cb (ListBoxRow row) {
    if (row is UserListEntry) {
      main_window.switch_page (MainWindow.PAGE_PROFILE,
                               ((UserListEntry)row).user_id);
    } else if (row is TweetListEntry) {
      main_window.switch_page (MainWindow.PAGE_TWEET_INFO,
                               TweetInfoPage.BY_INSTANCE,
                               ((TweetListEntry)row).tweet);
    }
  }


  private int sort_search_entries (ListBoxRow row1, ListBoxRow row2) {
      return ITwitterItem.sort_func(row1, row2);
  }


  private void header_func (ListBoxRow row, ListBoxRow? before) {
    Widget header = row.get_header ();
    if (header != null)
      return;

    if (before == null && row is UserListEntry) {
      row.set_header (users_header);
    } else if (before is UserListEntry && row is TweetListEntry) {
      row.set_header (tweets_header);
    }
  }




  public void create_tool_button(RadioToolButton? group){
    tool_button = new RadioToolButton.from_widget (group);
    tool_button.icon_name = "corebird-search-symbolic";
    tool_button.label = "Search";
  }

  public RadioToolButton? get_tool_button(){
    return tool_button;
  }

  public int get_id(){
    return id;
  }
}
