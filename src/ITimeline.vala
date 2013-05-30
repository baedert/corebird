

/**
 * Describes everything a timeline should provide, in an abstract way.
 * Default implementations are given through the *_internal methods.
 */
interface ITimeline : Gtk.Widget, IPage {
  public static const int REST = 25;
  protected abstract int64 max_id{get;set;}
  public    abstract MainWindow main_window{get;set;}
  protected abstract Egg.ListBox tweet_list{get;set;}

  public abstract void load_cached();
  public abstract void load_newest();
  public abstract void load_older ();
  public void update (){}

  protected abstract uint tweet_remove_timeout{get; set;}


  /**
   * Default implementation to load cached tweets from the
   * 'cache' sql table
   *
   * @param tweet_type The type of tweet to load
   */
  protected void load_cached_internal(int tweet_type) throws SQLHeavy.Error {
  }

  /**
   * Default implementation for loading the newest tweets
   * from the given function of the twitter api.
   *
   * @param function The twitter function to use
   * @param tweet_type The type of tweets to load
   */
  protected void load_newest_internal(string function, int tweet_type,
                                      LoaderThread.EndLoadFunc? end_load_func = null)
                                      throws SQLHeavy.Error {
    int64 greatest_id = 0;

    var call = Twitter.proxy.new_call();
    call.set_function(function);
    call.set_method("GET");
    call.add_param("count", "20");
    call.add_param("contributor_details", "true");
    if(greatest_id > 0)
      call.add_param("since_id", greatest_id.to_string());

    call.invoke_async.begin(null, () => {
      string back = call.get_payload();
      stdout.printf(back+"\n");
      var parser = new Json.Parser();
      try {
        parser.load_from_data(back);
      } catch(GLib.Error e) {
        stdout.printf(back+"\n");
        critical("Problem with json data from twitter: %s", e.message);
        return;
      }

      var root = parser.get_root().get_array();
      var loader_thread = new LoaderThread(root, main_window, tweet_list,
                                           tweet_type);
      loader_thread.run();
    });
  }

  /**
   * Default implementation to load older tweets using
   * the max_id method from the given function
   *
   * @param function The Twitter function to use
   * @param max_id The highest id of tweets to receive
   */
  protected void load_older_internal(string function, int tweet_type,
                                     LoaderThread.EndLoadFunc? end_load_func = null) {
    var call = Twitter.proxy.new_call();
    call.set_function(function);
    call.set_method("GET");
    message(@"using max_id: $max_id");
    call.add_param("max_id", (max_id - 1).to_string());
    call.invoke_async.begin(null, (obj, result) => {
      try{
        call.invoke_async.end(result);
      } catch (GLib.Error e) {
        critical(e.message);
        critical("Code: %u", call.get_status_code());
      }


      string back = call.get_payload();
      //stdout.printf(back+"\n");
      var parser = new Json.Parser();
      try{
        parser.load_from_data (back);
      } catch (GLib.Error e) {
        stdout.printf (back+"\n");
        critical(e.message);
      }

      var root = parser.get_root().get_array();
      var loader_thread = new LoaderThread(root, main_window, tweet_list,
                                           tweet_type);
      loader_thread.run(end_load_func);
    });
  }

  /**
   * Mark the TweetListEntries the user has already seen.
   * 
   * @param value The scrolling value as from Gtk.Adjustment
   */
  protected void mark_seen_on_scroll(double value) {
    if(unread_count == 0)
      return;

    tweet_list.forall_internal(false, (w) => {
      ITwitterItem tle = (ITwitterItem)w;
      if(tle.seen)
        return;

      Gtk.Allocation alloc;
      tle.get_allocation(out alloc);
      if(alloc.y+(alloc.height/2.0) >= value) {
        tle.seen = true;
        unread_count--;
      }
        
    });
  }

  protected void handle_scrolled_to_start() {
    if(tweet_list.get_size() > ITimeline.REST) {
      tweet_remove_timeout = GLib.Timeout.add(5000, () => {
        tweet_list.remove_last (tweet_list.get_size() - REST);
        return false;
      });
    } else {
      if(tweet_remove_timeout != 0) {
        GLib.Source.remove(tweet_remove_timeout);
        tweet_remove_timeout = 0;
      }
    }
  }
}
