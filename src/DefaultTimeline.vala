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

public abstract class DefaultTimeline : Cb.ScrollWidget, IPage {
  public const int REST = 25;
  protected bool initialized = false;
  public int id                          { get; set; }
  private int _unread_count = 0;
  public int unread_count {
    set {
      debug ("Unread count for %s from %d to %d", get_title (), _unread_count, value);
      _unread_count = int.max (value, 0);
      debug ("New unread count for %s: %d", this.get_title (), value);
      radio_button.show_badge = (_unread_count > 0);
    }
    get {
      return this._unread_count;
    }
  }
  protected unowned Cb.MainWindow _main_window;
  public unowned Cb.MainWindow main_window {
    set {
      _main_window = value;
    }
  }
#if EXPERIMENTAL_LISTBOX
  public ModelListBox tweet_list = new ModelListBox ();
#else
  public Cb.TweetListBox tweet_list = new Cb.TweetListBox ();
#endif
  public unowned Account account;
  protected Cb.BadgeRadioButton radio_button;
  protected uint tweet_remove_timeout = 0;
  protected abstract string function     { get;      }
  protected bool loading = false;
  protected Gtk.Widget? last_focus_widget = null;
  private double last_value = 0.0;


  public override GLib.Menu? get_menu () {
    var menu = new GLib.Menu ();
    var item = new GLib.MenuItem ("Split off", "page.split");
    menu.append_item (item);

    return menu;
  }

  protected DefaultTimeline (int id) {
    this.id = id;
    this.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
    this.scrolled_to_start.connect (handle_scrolled_to_start);
    this.scrolled_to_end.connect (() => {
      if (!loading) {
        load_older ();
      }
    });
    this.get_vadjustment ().notify["value"].connect (() => {
      mark_seen_on_scroll (this.get_vadjustment ().value);
    });

    this.add (tweet_list);

    tweet_list.get_widget ().row_activated.connect ((row) => {
      if (row is Cb.TweetRow || row is Cb.TweetRow) {
        var bundle = new Cb.Bundle ();
        bundle.put_int (TweetInfoPage.KEY_MODE, TweetInfoPage.BY_INSTANCE);
        if (row is Cb.TweetRow)
          bundle.put_object (TweetInfoPage.KEY_TWEET, ((Cb.TweetRow)row).tweet);
        else
          bundle.put_object (TweetInfoPage.KEY_TWEET, ((Cb.TweetRow)row).tweet);

        _main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
      }
      last_focus_widget = row;
    });
    tweet_list.retry_button_clicked.connect (() => {
      tweet_list.model.clear ();
      this.load_newest ();
    });

    this.hexpand = true;
  }

  public virtual void on_join (int page_id, Cb.Bundle? args) {
    if (STRESSTEST)
      return;

    if (!initialized) {
      load_newest ();

      if (!Settings.auto_scroll_on_new_tweets ()) {
        /* we are technically not scrolling up, but due to missing content,
           we can't really not be scrolled up...
         */
        mark_seen (-1);
      }

      account.user_stream.resumed.connect (stream_resumed_cb);
      initialized = true;
    }

    if (Settings.auto_scroll_on_new_tweets ()) {
      mark_seen (-1);
    }

#if !EXPERIMENTAL_LISTBOX
    if (last_focus_widget != null) {
      /* We might have a reference to a row that's been removed
         from the listbox */
      if (last_focus_widget.parent == tweet_list.get_widget ())
        last_focus_widget.grab_focus ();
      else
        last_focus_widget = null;
    }
#endif

    this.get_vadjustment ().value = this.last_value;
  }

  public virtual void on_leave () {
    this.last_focus_widget = _main_window.get_focus ();

    if (tweet_list.action_entry != null && tweet_list.action_entry.shows_actions ())
      tweet_list.action_entry.toggle_mode ();

    last_value = this.get_vadjustment ().value;
  }

  public bool handles_double_open () {
    return true;
  }

  public void double_open () {
    if (!loading) {
      this.scroll_up_next (true, true);
      tweet_list.get_widget ().get_row_at_index (0).grab_focus ();
    }
  }

  public void load_newest () {
    this.loading = true;
    this.load_newest_internal.begin (() => {
      this.loading = false;
    });
  }

  public void load_older () {
    if (!initialized)
      return;

    this.balance_next_upper_change (BOTTOM);
    this.loading = true;
    this.load_older_internal.begin (() => {
      this.loading = false;
    });
  }

  public abstract string get_title ();

  public override void dispose () {
    if (tweet_remove_timeout > 0) {
      GLib.Source.remove (tweet_remove_timeout);
      tweet_remove_timeout = 0;
    }

    base.dispose ();
  }

  public virtual void create_radio_button(Gtk.ToggleButton? group){}

  public Cb.BadgeRadioButton? get_radio_button() {
    return radio_button;
  }

  /**
   * Handle the case of the user scrolling to the start of the list,
   * i.e. remove all the items except a few ones after a timeout.
   */
  protected void handle_scrolled_to_start() {
    if (tweet_remove_timeout != 0)
      return;

    if (tweet_list.model.get_n_items () > DefaultTimeline.REST) {
      tweet_remove_timeout = GLib.Timeout.add (500, () => {
        if (!scrolled_up ()) {
          tweet_remove_timeout = 0;
          return GLib.Source.REMOVE;
        }

        /* Check again in case this changed in the last 500ms */
        if (tweet_list.model.get_n_items () > DefaultTimeline.REST) {
          tweet_list.model.remove_last_n_visible (tweet_list.model.get_n_items () - DefaultTimeline.REST);
        }
        tweet_remove_timeout = 0;
        return GLib.Source.REMOVE;
      });
    } else if (tweet_remove_timeout != 0) {
      GLib.Source.remove (tweet_remove_timeout);
      tweet_remove_timeout = 0;
    }
  }

  public void delete_tweet (int64 tweet_id) {
    bool was_seen;
    bool removed = this.tweet_list.model.delete_id (tweet_id, out was_seen);

    if (removed && !was_seen)
      this.unread_count --;
  }

  public void toggle_favorite (int64 id, bool mode) {

    Cb.Tweet? t = this.tweet_list.model.get_for_id (id, 0);
    if (t != null) {
      if (mode)
        this.tweet_list.model.set_tweet_flag (t, Cb.TweetState.FAVORITED);
      else
        this.tweet_list.model.unset_tweet_flag (t, Cb.TweetState.FAVORITED);
    }
  }


  /**
   * So, we don't want to display a retweet in the following situations:
   *   1) If the original tweet was a tweet by the authenticated user
   *   2) In any case, if the user follows the author of the tweet
   *      (not the author of the retweet!), we already get the source
   *      tweet by other means, so don't display it again.
   *   3) It's a retweet from the authenticating user itself
   *   4) If the tweet was retweeted by a user that is on the list of
   *      users the authenticating user disabled RTs for.
   *   5) If the retweet is already in the timeline. There's no other
   *      way of checking the case where 2 independend users retweet
   *      the same tweet.
   */
  protected Cb.TweetState get_rt_flags (Cb.Tweet t) {
    uint flags = 0;

    /* First case */
    if (t.get_user_id () == account.id)
      flags |= Cb.TweetState.HIDDEN_FORCE;

    /*  Second case */
    if (account.follows_id (t.get_user_id ()))
        flags |= Cb.TweetState.HIDDEN_RT_BY_FOLLOWEE;

    /* third case */
    if (t.retweeted_tweet != null &&
        t.retweeted_tweet.author.id == account.id)
      flags |= Cb.TweetState.HIDDEN_FORCE;

    /* Fourth case */
    foreach (int64 id in account.disabled_rts) {
      if (id == t.source_tweet.author.id) {
        flags |= Cb.TweetState.HIDDEN_RTS_DISABLED;
        break;
      }
    }

    /* Fifth case */
    if (t.retweeted_tweet != null) {
      if (tweet_list.model.contains_rt_id (t.retweeted_tweet.id)) {
        flags |= Cb.TweetState.HIDDEN_FORCE;
      }
    }

    return (Cb.TweetState)flags;
  }

  protected void mark_seen (int64 id) {
#if !EXPERIMENTAL_LISTBOX
    //foreach (Gtk.Widget w in tweet_list.get_widget ().get_children ()) {
      //if (w == null || !(w is Cb.TweetRow))
        //continue;

      //var tle = (Cb.TweetRow) w;
      //if (tle.tweet.id == id || id == -1) {
        //if (!tle.tweet.get_seen ()) {
          //this.unread_count--;
        //}
        //tle.tweet.set_seen (true);
        //if (id != -1)
          //break;
      //}
    //}
#endif
  }


  protected bool scroll_up (Cb.Tweet t) {
    bool auto_scroll = Settings.auto_scroll_on_new_tweets ();
    if (this.scrolled_up () && (t.get_user_id () == account.id || auto_scroll)) {
      this.scroll_up_next (true,
                           _main_window.get_cur_page_id () != this.id);
      return true;
    }

    return false;
  }

  private void stream_resumed_cb () {
    if (this.tweet_list.model.get_n_items () == 0)
      return;

    var call = account.proxy.new_call ();
    call.set_function (this.function);
    call.set_method ("GET");
    call.add_param ("count", "1");
    call.add_param ("since_id", (this.tweet_list.model.max_id + 1).to_string ());
    call.add_param ("trim_user", "true");
    call.add_param ("contributor_details", "false");
    call.add_param ("include_entities", "false");
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        tweet_list.model.clear ();
        load_newest ();
        warning (e.message);
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        tweet_list.model.clear ();
        this.unread_count = 0;
        warning (e.message);
        load_newest ();
        return;
      }

      var root_arr = parser.get_root ().get_array ();
      if (root_arr.get_length () > 0) {
        this.tweet_list.model.clear ();
        this.unread_count = 0;
        this.load_newest ();
      }

    });
  }

  /**
   * Default implementation for loading the newest tweets
   * from the given function of the twitter api.
   */
  protected async void load_newest_internal () {
    int requested_tweet_count = 28;
    var call = account.proxy.new_call ();
    call.set_function (this.function);
    call.set_method("GET");
    call.add_header ("Authorization", "Bearer " + ((Rest.OAuth2Proxy)account.proxy).get_access_token ());
    call.add_param ("limit", requested_tweet_count.to_string ());
    call.add_param ("max_id", (tweet_list.model.min_id - 1).to_string ());

    Json.Node? root_node = null;
    try {
      root_node = yield Cb.Utils.load_threaded_async (call, null);
    } catch (GLib.Error e) {
      message (e.message);
      tweet_list.set_error ("%s\n%s".printf (_("Could not load tweets"), e.message));
      return;
    }

    assert (root_node != null);

    var root = root_node.get_array();
    if (root.get_length () == 0) {
      tweet_list.set_empty ();
      return;
    }

#if EXPERIMENTAL_LISTBOX
    TweetUtils.work_array2 (root,
                            tweet_list,
                            account);
#else
    TweetUtils.work_array (root,
                           tweet_list,
                           account);
#endif
  }

  /**
   * Default implementation to load older tweets.
   *
   */
  protected async void load_older_internal () {
    int requested_tweet_count = 28;
    var call = account.proxy.new_call ();
    call.set_function (this.function);
    call.set_method ("GET");
    call.add_header ("Authorization", "Bearer " + ((Rest.OAuth2Proxy)account.proxy).get_access_token ());
    call.add_param ("count", requested_tweet_count.to_string ());
    call.add_param ("max_id", (tweet_list.model.min_id - 1).to_string ());

    Json.Node? root_node = null;

    try {
      root_node = yield Cb.Utils.load_threaded_async (call, null);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }

    var root = root_node.get_array ();
    if (root.get_length () == 0) {
      tweet_list.set_empty ();
      return;
    }

#if EXPERIMENTAL_LISTBOX
    TweetUtils.work_array2 (root,
                            tweet_list,
                            account);
#else
    TweetUtils.work_array (root,
                           tweet_list,
                           account);
#endif
  }

  /**
   * Mark the TweetListEntries the user has already seen.
   *
   * @param value The scrolling value as from Gtk.Adjustment
   */
  protected void mark_seen_on_scroll (double value) {
    if (unread_count == 0)
      return;

    // We HAVE to use widgets here.
#if !EXPERIMENTAL_LISTBOX
    //tweet_list.get_widget ().forall ((w) => {
      //if (!(w is Cb.TweetRow))
        //return;

      //var tle = (Cb.TweetRow)w;
      //if (tle.tweet.get_seen ())
        //return;

      //Gtk.Allocation alloc;
      //tle.get_allocation (out alloc);
      //if (alloc.y + (alloc.height / 2.0) >= value) {
        //tle.tweet.set_seen (true);
        //unread_count--;
      //}
    //});
#endif
  }

  public void rerun_filters () {
    Cb.TweetModel tm = tweet_list.model;

    for (uint i = 0; i < tm.get_n_items (); i ++) {
      var tweet = (Cb.Tweet) tm.get_object (i);
      if (account.filter_matches (tweet)) {
        if (tm.set_tweet_flag (tweet, Cb.TweetState.HIDDEN_FILTERED))
          i --;

        if (!tweet.get_seen ()) {
          this.unread_count --;
          tweet.set_seen (true);
        }
      } else {
        if (tm.unset_tweet_flag (tweet, Cb.TweetState.HIDDEN_FILTERED)) {
          i --;
        }
      }

    }

    // Same thing for invisible tweets...
    for (uint i = 0; i < tm.hidden_tweets.length; i ++) {
      var tweet =  tm.hidden_tweets.get (i);
      if (tweet.is_flag_set (Cb.TweetState.HIDDEN_FILTERED)) {
        if (!account.filter_matches (tweet)) {
          tm.unset_tweet_flag (tweet, Cb.TweetState.HIDDEN_FILTERED);
          i --;
        }
      }
    }
  }

}
