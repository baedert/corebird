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
interface ITimeline : Gtk.Widget, IPage {
  public static const int REST = 25;
  /** The lowest id of any tweet in this timeline */
  protected abstract int64 lowest_id            {get; set;}
  protected abstract int64 max_id               {get; set; default = 0;}
  protected abstract Gtk.ListBox tweet_list     {get; set;}
  public    abstract int unread_count           {get; set;}
  public    abstract DeltaUpdater delta_updater {get; set;}


  /**
   * Default implementation for loading the newest tweets
   * from the given function of the twitter api.
   *
   * @param function The twitter function to use
   * @param tweet_type The type of tweets to load
   */
  protected async void load_newest_internal(string function, int tweet_type) { //{{{
    var call = account.proxy.new_call();
    call.set_function(function);
    call.set_method("GET");
    call.add_param ("count", "28");
    call.add_param ("contributor_details", "true");
    call.add_param ("include_my_retweet", "true");
    if (max_id > 0)
      call.add_param ("max_id", (max_id - 1).to_string ());

    call.invoke_async.begin(null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }

      string back = call.get_payload();

      var parser = new Json.Parser();
      try {
        parser.load_from_data(back);
      } catch(GLib.Error e) {
        stdout.printf(back+"\n");
        critical("Problem with json data from twitter: %s", e.message);
        return;
      }


      var now = new GLib.DateTime.now_local ();
      var root = parser.get_root().get_array();
      root.foreach_element( (array, index, node) => {
        Tweet t = new Tweet();
        t.load_from_json(node, now);

        if (tweet_type != -1){
          t.type = tweet_type;
        }

        if(t.id < lowest_id)
          lowest_id = t.id;

        var entry  = new TweetListEntry(t, main_window, account);
        this.delta_updater.add (entry);
        tweet_list.add (entry);
      });
      load_newest_internal.callback ();
    });
    yield;
  } //}}}

  /**
   * Default implementation to load older tweets.
   *
   * @param function The Twitter function to use
   * @param tweet_type The type of tweets to load
   */
  protected async void load_older_internal(string function, int tweet_type) { //{{{
    var call = account.proxy.new_call();
    call.set_function(function);
    call.set_method("GET");
    message(@"using lowest_id: $lowest_id");
    call.add_param("max_id", (lowest_id - 1).to_string());
    call.invoke_async.begin(null, (obj, result) => {
      try{
        call.invoke_async.end(result);
      } catch (GLib.Error e) {
        critical(e.message);
        critical("Code: %u", call.get_status_code());
      }

      string back = call.get_payload();
      debug(back+"\n");
      var parser = new Json.Parser();
      try{
        parser.load_from_data (back);
      } catch (GLib.Error e) {
        critical(e.message);
      }
      var now = new GLib.DateTime.now_local ();
      var root = parser.get_root().get_array();
      root.foreach_element( (array, index, node) => {
        Tweet t = new Tweet();
        t.load_from_json(node, now);

        if (tweet_type != -1){
          t.type = tweet_type;
        }

        if(t.id < lowest_id)
          lowest_id = t.id;

        var entry  = new TweetListEntry(t, main_window, account);
        delta_updater.add (entry);
        tweet_list.add (entry);
      });
      load_older_internal.callback ();
    });
    yield;
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
      tle.get_allocation(out alloc);
      if (alloc.y+(alloc.height/2.0) >= value) {
        tle.seen = true;
        unread_count--;
      }

    });
  } //}}}


}
