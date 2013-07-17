


using Gtk;



[GtkTemplate (ui = "/org/baedert/corebird/ui/tweet-list-entry.ui")]
class TweetListEntry : ITwitterItem, ListBoxRow {
  [GtkChild]
  private Label screen_name_label;
  [GtkChild]
  private Label name_label;
  [GtkChild]
  private Label time_delta_label;
  [GtkChild]
  private ToggleButton retweet_button;
  [GtkChild]
  private ToggleButton favorite_button;
  [GtkChild]
  private Button more_button;
  [GtkChild]
  private Image avatar_image;
  [GtkChild]
  private Label text_label;
  [GtkChild]
  private Revealer reply_revealer;
  [GtkChild]
  private Entry reply_entry;
  
  

  
  
  
  
  public int64 sort_factor{
    get{ return tweet.created_at;}
  }
  public bool seen {get; set; default = true;}
  private unowned Account account;
  private unowned Tweet tweet;


  public TweetListEntry(Tweet tweet, MainWindow? window, Account account){
    this.account = account;
    this.tweet = tweet;

    name_label.label = tweet.user_name;
    screen_name_label.label = "@"+tweet.screen_name;
    avatar_image.pixbuf = tweet.avatar;
    text_label.label = tweet.text;
    update_time_delta ();
    reply_entry.text = "@"+tweet.screen_name;
    reply_entry.move_cursor (MovementStep.BUFFER_ENDS, 1, true);
  }



  [GtkCallback]
  private void state_flags_changed_cb () {
    Gtk.StateFlags flags = this.get_state_flags ();
    bool buttons_visible = (bool)(flags & (StateFlags.PRELIGHT | StateFlags.SELECTED));
    if (buttons_visible) {
      if (account.id != tweet.user_id){
        retweet_button.show ();
        favorite_button.show ();
      }
      more_button.show ();
    } else {
      favorite_button.set_visible (favorite_button.active);
      retweet_button.set_visible (retweet_button.active);
      more_button.hide ();
    }
  }

  [GtkCallback]
  private bool focus_out_cb (Gdk.EventFocus evt) {
    message ("in: %d, send_event: %d, type: %s", 
        (int)evt.@in, (int)evt.send_event, evt.type.to_string ());
//    reply_revealer.reveal_child = false;
    return false;
    // The focus gets moved out -> the revealer reveals again
  }


  [GtkCallback]
  private bool key_released_cb (Gdk.EventKey evt) {
    message ("%s, %d", evt.type.to_string (), (int)evt.group);
    switch(evt.keyval) {
      case Gdk.Key.r:
        message ("r");
        reply_revealer.reveal_child = !reply_revealer.reveal_child;
        reply_entry.grab_focus ();
        return true;
    }
    return false;
  }

  [GtkCallback]
  private bool reply_entry_key_released_cb (Gdk.EventKey evt) {
    if (evt.keyval == Gdk.Key.Escape) {
      reply_revealer.reveal_child = false;
      this.grab_focus ();
      return true;
    } else if (evt.keyval == Gdk.Key.r)
      return true;
    return false;
  }

  [GtkCallback]
  private void retweet_button_toggled () {

  }

  [GtkCallback]
  private void favorite_button_toggled () {

  }


  /**
   * Updates the time delta label in the upper right
   *
   * @return The seconds between the current time and
   *         the time the tweet was created
   */
  public int update_time_delta () {
    GLib.DateTime now  = new GLib.DateTime.now_local ();
    GLib.DateTime then = new GLib.DateTime.from_unix_local (
      tweet.is_retweet ? tweet.rt_created_at : tweet.created_at);
    string link = "https://twitter.com/%s/status/%s".printf (tweet.screen_name,
                                                             tweet.id.to_string());
    time_delta_label.label = "<small><a href='%s' title='Open in Browser'>%s</a></small>"
                  .printf (link, Utils.get_time_delta (then, now));
    return (int)(now.difference (then) / 1000.0 / 1000.0);
  }


}

