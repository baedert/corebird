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

class MentionsTimeline : IPage, ITimeline, IMessageReceiver, ScrollWidget {
  private bool inited = false;
  public int unread_count {get;set;}
  public unowned MainWindow main_window {set; get;}
  protected Gtk.ListBox tweet_list {set; get;}
  public Account account {get; set;}
  private int id;
  private BadgeRadioToolButton tool_button;
  private bool loading = false;
  public int64 lowest_id {get;set; default = int64.MAX-2;}
  protected uint tweet_remove_timeout{get;set;}
  private ProgressEntry progress_entry = new ProgressEntry(75);
  public DeltaUpdater delta_updater {get;set;}

  public MentionsTimeline(int id){
    this.id = id;
    tweet_list = new Gtk.ListBox();
    tweet_list.get_style_context().add_class("stream");
    tweet_list.set_selection_mode(SelectionMode.NONE);
    tweet_list.set_sort_func(ITwitterItem.sort_func);
    this.add (tweet_list);


    this.scrolled_to_end.connect(() => {
      if(!loading) {
        loading = true;
        load_older();
      }
    });

    this.scrolled_to_start.connect(handle_scrolled_to_start);
    this.button_press_event.connect (button_pressed_event_cb);
    tweet_list.activate_on_single_click = false;
    tweet_list.row_activated.connect ((row) => {
      main_window.switch_page (MainWindow.PAGE_TWEET_INFO,
                               TweetInfoPage.BY_INSTANCE,
                               ((TweetListEntry)row).tweet);
    });



    this.vadjustment.notify["value"].connect(() => {
      mark_seen_on_scroll (vadjustment.value);
      update_unread_count();
    });

    tweet_list.add(progress_entry);
  }

  private void stream_message_received(StreamMessageType type, Json.Node root_node){
    Json.Object root = root_node.get_object ();
    if(type == StreamMessageType.TWEET) {
      if(root.get_string_member("text").contains("@"+account.screen_name)) {
        GLib.DateTime now = new GLib.DateTime.now_local();
        Tweet t = new Tweet();
        t.load_from_json(root_node, now);
        if (t.user_id == account.id)
          return;

        this.balance_next_upper_change(TOP);
        var entry = new TweetListEntry(t, main_window, account);
        entry.seen = false;

        delta_updater.add (entry);
        tweet_list.add (entry);

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
    if (!inited) {
      load_cached ();
      load_newest ();
      inited = true;
    }
  }

  public void load_cached() {
    Corebird.db.exec ("SELECT `sort_factor`, `type`, `data`, `id` FROM cache WHERE
        `type`='%d';".printf(NewFollowerEntry.TYPE), (n_cols, vals) => {
      var entry = new NewFollowerEntry.from_data (int.parse(vals[3]), vals[2], int64.parse(vals[0]));
      tweet_list.add(entry);
      entry.show_all();
      return 0;
    });
    this.vadjustment.set_upper(0);
  }

  public void load_newest() {
    this.load_newest_internal.begin("1.1/statuses/mentions_timeline.json", Tweet.TYPE_MENTION, () => {
      tweet_list.remove(progress_entry);
      progress_entry = null;
    });
  }

  public void load_older() {
    this.balance_next_upper_change (BOTTOM);
    this.load_older_internal.begin ("1.1/statuses/mentions_timeline.json", Tweet.TYPE_MENTION, () => {
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
