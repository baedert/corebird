/*  This file is part of corebird.
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

class MentionsTimeline : IPage, ITimeline, IMessageReceiver, ScrollWidget{
  public int unread_count {get;set;}
  protected int64 max_id{
    get {return lowest_id;}
    set {lowest_id = value;}
  }
  public MainWindow main_window {set; get;}
  protected Gtk.ListBox tweet_list {set; get;}
  public Account account {get; set;}
  private int id;
  private BadgeRadioToolButton tool_button;
  private bool loading = false;
  private int64 lowest_id = int64.MAX-2;
  protected uint tweet_remove_timeout{get;set;}
  private ProgressEntry progress_entry = new ProgressEntry(75);

  public MentionsTimeline(int id){
    this.id = id;
    tweet_list = new Gtk.ListBox();
    tweet_list.get_style_context().add_class("stream");
    tweet_list.set_selection_mode(SelectionMode.NONE);
    this.add (tweet_list);
    tweet_list.set_sort_func(ITwitterItem.sort_func);


    this.scrolled_to_end.connect(() => {
      if(!loading) {
        loading = true;
        load_older();
      }
    });
    
    this.scrolled_to_start.connect(() => {
      handle_scrolled_to_start();
    });

    this.vadjustment.notify["value"].connect(() => {
      mark_seen_on_scroll (vadjustment.value);
      update_unread_count();
    });

    tweet_list.add(progress_entry);

    UserStream.get().register(this);
  }

  private void stream_message_received(StreamMessageType type, Json.Object root){
    if(type == StreamMessageType.TWEET) {
      if(root.get_string_member("text").contains("@"+User.screen_name)) {

        GLib.DateTime now = new GLib.DateTime.now_local();
        Tweet t = new Tweet();
        t.load_from_json(root, now);

        this.balance_next_upper_change(TOP);
        var entry = new TweetListEntry(t, main_window, account);
        entry.seen = false;

        tweet_list.add(entry);
//        tweet_list.resort();

        unread_count++;
        update_unread_count();

        if(Settings.notify_new_mentions()) {
          NotificationManager.notify(
            "New Mention from @"+t.screen_name,
            t.text,
            Notify.Urgency.NORMAL,
            t.avatar);
        }
      }
    } else if(type == StreamMessageType.FOLLOW) {
      NewFollowerEntry follower_entry;
      ITwitterItem first_entry = (ITwitterItem)tweet_list.get_children().first().data;

      if(first_entry is NewFollowerEntry){
        follower_entry = (NewFollowerEntry) first_entry;
        this.balance_next_upper_change(TOP);
      } else {
        follower_entry = new NewFollowerEntry();
        tweet_list.add(follower_entry);
      }

      bool real_follower_added = follower_entry.add_follower(root);
      if(real_follower_added){
        unread_count++;
        update_unread_count();
      }

      // TODO: Are all there resort calls actually needed?
//      tweet_list.resort();

      // Show notification
      if(Settings.notify_new_followers()) {
        
      }
    }
  }


  /**
   * see IPage#onJoin
   */
  public void on_join(int page_id, va_list arg_list){

  }

  public void load_cached() {
    SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
      "SELECT `sort_factor`, `type`, `data`, `id` FROM cache WHERE `type`='%d';".printf(NewFollowerEntry.TYPE));
    SQLHeavy.QueryResult result = q.execute();
    while(!result.finished){
      var entry = new NewFollowerEntry.from_data(result.fetch_int(3),
                                                 result.fetch_string(2),
                                                 result.fetch_int64(0));
      tweet_list.add(entry);
      entry.show_all();
      result.next();
    }
//    tweet_list.resort();
    this.vadjustment.set_upper(0);
  }

  public void load_newest() {
    try {
      this.load_newest_internal("1.1/statuses/mentions_timeline.json",
                                 Tweet.TYPE_MENTION,
        (count, lowest_id) => {
          if(lowest_id < this.lowest_id)
            this.lowest_id = lowest_id;
          tweet_list.remove(progress_entry);
          progress_entry = null;  
        });
    } catch (SQLHeavy.Error e) {
      warning(e.message);
    }
  }

  public void load_older() {
    this.balance_next_upper_change(BOTTOM);
    this.load_older_internal("1.1/statuses/mentions_timeline.json",
                             Tweet.TYPE_MENTION,
        (count, lowest_id) => {
          if(lowest_id < this.lowest_id){
            this.lowest_id = lowest_id;
            message("Setting lowest_id to new value(%s)", lowest_id.to_string());
          }

          this.loading = false;
        });

  }

  public void create_tool_button(RadioToolButton? group){
    tool_button = new BadgeRadioToolButton(group, "mentions");
    tool_button.label = "Connect";
  }

  public RadioToolButton? get_tool_button(){
    return tool_button;
  }

  public int get_id(){
    return id;
  }

  private void update_unread_count() {
    tool_button.show_badge = (unread_count > 0);
    tool_button.queue_draw();
  }
}
