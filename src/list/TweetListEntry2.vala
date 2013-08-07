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
  private TextButton name_button;
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
  [GtkChild]
  private Box text_box;
  [GtkChild]
  private InvisibilityBin retweet_bin;







  public int64 sort_factor{
    get{ return tweet.created_at;}
  }
  public bool seen {get; set; default = true;}
  private unowned Account account;
  private unowned MainWindow window;
  public Tweet tweet;
  private Gtk.Menu more_menu;
  private bool values_set = false;


  public TweetListEntry(Tweet tweet, MainWindow? window, Account account){
    this.account = account;
    this.tweet = tweet;
    this.window = window;

    name_button.set_markup (tweet.user_name);
    screen_name_label.label = "@"+tweet.screen_name;
    avatar_image.pixbuf = tweet.avatar;
    text_label.label = tweet.get_formatted_text ();
    update_time_delta ();
    reply_entry.text = "@"+tweet.screen_name+" ";
    if (tweet.is_retweet) {
      rt_label.show ();
      rt_label.label = "RT by "+tweet.retweeted_by;
    }

    if (tweet.retweeted) {
      retweet_button.active = true;
      retweet_button.show ();
    }

    if (tweet.favorited) {
      favorite_button.active = true;
      favorite_button.show ();
    }

    // If the avatar gets loaded, we want to change it here immediately
    tweet.notify["avatar"].connect (() => {
      avatar_image.pixbuf = tweet.avatar;
      avatar_image.queue_draw ();
    });

    tweet.inline_media_added.connect ((pic) => {
      var inline_button = new ImageButton ();
      inline_button.set_bg (pic);
      text_box.pack_end (inline_button, false, false);
      inline_button.valign = Align.START;
      inline_button.clicked.connect(() => {
        ImageDialog id = new ImageDialog(window, tweet.media);
        id.show_all();
      });
      inline_button.show ();
    });

    if (tweet.media_thumb != null) {
      var inline_button = new ImageButton ();
      try {
        inline_button.set_bg (new Gdk.Pixbuf.from_file (tweet.media_thumb));
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }
      text_box.pack_end (inline_button, false, false);
      inline_button.valign = Align.START;
      inline_button.clicked.connect(() => {
        ImageDialog id = new ImageDialog(window, tweet.media);
        id.show_all();
      });
      inline_button.show ();
    }

    if (tweet.reply_id != 0) {
      conversation_button.show ();
    }

    DeltaUpdater.get ().add (this);

    values_set = true;

    reply_entry.focus_in_event.connect(() => {
      reply_revealer.reveal_child = true;
      return false;
    });
    reply_entry.focus_out_event.connect(() => {
      reply_revealer.reveal_child = false;
      return false;
    });
  }



  [GtkCallback]
  private void state_flags_changed_cb () {
    Gtk.StateFlags flags = this.get_state_flags ();
    bool buttons_visible = (bool)(flags & (StateFlags.PRELIGHT | StateFlags.SELECTED));
    if (buttons_visible) {
      if (account.id != tweet.user_id){
        retweet_bin.show_child ();
        favorite_button.show ();
      }
      more_button.show ();
    } else {
      favorite_button.set_visible (favorite_button.active);
      retweet_bin.set_child_visible (retweet_button.active);
      more_button.hide ();
    }
  }

  [GtkCallback]
  private bool focus_out_cb (Gdk.EventFocus evt) {
    reply_revealer.reveal_child = false;
    return false;
  }


  [GtkCallback]
  private bool key_released_cb (Gdk.EventKey evt) {
    //TODO: Use Accels instead of this?
    switch(evt.keyval) {
      case Gdk.Key.r:
        reply_revealer.reveal_child = !reply_revealer.reveal_child;
        reply_entry.grab_focus ();
        reply_entry.move_cursor (MovementStep.BUFFER_ENDS, 1, false);
        return true;
      case Gdk.Key.f:
        if (favorite_button.parent != null)
          favorite_button.active = !favorite_button.active;
        return true;
      case Gdk.Key.t:
        if (retweet_button.parent != null)
          retweet_button.active = !retweet_button.active;
        return true;
      case Gdk.Key.d:
        delete_tweet ();
        return true;
      case Gdk.Key.Return:
        ((ListBox)(this.parent)).row_activated (this);
        return true;
#if __DEV
      case Gdk.Key.k:
        stdout.printf (tweet.json_data+"\n");
        return true;
#endif
    }
    return false;
  }

  [GtkCallback]
  private bool reply_entry_key_released_cb (Gdk.EventKey evt) {
    switch (evt.keyval) {
      case Gdk.Key.Escape:
        reply_revealer.reveal_child = false;
        this.grab_focus ();
        return true;
      case Gdk.Key.r:
      case Gdk.Key.k:
      case Gdk.Key.f:
      case Gdk.Key.d:
      case Gdk.Key.t:
        return true;
      case Gdk.Key.Return:
        reply_send_button_clicked_cb ();
        return true;
    }
    return false;
  }

  [GtkCallback]
  private void more_button_clicked_cb () {
    if (more_menu == null) {
      more_menu = new Gtk.Menu ();
      more_menu.attach_widget = more_button;
      Gtk.MenuItem info_item = new Gtk.MenuItem.with_label (_("Info"));
      more_menu.add (info_item);
      if (tweet.user_id == account.id) {
        Gtk.MenuItem delete_item = new Gtk.MenuItem.with_label (_("Delete"));
        delete_item.activate.connect(delete_tweet);
        more_menu.add (delete_item);
      }

      more_menu.show_all ();
    }
    more_menu.popup (null, null, null, 0, 0);
  }

  /**
   * Retweets or un-retweets the tweet.
   */
  [GtkCallback]
  private void retweet_button_toggled () {
    // You can't retweet your own tweets.
    if (account.id == this.tweet.user_id || !values_set)
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
    if (!values_set)
      return;

    var spinner = new Spinner();
    spinner.start();
    WidgetReplacer.replace_tmp(favorite_button, spinner);

    var call = account.proxy.new_call();
    if (favorite_button.active) {
      call.set_function("1.1/favorites/create.json");
    } else {
      call.set_function("1.1/favorites/destroy.json");
    }

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
    // TODO: Show confirmation dialog
    var call = account.proxy.new_call ();
    call.set_method ("POST");
    call.set_function ("1.1/statuses/destroy/"+tweet.id.to_string ()+".json");
    call.add_param ("id", tweet.id.to_string ());
    call.invoke_async.begin (null, (obj, res) => {
      try { call.invoke_async.end (res);} catch (GLib.Error e) { critical (e.message);}
      this.sensitive = false;
    });
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

  public override bool draw (Cairo.Context c) {
    var style = this.get_style_context();
    int w = get_allocated_width();
    int h = get_allocated_height();
    style.render_background(c, 0, 0, w, h);

    var border_color = style.get_border_color(get_state_flags());
    c.set_source_rgba(border_color.red, border_color.green, border_color.blue,
                      border_color.alpha);

    // The line here is 50% of the width
    c.move_to(w*0.25, h);
    c.line_to(w*0.75, h);
    c.stroke();

    base.draw(c);
    return false;
  }

}

