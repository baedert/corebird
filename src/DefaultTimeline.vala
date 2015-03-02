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

public abstract class DefaultTimeline : ScrollWidget, IPage, ITimeline {
  protected bool initialized = false;
  public int id                          { get; set; }
  public int unread_count                { get; set; }
  public unowned MainWindow main_window  { set; get; }
  protected TweetListBox tweet_list      { set; get; default=new TweetListBox ();}
  public unowned Account account         { get; set; }
  protected BadgeRadioToolButton tool_button;
  public int64 lowest_id                 { get; set; default = int64.MAX-2; }
  protected uint tweet_remove_timeout    { get; set; }
  protected int64 max_id                 { get; set; default = 0; }
  public DeltaUpdater delta_updater      { get; set; }
  protected abstract string function     { get;      }
  protected bool loading = false;
  protected Gtk.Widget? last_focus_widget = null;


  public DefaultTimeline (int id) {
    this.id = id;
    this.vscrollbar_policy = Gtk.PolicyType.ALWAYS;
    this.scrolled_to_start.connect(handle_scrolled_to_start);
    this.scrolled_to_end.connect(() => {
      if (!loading) {
        load_older ();
      }
    });
    this.vadjustment.notify["value"].connect (() => {
      mark_seen_on_scroll (vadjustment.value);
      update_unread_count ();
    });


    tweet_list.set_sort_func(ITwitterItem.sort_func);
    this.add (tweet_list);

    tweet_list.row_activated.connect ((row) => {
      if (row is TweetListEntry) {
        var bundle = new Bundle ();
        bundle.put_int ("mode", TweetInfoPage.BY_INSTANCE);
        bundle.put_object ("tweet", ((TweetListEntry)row).tweet);
        main_window.main_widget.switch_page (Page.TWEET_INFO, bundle);
      }
      last_focus_widget = row;
    });
    tweet_list.retry_button_clicked.connect (() => {
      tweet_list.remove_all ();
      this.load_newest ();
    });

  }

  public virtual void on_join (int page_id, Bundle? args) {
    if (!initialized) {
      load_cached ();
      load_newest ();
      account.user_stream.resumed.connect (stream_resumed_cb);
      initialized = true;
    }

    if (Settings.auto_scroll_on_new_tweets ()) {
      this.unread_count = 0;
      mark_seen (-1);
      update_unread_count ();
    }

    if (last_focus_widget != null) {
      last_focus_widget.grab_focus ();
    }
  }


  public bool handles_double_open () {
    return true;
  }

  public void double_open () {
    if (!loading) {
      this.scroll_up_next (true, false, true);
      tweet_list.get_row_at_index (0).grab_focus ();
    }
  }

  public virtual void on_leave () {
    Gtk.Widget? focus_widget = main_window.get_focus ();
    if (focus_widget == null)
      return;

    GLib.List<weak Gtk.Widget> list_rows = tweet_list.get_children ();
    foreach (Gtk.Widget w in list_rows) {
      if (w == focus_widget) {
        last_focus_widget = w;
        break;
      }
    }

    if (tweet_list.action_entry != null && tweet_list.action_entry.shows_actions)
      tweet_list.action_entry.toggle_mode ();
  }

  public virtual void load_cached () {}
  public abstract void load_newest ();
  public abstract void load_older ();
  public abstract string? get_title ();

  public override void destroy () {
    if (tweet_remove_timeout > 0)
      GLib.Source.remove (tweet_remove_timeout);
  }

  public virtual void create_tool_button(Gtk.RadioButton? group){}

  public Gtk.RadioButton? get_tool_button() {
    return tool_button;
  }


  protected void update_unread_count() {
    tool_button.show_badge = (unread_count > 0);
    tool_button.queue_draw();
  }
  /**
   * Handle the case of the user scrolling to the start of the list,
   * i.e. remove all the items except a few ones after a timeout.
   */
  protected void handle_scrolled_to_start() { // {{{
    if (tweet_remove_timeout != 0)
      return;

    GLib.List<weak Gtk.Widget> entries = tweet_list.get_children ();
    uint item_count = entries.length ();
    if (item_count > ITimeline.REST) {
      tweet_remove_timeout = GLib.Timeout.add (5000, () => {
        if (!scrolled_up) {
          tweet_remove_timeout = 0;
          return false;
        }

        while (item_count > ITimeline.REST) {
          Gtk.Widget? w = tweet_list.get_row_at_index (ITimeline.REST);
          if (w == null || w.visible)
            item_count --;

          if (w != null)
            tweet_list.remove (w);
        }
        tweet_remove_timeout = 0;
        lowest_id = ((TweetListEntry)tweet_list.get_row_at_index (ITimeline.REST -1)).tweet.id;
        return false;
      });
    } else if (tweet_remove_timeout != 0) {
      GLib.Source.remove (tweet_remove_timeout);
      tweet_remove_timeout = 0;
    }
  } // }}}

  public void delete_tweet (int64 tweet_id) { // {{{
    foreach (Gtk.Widget w in tweet_list.get_children ()) {
      if (w == null || !(w is TweetListEntry))
        continue;

      var tle = (TweetListEntry) w;
      if (tle.tweet.id == tweet_id) {
        if (!tle.seen) {
          tweet_list.remove (tle);
          unread_count --;
          update_unread_count ();
        }else
          tle.sensitive = false;
        return;
      } else if (tle.tweet.retweeted && tle.tweet.my_retweet == tweet_id) {
        tle.tweet.retweeted = false;
        return;
      }
    }
  } // }}}

  public void toggle_favorite (int64 id, bool mode) { // {{{
    var tweets = tweet_list.get_children ();

    foreach (var w in tweets) {
      if (!(w is TweetListEntry))
        continue;
      var t = ((TweetListEntry)w).tweet;
      if (t.id == id) {
        t.favorited = mode;
        break;
      }
    }
  } // }}}


  /**
   * So, we don't want to display a retweet in the following situations:
   *   - If the original tweet was a tweet by the authenticated user
   *   - In any case, if the user follows the author of the tweet
   *     (not the author of the retweet!), we already get the source
   *     tweet by other means, so don't display it again.
   *   - It's a retweet from the authenticating user itself
   *   - If the tweet was retweeted by a user that is on the list of
   *     users the authenticating user disabled RTs for.
   *   - If the retweet is already in the timeline. There's no other
   *     way of checking the case where 2 indipendend users retweet
   *     the same tweet.
   */
  protected bool should_display_retweet (Tweet t) {
    /* First case */
    if (t.user_id == account.id)
      return false;

    /*  Second case */
    if (account.follows_id (t.user_id))
        return false;

    /* third case */
    if (t.rt_by_id == account.id)
      return false;

    /* Fourth case */
    foreach (int64 id in account.disabled_rts)
      if (id == t.rt_by_id)
        return false;

    /* Fifth case */
    foreach (Gtk.Widget w in tweet_list.get_children ()) {
      if (w is TweetListEntry) {
        if (((TweetListEntry)w).tweet.rt_id == t.rt_id)
          return false;
      }
    }

    return true;
  }

  protected void mark_seen (int64 id) {
    foreach (Gtk.Widget w in tweet_list.get_children ()) {
      if (w == null || !(w is TweetListEntry))
        continue;

      var tle = (TweetListEntry) w;
      if (tle.tweet.id == id || id == -1) {
        if (!tle.seen) {
          unread_count--;
          update_unread_count ();
        }
        tle.seen = true;
        break;
      }
    }
  }


  protected void scroll_up (Tweet t) {
    bool auto_scroll = Settings.auto_scroll_on_new_tweets ();
    if (this.scrolled_up && (t.user_id == account.id || auto_scroll)) {
      this.scroll_up_next (true, false,
                           main_window.cur_page_id != this.id);
    }

  }

  protected void postprocess_tweet (TweetListEntry tle) {
    var t = tle.tweet;
    if (t.id < lowest_id)
      lowest_id = t.id;
    else if (t.id > max_id)
      max_id = t.id;

    if (!tle.seen && tle.visible) {
      this.unread_count ++;
      this.update_unread_count ();
    }
  }

  private void stream_resumed_cb () {
    // XXX If load_newest failed, the list still gets cleared...
    var call = account.proxy.new_call ();
    call.set_function (this.function);
    call.set_method ("GET");
    call.add_param ("count", "1");
    call.add_param ("since_id", (this.max_id + 1).to_string ());
    call.add_param ("trim_user", "true");
    call.add_param ("contributor_details", "false");
    call.add_param ("include_entities", "false");
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        tweet_list.remove_all ();
        lowest_id = int64.MAX - 2;
        load_newest ();
        warning (e.message);
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        tweet_list.remove_all ();
        lowest_id = int64.MAX - 2;
        load_newest ();
        warning (e.message);
        return;
      }

      var root_arr = parser.get_root ().get_array ();
      if (root_arr.get_length () > 0) {
        tweet_list.remove_all ();
        lowest_id = int64.MAX - 2;
        unread_count = 0;
        update_unread_count ();
        load_newest ();
      }

    });
  }
}
