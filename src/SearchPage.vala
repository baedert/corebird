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

[GtkTemplate (ui = "/org/baedert/corebird/ui/search-page.ui")]
class SearchPage : IPage, Gtk.Box {
  private static const int USER_COUNT = 3;
  /** The unread count here is always zero */
  public int unread_count {
    get { return 0; }
  }
  public unowned Account account;
  public int id                         { get; set; }
  private unowned MainWindow main_window;
  public unowned MainWindow window {
    set {
      main_window = value;
    }
  }

  [GtkChild]
  private Gtk.SearchEntry search_entry;
  [GtkChild]
  private Gtk.Button search_button;
  [GtkChild]
  private TweetListBox tweet_list;
  [GtkChild]
  private Gtk.Label users_header;
  [GtkChild]
  private Gtk.Label tweets_header;
  [GtkChild]
  private ScrollWidget scroll_widget;
  private Gtk.RadioButton radio_button;
  public DeltaUpdater delta_updater;
  private GLib.Cancellable? cancellable = null;
  private LoadMoreEntry load_more_entry = new LoadMoreEntry ();
  private string search_query;
  private int user_page = 1;
  private int64 lowest_tweet_id = int64.MAX-1;
  private Gtk.Widget last_focus_widget;
  private int n_results = 0;
  private Collect collect_obj;
  private uint remove_content_timeout = 0;
  private string last_search_query;


  public SearchPage (int id, Account account, DeltaUpdater delta_updater) {
    this.id = id;
    this.account = account;
    this.delta_updater = delta_updater;

    /* We are slightly abusing the TweetListBox here */
    tweet_list.bind_model (null, null);
    tweet_list.set_header_func (header_func);
    tweet_list.set_sort_func (ITwitterItem.sort_func);
    tweet_list.row_activated.connect (row_activated_cb);
    tweet_list.retry_button_clicked.connect (retry_button_clicked_cb);
    search_button.clicked.connect (() => {
      search_for (search_entry.get_text());
    });
    load_more_entry.get_button ().clicked.connect (() => {
      user_page++;
      load_users ();
    });
    scroll_widget.scrolled_to_end.connect (load_tweets);
    tweet_list.get_placeholder ().hide ();
    tweet_list.set_adjustment (scroll_widget.get_vadjustment ());
  }

  [GtkCallback]
  private void search_entry_activate_cb () {
    search_for (search_entry.get_text ());
  }

  private void retry_button_clicked_cb () {
    search_for (last_search_query);
  }

  /**
   * see IPage#onJoin
   */
  public void on_join (int page_id, Bundle? args) {
    string? term = args != null ? args.get_string ("query") : null;

    if (this.remove_content_timeout != 0) {
      GLib.Source.remove (this.remove_content_timeout);
      this.remove_content_timeout = 0;
    }


    if (term == null) {
      if (last_focus_widget != null &&
          last_focus_widget.parent != null)
        last_focus_widget.grab_focus ();
      else
        search_entry.grab_focus ();
      return;
    }

    search_for (term, true);
  }

  public void on_leave () {
    this.remove_content_timeout = GLib.Timeout.add (3 * 1000 * 60, () => {
      tweet_list.remove_all ();
      tweet_list.get_placeholder ().hide ();
      this.last_focus_widget  = null;

      this.remove_content_timeout = 0;
      return GLib.Source.REMOVE;
    });
  }

  public void search_for (string search_term, bool set_text = false) { //{{{
    if(search_term.length == 0)
      return;

    this.last_search_query = search_term;

    if (this.cancellable != null) {
      debug ("Cancelling earlier search...");
      this.cancellable.cancel ();
    }

    this.cancellable = new GLib.Cancellable ();

    n_results = 0;
    string q = search_term;

    // clear the list
    tweet_list.remove_all ();
    tweet_list.set_unempty ();
    tweet_list.get_placeholder ().show ();


    if (set_text)
      search_entry.set_text(search_term);

    q += " -rt";

    this.search_query    = GLib.Uri.escape_string (q);
    this.user_page       = 1;
    this.lowest_tweet_id = int64.MAX-1;

    collect_obj = new Collect (2);
    collect_obj.finished.connect (show_entries);

    load_tweets ();
    load_users ();
  } //}}}

  private void row_activated_cb (Gtk.ListBoxRow row) {
    this.last_focus_widget = row;
    var bundle = new Bundle ();
    if (row is UserListEntry) {
      bundle.put_int64 ("user_id", ((UserListEntry)row).user_id);
      bundle.put_string ("screen_name", ((UserListEntry)row).screen_name);
      main_window.main_widget.switch_page (Page.PROFILE, bundle);
    } else if (row is TweetListEntry) {
      bundle.put_int ("mode", TweetInfoPage.BY_INSTANCE);
      bundle.put_object ("tweet", ((TweetListEntry)row).tweet);
      main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
    }
  }

  private void header_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) { //{{{
    Gtk.Widget header = row.get_header ();
    if (header != null)
      return;

    if (before == null && row is UserListEntry) {
      row.set_header (users_header);
    } else if ((before is UserListEntry || before is LoadMoreEntry) && row is TweetListEntry) {
      row.set_header (tweets_header);
    }
  } //}}}

  private void load_users () {
    var user_call = account.proxy.new_call ();
    user_call.set_method ("GET");
    user_call.set_function ("1.1/users/search.json");
    user_call.add_param ("q", this.search_query);
    user_call.add_param ("count", (USER_COUNT + 1).to_string ());
    user_call.add_param ("include_entities", "false");
    user_call.add_param ("page", user_page.to_string ());
    TweetUtils.load_threaded.begin (user_call, cancellable, (_, res) => {
      Json.Node? root = null;
      try {
        root = TweetUtils.load_threaded.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        tweet_list.set_error (e.message);

        if (!collect_obj.done)
          collect_obj.emit ();

        return;
      }

      if (root == null) {
        debug ("load_users: root is null");
        return;
      }

      var users = root.get_array ();
      if (users.get_length () == 0 && n_results <= 0)
        n_results = -1;
      else
        n_results += (int)users.get_length ();

      if (n_results <= 0) {
        tweet_list.set_empty ();
      }

      users.foreach_element ((array, index, node) => {
        if (index > USER_COUNT - 1)
          return;

        var user_obj = node.get_object ();
        var entry = new UserListEntry ();
        string avatar_url = user_obj.get_string_member ("profile_image_url");

        if (this.get_scale_factor () == 2)
          avatar_url = avatar_url.replace ("_normal", "_bigger");

        entry.user_id = user_obj.get_int_member ("id");
        entry.screen_name = "@" + user_obj.get_string_member ("screen_name");
        entry.name = user_obj.get_string_member ("name").strip ();
        entry.avatar_url = avatar_url;
        entry.show_settings = false;
        if (!collect_obj.done)
          entry.visible = false;
        tweet_list.add (entry);
      });
      if (users.get_length () > USER_COUNT) {
        if (load_more_entry.parent == null) {
          load_more_entry.visible = false;
          tweet_list.add (load_more_entry);
        }
      } else {
        load_more_entry.hide ();
      }

      if (!collect_obj.done)
        collect_obj.emit ();
    });

  }

  private void load_tweets () {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/search/tweets.json");
    call.set_method ("GET");
    call.add_param ("q", this.search_query);
    call.add_param ("max_id", (lowest_tweet_id - 1).to_string ());
    call.add_param ("count", "35");
    TweetUtils.load_threaded.begin (call, cancellable, (_, res) => {
      Json.Node? root = null;
      try {
        root = TweetUtils.load_threaded.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        tweet_list.set_error (e.message);
        if (!collect_obj.done)
          collect_obj.emit ();

        return;
      }

      if (root == null) {
        debug ("load tweets: root is null");
        return;
      }

      var now = new GLib.DateTime.now_local ();
      var statuses = root.get_object().get_array_member("statuses");
      if (statuses.get_length () == 0 && n_results <= 0)
        n_results = -1;
      else
        n_results += (int)statuses.get_length ();

      if (n_results <= 0)
        tweet_list.set_empty ();

      statuses.foreach_element ((array, index, node) => {
        var tweet = new Tweet ();
        tweet.load_from_json (node, now, account);
        if (tweet.id < lowest_tweet_id)
          lowest_tweet_id = tweet.id;
        var entry = new TweetListEntry (tweet, main_window, account);
        delta_updater.add (entry);
        if (!collect_obj.done)
          entry.visible = false;
        else
          entry.show ();

        tweet_list.add (entry);
      });

      if (!collect_obj.done)
        collect_obj.emit ();
    });

  }

  private void show_entries (GLib.Error? e) {
    if (e != null) {
      tweet_list.set_error (e.message);
      tweet_list.set_empty ();
      return;
    }

    tweet_list.@foreach ((w) => w.show());
  }

  public void create_radio_button (Gtk.RadioButton? group){
    radio_button = new BadgeRadioButton (group, "edit-find-symbolic", _("Search"));
  }

  public Gtk.RadioButton? get_radio_button() {
    return radio_button;
  }


  public string get_title () {
    return _("Search");
  }

  public bool handles_double_open () {
    return true;
  }
}

[GtkTemplate (ui = "/org/baedert/corebird/ui/load-more-entry.ui")]
class LoadMoreEntry : Gtk.ListBoxRow, ITwitterItem {
  public int64 sort_factor {
    get { return int64.MAX-2; }
  }
  public bool seen {
    get { return true; }
    set {}
  }
  [GtkChild]
  private Gtk.Button load_more_button;

  public LoadMoreEntry () {
    this.activatable = false;
  }
  public Gtk.Button get_button () {
    return load_more_button;
  }
  public int update_time_delta (GLib.DateTime? now = null) {return 0;}
}
