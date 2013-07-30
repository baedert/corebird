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
  private Label rt_label;
  [GtkChild]
  private Revealer reply_revealer;
  [GtkChild]
  private Entry reply_entry;
  [GtkChild]
  private Button conversation_button;
  
  

  
  
  
  
  public int64 sort_factor{
    get{ return tweet.created_at;}
  }
  public bool seen {get; set; default = true;}
  private unowned Account account;
  private unowned MainWindow window;
  private Tweet tweet;


  public TweetListEntry(Tweet tweet, MainWindow? window, Account account){
    this.account = account;
    this.tweet = tweet;
    this.window = window;

    name_label.label = "<b><a href='@%s'>%s</a></b>".printf (tweet.screen_name,
                                                             tweet.user_name);
    screen_name_label.label = "@"+tweet.screen_name;
    avatar_image.pixbuf = tweet.avatar;
    text_label.label = Utils.format_tweet_text (tweet.text);
    update_time_delta ();
    reply_entry.text = "@"+tweet.screen_name;
    reply_entry.move_cursor (MovementStep.BUFFER_ENDS, 1, true);
    if (tweet.is_retweet) {
      rt_label.show ();
      rt_label.label = "RT by "+tweet.retweeted_by;
    }


    // If the avatar gets loaded, we want to change it here immediately
    tweet.notify["avatar"].connect (() => {
      avatar_image.pixbuf = tweet.avatar;
      avatar_image.queue_draw ();
    });

    if (tweet.reply_id != 0)
      conversation_button.show ();

    DeltaUpdater.get ().add (this);
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
//    message ("in: %d, send_event: %d, type: %s", 
//        (int)evt.@in, (int)evt.send_event, evt.type.to_string ());
//    reply_revealer.reveal_child = false;
    return false;
    // The focus gets moved out -> the revealer reveals again
    /*
      Problem: This also gets called when we automatically focus the
      reply_entry when pressing 'r', so it gets un-revealed immediately.
    */
  }


  [GtkCallback]
  private bool key_released_cb (Gdk.EventKey evt) {
    switch(evt.keyval) {
      case Gdk.Key.r:
        reply_revealer.reveal_child = !reply_revealer.reveal_child;
        reply_entry.grab_focus ();
        return true;
      case Gdk.Key.f:
        favorite_button.active = !favorite_button.active;
        return true;
      case Gdk.Key.t:
        retweet_button.active = !retweet_button.active;
        return true;
      case Gdk.Key.d:
        delete_tweet ();
        return true;
#if __DEV
      case Gdk.Key.k:
        stdout.printf (tweet.json_data);
        return true;
#endif
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
    else if (evt.keyval == Gdk.Key.Return) {
      reply_send_button_clicked_cb ();
      return true;
    }

    return false;
  }

  [GtkCallback]
  private void more_button_clicked_cb () {

  }

  /**
   * Retweets or un-retweets the tweet.
   */
  [GtkCallback]
  private void retweet_button_toggled () {
    // You can't retweet your own tweets.
    if (account.id == this.tweet.user_id)
      return;
    var spinner = new Spinner();
    spinner.start();
    WidgetReplacer.replace_tmp(retweet_button, spinner);

    var call = account.proxy.new_call();
    call.set_method("POST");
    if(retweet_button.active) {
      call.set_function(@"1.1/statuses/retweet/$(tweet.id).json");
      call.invoke_async.begin(null, (obj, res) => {
        try{
          call.invoke_async.end(res);
        } catch (GLib.Error e) {
          Utils.show_error_dialog(e.message);
        }
        string back = call.get_payload();
        var parser = new Json.Parser();
        try{
          parser.load_from_data(back);
        } catch(GLib.Error e){
          critical(e.message);
          critical(back);
        }
        int64 new_id = parser.get_root().get_object().get_int_member("id");
        tweet.rt_id = new_id;
        WidgetReplacer.replace_tmp_back(retweet_button);
      });
    } else {
      call.set_function(@"1.1/statuses/destroy/$(tweet.rt_id).json");
      call.invoke_async.begin(null, (obj, res) => {
        try {
          call.invoke_async.end(res);
        } catch (GLib.Error e) {
          Utils.show_error_dialog(e.message);
          critical(e.message);
        }
        WidgetReplacer.replace_tmp_back(retweet_button);
      });
    }

  }

  [GtkCallback]
  private void favorite_button_toggled () {
    var spinner = new Spinner();
    spinner.start();
    WidgetReplacer.replace_tmp(favorite_button, spinner);

    var call = account.proxy.new_call();
    if (favorite_button.active)
      call.set_function("1.1/favorites/create.json");
    else
      call.set_function("1.1/favorites/destroy.json");

    call.set_method("POST");
    call.add_param("id", tweet.id.to_string());
    call.invoke_async.begin(null, (obj, res) => {
      try {
        call.invoke_async.end(res);
      } catch (GLib.Error e) {
        critical(e.message);
      }
      WidgetReplacer.replace_tmp_back(favorite_button, true,
                                      favorite_button.active);
    });
  }


  [GtkCallback]
  private void reply_send_button_clicked_cb () {
    string text = reply_entry.text;
    if (text.strip().length > 0){
      var call = account.proxy.new_call ();
      call.set_function ("1.1/statuses/update.json");
      call.set_method ("POST");
      call.add_param ("in_reply_to_status_id", tweet.id.to_string ());
      call.add_param ("status", text);
      call.invoke_async.begin (null, () => {
        reply_revealer.reveal_child = false;
      });
    }

    this.grab_focus ();
    reply_revealer.reveal_child = false;
  }

  [GtkCallback]
  private bool link_activated_cb (string uri) {
    uri = uri._strip();
    string term = uri.substring(1);

    if(uri.has_prefix("@")){
      window.switch_page(MainWindow.PAGE_PROFILE,
                         ProfilePage.BY_NAME,
                         term);
      return true;
    }else if(uri.has_prefix("#")){
      window.switch_page(MainWindow.PAGE_SEARCH, uri);
      return true;
    }
    return false;
  }


  private void delete_tweet () {
    if (tweet.user_id != account.id)
      return; // Nope.
    message ("TODO: Implement");
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

