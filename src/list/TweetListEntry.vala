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


[GtkTemplate (ui = "/org/baedert/corebird/ui/tweet-list-entry.ui")]
public class TweetListEntry : ITwitterItem, Gtk.ListBoxRow {
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private TextButton name_button;
  [GtkChild]
  private Gtk.Label time_delta_label;
  [GtkChild]
  private Gtk.Image avatar_image;
  [GtkChild]
  private Gtk.Label text_label;
  [GtkChild]
  private Gtk.Label rt_label;
  [GtkChild]
  private Gtk.Image rt_image;
  [GtkChild]
  private Gtk.Image conversation_image;
  [GtkChild]
  private BgBox hover_box;
  [GtkChild]
  private DoubleTapButton retweet_button;
  [GtkChild]
  private Gtk.ToggleButton favorite_button;
  [GtkChild]
  private Gtk.Button reply_button;
  [GtkChild]
  private Gtk.MenuButton more_button;
  [GtkChild]
  private Gtk.Menu more_menu;
  [GtkChild]
  private Gtk.MenuItem more_menu_delete_item;
  [GtkChild]
  private Gtk.Grid grid;
  [GtkChild]
  private MultiMediaWidget mm_widget;



  public int64 sort_factor{
    get{ return tweet.created_at;}
  }
  public bool seen {get; set; default = true;}
  private weak Account account;
  private weak MainWindow window;
  public Tweet tweet;
  private bool values_set = false;
  private bool delete_first_activated = false;
  [Signal (action = true)]
  private signal void reply_tweet ();
  [Signal (action = true)]
  private signal void favorite_tweet ();
  [Signal (action = true)]
  private signal void retweet_tweet ();
  [Signal (action = true)]
  private signal void delete_tweet ();


  public TweetListEntry (owned Tweet tweet, MainWindow? window, Account account){
    this.account = account;
    this.tweet = tweet;
    this.window = window;

    name_button.set_markup (tweet.user_name);
    screen_name_label.label = "@"+tweet.screen_name;
    avatar_image.pixbuf = tweet.avatar;
    text_label.label = tweet.get_formatted_text ();
    update_time_delta ();
    if (tweet.is_retweet) {
      rt_label.show ();
      rt_image.show ();
      rt_label.label = @"<span underline='none'><a href=\"@$(tweet.rt_by_id)/$(tweet.rt_by_screen_name)\"
                         title=\"@$(tweet.rt_by_screen_name)\">$(tweet.retweeted_by)</a></span>";
    } else {
      grid.remove (rt_image);
      grid.remove (rt_label);
    }


    if (tweet.retweeted || tweet.favorited || tweet.reply_id != 0) {
      adjust_hover_box ();
    }

    retweet_button.visible = tweet.retweeted;
    retweet_button.active = tweet.retweeted;
    tweet.notify["retweeted"].connect (() => {
      values_set = false;
      retweet_button.active = tweet.retweeted;
      retweet_button.visible = tweet.retweeted;
      adjust_hover_box ();
      values_set = true;
    });

    favorite_button.visible = tweet.favorited;
    favorite_button.active = tweet.favorited;
    tweet.notify["favorited"].connect (() => {
      values_set = false;
      favorite_button.active = tweet.favorited;
      favorite_button.visible = tweet.favorited;
      adjust_hover_box ();
      values_set = true;
    });

    if (tweet.reply_id == 0)
      conversation_image.unparent ();
    else {
      conversation_image.show ();
    }

    // If the avatar gets loaded, we want to change it here immediately
    tweet.notify["avatar"].connect (avatar_changed);

    if (tweet.has_inline_media) {
      mm_widget.set_all_media (tweet.medias);
      mm_widget.media_clicked.connect (media_button_clicked_cb);
      mm_widget.window = window;
    } else
      grid.remove (mm_widget);


    if (tweet.user_id != account.id)
      more_menu.remove (more_menu_delete_item);


    hover_box.show ();

    reply_tweet.connect (reply_button_clicked_cb);
    delete_tweet.connect (delete_tweet_activated);
    favorite_tweet.connect (() => {
      if (favorite_button.parent != null)
        favorite_button.active = !favorite_button.active;
    });
    retweet_tweet.connect (() => {
      if (retweet_button.parent != null)
        retweet_button.tap ();
    });

    values_set = true;
  }

  private void delete_tweet_activated () {
    if (tweet.user_id != account.id)
      return; // Nope.

    if (delete_first_activated) {
      TweetUtils.delete_tweet.begin (account, tweet, () => {
        sensitive = false;
      });
    } else
      delete_first_activated = true;
  }

  private void avatar_changed () {
    avatar_image.pixbuf = tweet.avatar;
    avatar_image.queue_draw ();
  }

  private void media_button_clicked_cb (Media media) {
    if (media.type == MediaType.IMAGE ||
        media.type == MediaType.GIF) {
      var id = new ImageDialog (window, media.path);
      id.show_all ();
    } else if (media.type == MediaType.VINE ||
               media.type == MediaType.ANIMATED_GIF) {
      var vd = new VideoDialog (window, media);
      vd.show_all ();
    } else {
      warning ("Unknown media type: %d", media.type);
    }
  }

  static construct {
    unowned Gtk.BindingSet binding_set = Gtk.BindingSet.by_class (typeof (TweetListEntry).class_ref ());

    Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.r, 0,      "reply-tweet", 0, null);
    Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.Return, 0, "activate", 0, null);
    Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.d, 0,      "delete-tweet", 0, null);
    Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.t, 0,      "retweet-tweet", 0, null);
    Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.f, 0,      "favorite-tweet", 0, null);
    // TODO: Add q shortcut
  }

  [GtkCallback]
  private void state_flags_changed_cb () { //{{{
    Gtk.StateFlags flags = this.get_state_flags ();
    var ct = this.get_style_context ();
    bool buttons_visible = (bool)(flags & (Gtk.StateFlags.PRELIGHT | Gtk.StateFlags.SELECTED));
    buttons_visible = (buttons_visible || more_menu.visible);
    more_button.visible = buttons_visible;
    favorite_button.visible = buttons_visible || tweet.favorited;
    reply_button.visible = buttons_visible;

    if (buttons_visible) {
      hover_box.margin_end = 1;
      hover_box.margin_top = (time_delta_label.get_allocated_height () / 2) - 6;
      hover_box.override_background_color (Gtk.StateFlags.NORMAL,
                                           ct.get_background_color (Gtk.StateFlags.PRELIGHT));
      retweet_button.visible = (account.id != tweet.user_id);
    } else {
      hover_box.override_background_color (Gtk.StateFlags.NORMAL,
                                           ct.get_background_color (Gtk.StateFlags.NORMAL));
      retweet_button.visible = tweet.retweeted;
      hover_box.margin_end = time_delta_label.get_allocated_width () + 3;
      if (tweet.reply_id != 0)
        hover_box.margin_end += conversation_image.get_allocated_width () + 4;
    }
  } //}}}

  [GtkCallback]
  private bool focus_out_cb (Gdk.EventFocus evt) {
    delete_first_activated = false;
    retweet_button.reset ();
    return false;
  }


  [GtkCallback]
  private bool key_released_cb (Gdk.EventKey evt) {
#if DEBUG
    switch(evt.keyval) {
      case Gdk.Key.k:
        stdout.printf (tweet.json_data+"\n");
        return true;
    }
#endif
    return false;
  }

  /**
   * Retweets or un-retweets the tweet.
   */
  [GtkCallback]
  private void retweet_button_toggled () { // {{{
    // You can't retweet your own tweets.
    if (account.id == this.tweet.user_id || !values_set)
      return;
    var spinner = new Gtk.Spinner();

    spinner.start ();
    WidgetReplacer.replace_tmp (retweet_button, spinner);
    spinner.show ();
    TweetUtils.toggle_retweet_tweet.begin (account, tweet, !retweet_button.active, () => {
      WidgetReplacer.replace_tmp_back(retweet_button);
      retweet_button.visible = retweet_button.active;
    });

  } // }}}

  [GtkCallback]
  private void favorite_button_toggled () { // {{{
    if (!values_set)
      return;

    var spinner = new Gtk.Spinner();
    spinner.start();
    WidgetReplacer.replace_tmp(favorite_button, spinner);
    spinner.show ();
    TweetUtils.toggle_favorite_tweet.begin (account, tweet, !favorite_button.active, () => {
      WidgetReplacer.replace_tmp_back(favorite_button, true,
                                      favorite_button.active);
      favorite_button.visible = favorite_button.active;
    });
  } // }}}

  [GtkCallback]
  private void name_button_clicked_cb () {
    window.switch_page (MainWindow.PAGE_PROFILE,
                        tweet.user_id,
                        tweet.screen_name);
  }
  [GtkCallback]
  private void reply_button_clicked_cb () {
    ComposeTweetWindow ctw = new ComposeTweetWindow(this.window, this.account, this.tweet,
                                                    ComposeTweetWindow.Mode.REPLY,
                                                    this.window.get_application ());
    ctw.show ();
  }

  [GtkCallback]
  private void detail_item_activated_cb () {
    window.switch_page (MainWindow.PAGE_TWEET_INFO,
                        TweetInfoPage.BY_INSTANCE,
                        tweet);
  }

  [GtkCallback]
  private void quote_item_activated_cb () {
    ComposeTweetWindow ctw = new ComposeTweetWindow(this.window, this.account, this.tweet,
                                                    ComposeTweetWindow.Mode.QUOTE,
                                                    this.window.get_application ());
    ctw.show ();

  }

  [GtkCallback]
  private void delete_item_activated_cb () {
    delete_first_activated = true;
    delete_tweet ();
  }

  [GtkCallback]
  private bool link_activated_cb (string uri) {
    return TweetUtils.activate_link (uri, window);
  }


  private void adjust_hover_box () {
    // Only do this if the hover_box has not been 'adjusted' yet
    if (hover_box.margin_end > 0) {
      return;
    }

    // XXX Keep this in sync with the version below
    if (time_delta_label.get_allocated_width () > 1 && conversation_image.get_allocated_width () > 1) {
      hover_box.margin_top = (time_delta_label.get_allocated_height () / 2) - 6;
      hover_box.margin_end = time_delta_label.get_allocated_width () + 3;
      if (tweet.reply_id != 0) {
        conversation_image.margin_top = (time_delta_label.get_allocated_height () / 2) - 6;
        hover_box.margin_end += conversation_image.get_allocated_width () + 4;
      }
      return;
    }


    ulong id = 0;
    id = time_delta_label.size_allocate.connect (() => {
      hover_box.margin_top = (time_delta_label.get_allocated_height () / 2) - 6;
      hover_box.margin_end += time_delta_label.get_allocated_width () + 3;
      if (tweet.reply_id != 0) {
        conversation_image.margin_top = (time_delta_label.get_allocated_height () / 2) - 6;
      }
      time_delta_label.disconnect (id);
    });

    if (tweet.reply_id == 0)
      return;

    ulong id2 = 0;
    id2 = conversation_image.size_allocate.connect (() => {
      hover_box.margin_end += conversation_image.get_allocated_width () + 4;
      conversation_image.disconnect (id2);
    });

  }

  /**
   * Updates the time delta label in the upper right
   *
   * @return The seconds between the current time and
   *         the time the tweet was created
   */
  public int update_time_delta (GLib.DateTime? now = null) { //{{{
    GLib.DateTime cur_time;
    if (now == null)
      cur_time = new GLib.DateTime.now_local ();
    else
      cur_time = now;

    GLib.DateTime then = new GLib.DateTime.from_unix_local (
                 tweet.is_retweet ? tweet.rt_created_at : tweet.created_at);
    time_delta_label.label = Utils.get_time_delta (then, cur_time);
    return (int)(cur_time.difference (then) / 1000.0 / 1000.0);
  } //}}}

  public override bool draw (Cairo.Context c) { //{{{
    var style = this.get_style_context();
    int w = get_allocated_width();
    int h = get_allocated_height();
    style.render_background(c, 0, 0, w, h);

    var border_color = style.get_border_color(get_state_flags());
    c.set_source_rgba(border_color.red, border_color.green, border_color.blue,
                      border_color.alpha);

    base.draw(c);
    // The line here is 50% of the width
    c.move_to(w*0.25, h);
    c.line_to(w*0.75, h);
    c.stroke();

    return false;
  } //}}}

}
