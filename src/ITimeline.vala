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


/**
 * Describes everything a timeline should provide, in an abstract way.
 * Default implementations are given through the *_internal methods.
 */
public interface ITimeline : Gtk.Widget, IPage {
  public static const int REST = 25;
  /** The lowest id of any tweet in this timeline */
  protected abstract int64 lowest_id            {get; set;}
  protected abstract int64 max_id               {get; set; default = 0;}
  protected abstract TweetListBox tweet_list    {get; set;}
  public    abstract int unread_count           {get; set;}
  public    abstract DeltaUpdater delta_updater {get; set;}
  protected abstract string function            {get;}


  /**
   * Default implementation for loading the newest tweets
   * from the given function of the twitter api.
   */
  protected async void load_newest_internal () { //{{{
    int requested_tweet_count = 28;
    var call = account.proxy.new_call ();
    call.set_function (this.function);
    call.set_method("GET");
    call.add_param ("count", requested_tweet_count.to_string ());
    call.add_param ("contributor_details", "true");
    call.add_param ("include_my_retweet", "true");
    call.add_param ("max_id", (lowest_id - 1).to_string ());

    Json.Node? root_node = yield TweetUtils.load_threaded (call);
    if (root_node == null) {
      tweet_list.set_error (_("Could not load tweets"));
      tweet_list.set_empty ();
      return;
    }

    var root = root_node.get_array();
    if (root.get_length () == 0) {
      tweet_list.set_empty ();
      return;
    }
    var res = yield TweetUtils.work_array (root,
                                           requested_tweet_count,
                                           delta_updater,
                                           tweet_list,
                                           main_window,
                                           account);

    if (res.min_id < this.lowest_id)
      this.lowest_id = res.min_id;

    if (res.max_id > this.max_id)
      this.max_id = res.max_id;
  } //}}}

  /**
   * Default implementation to load older tweets.
   *
   */
  protected async void load_older_internal () { //{{{
    int requested_tweet_count = 28;
    var call = account.proxy.new_call ();
    call.set_function (this.function);
    call.set_method ("GET");
    call.add_param ("count", requested_tweet_count.to_string ());
    call.add_param ("include_my_retweet", "true");
    call.add_param ("max_id", (lowest_id - 1).to_string ());

    Json.Node? root_node = yield TweetUtils.load_threaded (call);
    if (root_node == null) {
      return;
    }
    var root = root_node.get_array ();
    if (root.get_length () == 0) {
      tweet_list.set_empty ();
      return;
    }
    var res = yield TweetUtils.work_array (root,
                                           requested_tweet_count,
                                           delta_updater,
                                           tweet_list,
                                           main_window,
                                           account);
    if (res.min_id < lowest_id)
      lowest_id = res.min_id;
  } ///}}}

  /**
   * Mark the TweetListEntries the user has already seen.
   *
   * @param value The scrolling value as from Gtk.Adjustment
   */
  protected void mark_seen_on_scroll (double value) { //{{{
    if (unread_count == 0)
      return;

    tweet_list.forall_internal (false, (w) => {
      ITwitterItem tle = (ITwitterItem)w;
      if (tle.seen)
        return;

      Gtk.Allocation alloc;
      tle.get_allocation (out alloc);
      if (alloc.y + (alloc.height / 2.0) >= value) {
        tle.seen = true;
        unread_count--;
      }
    });
  } //}}}

  public void rerun_filters () {
    GLib.List<unowned Gtk.Widget> children = tweet_list.get_children ();
    foreach (Gtk.Widget w in children) {
      if (!(w is TweetListEntry))
        continue;

      TweetListEntry tle = (TweetListEntry) w;
      if (account.filter_matches (tle.tweet))
        tle.hide ();
      else
        tle.show ();
    }
  }
}
