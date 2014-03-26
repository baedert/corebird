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

abstract class DefaultTimeline : ScrollWidget, IPage, ITimeline {
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
  public DeltaUpdater delta_updater      { get; set;}
  protected bool loading = false;
  protected Gtk.Widget? last_focus_widget = null;
  protected MissingListEntry missing_entry = new MissingListEntry ();

  public DefaultTimeline (int id) {
    this.id = id;
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

    tweet_list.activate_on_single_click = false;
    tweet_list.row_activated.connect ((row) => {
      if (!(row is TweetListEntry))
        return;
      main_window.switch_page (MainWindow.PAGE_TWEET_INFO,
                               TweetInfoPage.BY_INSTANCE,
                               ((TweetListEntry)row).tweet);
      last_focus_widget = row;
    });

  }

  public virtual void on_join (int page_id, va_list args) {
    if (!initialized) {
      load_cached ();
      load_newest ();
      connect_stream_signals ();
      initialized = true;
    }

    if (Settings.auto_scroll_on_new_tweets ()) {
      this.unread_count = 0;
      update_unread_count ();
    }

    if (last_focus_widget != null) {
      last_focus_widget.grab_focus ();
    }
  }

  private void connect_stream_signals () {
    account.user_stream.interrupted.connect (() => {
      missing_entry.lower_id = max_id;
      missing_entry.timestamp = new GLib.DateTime.now_local ().to_unix ();
      missing_entry.set_interrupted ();
      missing_entry.show_all ();
      tweet_list.add (missing_entry);
    });

    account.user_stream.resumed.connect (() => {
      load_missing_tweets.begin (this.max_id + 1, -1, true, (o, res) => {
        uint count = load_missing_tweets.end (res);
        if (count > 0) {
          missing_entry.set_resumed ();
        } else {
          tweet_list.remove (missing_entry);
        }
      });
    });
    missing_entry.load_clicked.connect (() => {
      tweet_list.remove (missing_entry);
      missing_entry.set_loading ();
      load_missing_tweets.begin (missing_entry.lower_id,
                                 missing_entry.upper_id,
                                 false,
                                 () => {

        missing_entry.set_interrupted (); // reset state
        tweet_list.remove (missing_entry);
        missing_entry.upper_id = -1;
        missing_entry.lower_id = -1;
      });
    });
  }

  private async uint load_missing_tweets (int64 lower_id, int64 upper_id,
                                          bool insert = false) {
    var call = account.proxy.new_call ();
    call.set_method ("GET");
    call.set_function (get_function ());
    call.add_param ("count", "1");
    call.add_param ("contributor_details", "false");
    if (!insert) {
      call.add_param ("trim_user", "true");
      call.add_param ("include_entities", "false");
    }
    if (upper_id != -1)
      call.add_param ("max_id", upper_id.to_string ());
    call.add_param ("since_id", lower_id.to_string ());
    try {
      yield call.invoke_async (null);
    } catch (GLib.Error e) {
      warning (e.message);
      missing_entry.set_error (e.message);
      return 0;
    }
    var parser = new Json.Parser ();
    try  {
      parser.load_from_data (call.get_payload ());
    } catch (GLib.Error e) {
      warning (e.message);
      missing_entry.set_error (e.message);
      return 0;
    }
    var root_arr = parser.get_root ().get_array ();
    if (insert) {
      yield TweetUtils.work_array (root_arr,
                                   delta_updater,
                                   tweet_list,
                                   main_window,
                                   account);
    }
    return root_arr.get_length ();
  }


  public bool handles_double_open () {
    return true;
  }

  public void double_open () {
    if (!loading)
      this.scroll_up_next (true, false, true);
  }

  public virtual  void on_leave () {}

  public virtual  void load_cached () {}
  public abstract void load_newest ();
  public abstract void load_older ();
  protected abstract string get_function ();

  public override void destroy () {
    if (tweet_remove_timeout > 0)
      GLib.Source.remove (tweet_remove_timeout);
  }

  public virtual void create_tool_button(RadioToolButton? group){}

  public RadioToolButton? get_tool_button() {
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
          tweet_list.remove (tweet_list.get_row_at_index (ITimeline.REST));
          item_count--;
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
   *   - In any case, if the original tweet already exists in the timline,
   *     we don't display the retweet but instead just mark the original tweet
   *     as retweeted.
   */
  protected bool should_display_retweet (Tweet t) {
    // First case
    if (t.user_id == account.id)
      return false;

    // Second case
    foreach (Gtk.Widget w in tweet_list.get_children ()) {
      if (w == null || !(w is TweetListEntry))
       continue;

      var tle = (TweetListEntry) w;
      if (tle.tweet.id == t.rt_id || tle.tweet.rt_id == t.rt_id) {
        if (t.rt_by_id == account.id) {
          tle.tweet.retweeted = true;
          tle.tweet.my_retweet = t.id;
        }
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
      if (tle.tweet.id == id) {
        tle.seen = true;
        unread_count--;
        update_unread_count ();
        break;
      }
    }
  }

  protected void update_tweet_ids () {
    if (missing_entry.parent == null) {
      debug ("Tried to update tweet ids but the MLE is not active");
      return;
    }

    if (missing_entry.upper_id != -1)
      return;

    unowned Gtk.Widget last = null;
    foreach (var w in tweet_list.get_children ()) {
      if (w is MissingListEntry) {
        break;
      }
      last = w;
    }

    if (last != null) {
      missing_entry.upper_id = ((TweetListEntry)last).tweet.id;
    } else
      debug ("last == null");

  }

}
