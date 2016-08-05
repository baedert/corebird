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
  private const GLib.ActionEntry[] action_entries = {
    {"quote", quote_activated},
    {"delete", delete_activated}
  };

  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private TextButton name_button;
  [GtkChild]
  private Gtk.Label time_delta_label;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Label text_label;
  [GtkChild]
  private Gtk.Label rt_label;
  [GtkChild]
  private Gtk.Image rt_image;
  [GtkChild]
  private Gtk.Image conversation_image;
  [GtkChild]
  private Gtk.Image rt_status_image;
  [GtkChild]
  private Gtk.Image fav_status_image;
  [GtkChild]
  private DoubleTapButton retweet_button;
  [GtkChild]
  private Gtk.ToggleButton favorite_button;
  [GtkChild]
  private Gtk.Grid grid;
  [GtkChild]
  private Gtk.Stack stack;
  [GtkChild]
  private Gtk.Box action_box;

  /* Conditionally created widgets... */
  private Gtk.Label? quote_label = null;
  private TextButton? quote_name = null;
  private Gtk.Label? quote_screen_name = null;
  private Gtk.Grid? quote_grid = null;
  private Gtk.Stack? media_stack = null;
  private MultiMediaWidget? mm_widget = null;


  private bool _read_only = false;
  public bool read_only {
    set {
      assert (value);
      if (mm_widget != null)
        mm_widget.sensitive = !value;

      this.grid.remove (name_button);
      var name_label = new Gtk.Label ("<b>" + tweet.get_user_name () + "</b>");
      name_label.set_use_markup (true);
      name_label.valign = Gtk.Align.BASELINE;
      name_label.show ();
      this.grid.attach (name_label, 1, 0, 1, 1);

      this._read_only = value;
    }
  }
  public int64 sort_factor {
    get { return tweet.source_tweet.id;}
  }
  public bool shows_actions {
    get {
      return stack.visible_child == action_box;
    }
  }
  private unowned Account account;
  private unowned MainWindow main_window;
  public Cb.Tweet tweet;
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

  public TweetListEntry (Cb.Tweet    tweet,
                         MainWindow? main_window,
                         Account     account,
                         bool        restrict_height = false) {
    this.account = account;
    this.tweet = tweet;
    this.main_window = main_window;

    name_button.set_markup (tweet.get_user_name ());
    screen_name_label.label = "@" + tweet.get_screen_name ();
    if (tweet.avatar_url != null) {
      string avatar_url = tweet.avatar_url;
      if (this.get_scale_factor () == 2)
        avatar_url = avatar_url.replace ("_normal", "_bigger");
      avatar_image.surface = Twitter.get ().get_avatar (tweet.get_user_id (), avatar_url, (a) => {
        avatar_image.surface = a;
      }, 48 * this.get_scale_factor ());
    }
    avatar_image.verified = tweet.is_flag_set (Cb.TweetState.VERIFIED);
    text_label.label = tweet.get_trimmed_text (Settings.get_text_transform_flags ());
    update_time_delta ();
    if (tweet.retweeted_tweet != null) {
      rt_label.show ();
      rt_image.show ();
      var buff = new StringBuilder ();
      buff.append ("<span underline='none'><a href=\"@")
          .append (tweet.source_tweet.author.id.to_string ())
          .append ("/@")
          .append (tweet.source_tweet.author.screen_name)
          .append ("\" title=\"@")
          .append (tweet.source_tweet.author.screen_name)
          .append ("\">")
          .append (tweet.source_tweet.author.user_name)
          .append ("</a></span>");
      rt_label.label = buff.str;
    }

    if (tweet.quoted_tweet != null) {
      this.create_quote_grid ();
      quote_label.label = Cb.TextTransform.tweet (ref tweet.quoted_tweet,
                                                 Settings.get_text_transform_flags (),
                                                 0);
      quote_name.set_markup (tweet.quoted_tweet.author.user_name);
      quote_screen_name.label = "@" + tweet.quoted_tweet.author.screen_name;
    }

    retweet_button.active    =   tweet.is_flag_set (Cb.TweetState.RETWEETED);
    retweet_button.sensitive = !(tweet.is_flag_set (Cb.TweetState.PROTECTED) &&
                                 tweet.get_user_id () != account.id);

    favorite_button.active = tweet.is_flag_set (Cb.TweetState.FAVORITED);

    tweet.state_changed.connect (state_changed_cb);

    conversation_image.visible = (tweet.reply_id != 0);

    if (tweet.has_inline_media ()) {
      this.create_media_widget (tweet.is_flag_set (Cb.TweetState.NSFW));
      mm_widget.restrict_height = restrict_height;
      mm_widget.set_all_media (tweet.get_medias ());
      mm_widget.media_clicked.connect (media_clicked_cb);
      mm_widget.media_invalid.connect (media_invalid_cb);
      mm_widget.window = main_window;

      if (text_label.label.length == 0 && tweet.quoted_tweet == null) {
        if (this.media_stack == null)
          this.grid.child_set (mm_widget, "top-attach", 1);
        else
          this.grid.child_set (media_stack, "top-attach", 1);
      }

      if (tweet.is_flag_set (Cb.TweetState.NSFW))
        Settings.get ().changed["hide-nsfw-content"].connect (hide_nsfw_content_changed_cb);

      Settings.get ().changed["media-visibility"].connect (media_visibility_changed_cb);
      mm_widget.visible = (Settings.get_media_visiblity () == MediaVisibility.SHOW);
    }

    var actions = new GLib.SimpleActionGroup ();
    actions.add_action_entries (action_entries, this);
    this.insert_action_group ("tweet", actions);

    if (tweet.get_user_id () != account.id)
      ((GLib.SimpleAction)actions.lookup_action ("delete")).set_enabled (false);

    if (tweet.is_flag_set (Cb.TweetState.PROTECTED))
      ((GLib.SimpleAction)actions.lookup_action ("quote")).set_enabled (false);

    reply_tweet.connect (reply_tweet_activated);
    delete_tweet.connect (delete_tweet_activated);
    favorite_tweet.connect (() => {
      favorite_button.active = !favorite_button.active;
    });
    retweet_tweet.connect (() => {
      retweet_button.tap ();
    });

    if (tweet.is_flag_set (Cb.TweetState.FAVORITED))
      fav_status_image.show ();

    if (tweet.is_flag_set (Cb.TweetState.RETWEETED))
      rt_status_image.show ();

    values_set = true;

    // TODO All these settings signal connections with lots of tweets could be costly...
    Settings.get ().changed["text-transform-flags"].connect (transform_flags_changed_cb);
  }

  ~TweetListEntry () {
    Settings.get ().changed["text-transform-flags"].disconnect (transform_flags_changed_cb);

    if (tweet.is_flag_set (Cb.TweetState.NSFW) && this.media_stack != null)
      Settings.get ().changed["hide-nsfw-content"].disconnect (hide_nsfw_content_changed_cb);

    if (this.mm_widget != null)
      Settings.get ().changed["media-visibility"].disconnect (media_visibility_changed_cb);
  }

  private void media_visibility_changed_cb () {
    if (Settings.get_media_visiblity () == MediaVisibility.SHOW)
      this.mm_widget.show ();
    else
      this.mm_widget.hide ();
  }

  private void transform_flags_changed_cb () {
    text_label.label = tweet.get_trimmed_text (Settings.get_text_transform_flags ());
    if (this.tweet.quoted_tweet != null) {
      this.quote_label.label = Cb.TextTransform.tweet (ref tweet.quoted_tweet,
                                                       Settings.get_text_transform_flags (),
                                                       0);
    }

    if (this.mm_widget != null && this.tweet.quoted_tweet == null) {
      if (text_label.label.length == 0)
        this.grid.child_set (mm_widget, "top-attach", 1);
      else
        this.grid.child_set (mm_widget, "top-attach", 7);
    }
  }

  private void hide_nsfw_content_changed_cb () {
    assert (this.media_stack != null);

    if (this.tweet.is_flag_set (Cb.TweetState.NSFW) &&
        Settings.hide_nsfw_content ())
      this.media_stack.visible_child_name = "nsfw";
    else
      this.media_stack.visible_child = mm_widget;
  }

  private void media_clicked_cb (Cb.Media m, int index) {
    TweetUtils.handle_media_click (this.tweet, this.main_window, index);
  }

  private void delete_tweet_activated () {
    if (tweet.get_user_id () != account.id)
      return; // Nope.

    if (delete_first_activated) {
      TweetUtils.delete_tweet.begin (account, tweet, () => {
        sensitive = false;
      });
    } else
      delete_first_activated = true;
  }

  static construct {
    unowned Gtk.BindingSet binding_set = Gtk.BindingSet.by_class ((GLib.ObjectClass)typeof (TweetListEntry).class_ref ());

    Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.r, 0, "reply-tweet", 0, null);
    Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.d, 0, "delete-tweet", 0, null);
    Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.t, 0, "retweet-tweet", 0, null);
    Gtk.BindingEntry.add_signal (binding_set, Gdk.Key.f, 0, "favorite-tweet", 0, null);
  }

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
        message ("My retweet: %s", tweet.my_retweet.to_string ());
        message ("Retweeted: %s", tweet.is_flag_set (Cb.TweetState.RETWEETED).to_string ());
        message ("Favorited: %s", tweet.is_flag_set (Cb.TweetState.FAVORITED).to_string ());
        message ("Protected: %s", tweet.is_flag_set (Cb.TweetState.PROTECTED).to_string ());
        message ("State    : %s", tweet.state.to_string ());
        message ("Source tweet author id: %s", tweet.source_tweet.author.id.to_string ());
        message ("Source tweet author screen_name: %s", tweet.source_tweet.author.screen_name);
        if (tweet.retweeted_tweet != null) {
          message ("Retweet!");
          message ("Retweet author id: %s", tweet.retweeted_tweet.author.id.to_string ());
          message ("Retweet author screen_name: %s", tweet.retweeted_tweet.author.screen_name);
        }
        if (tweet.has_inline_media ()) {
          foreach (Cb.Media m in tweet.get_medias ()) {
            message ("Media: %p", m);
          }
        }
        return Gdk.EVENT_STOP;
    }
#endif
    return Gdk.EVENT_PROPAGATE;
  }

  /**
   * Retweets or un-retweets the tweet.
   */
  [GtkCallback]
  private void retweet_button_toggled_cb () {
    bool retweetable = tweet.get_user_id () == account.id ||
                       !tweet.is_flag_set (Cb.TweetState.PROTECTED);

    if (!retweetable || !values_set)
      return;

    retweet_button.sensitive = false;
    TweetUtils.set_retweet_status.begin (account, tweet, retweet_button.active, () => {
      retweet_button.sensitive = true;
    });
    if (shows_actions)
      toggle_mode ();
  }

  [GtkCallback]
  private void favorite_button_toggled_cb () {
    if (!values_set)
      return;

    favorite_button.sensitive = false;
    TweetUtils.set_favorite_status.begin (account, tweet, favorite_button.active, () => {
      favorite_button.sensitive = true;
    });
    if (shows_actions)
      toggle_mode ();
  }

  [GtkCallback]
  private void name_button_clicked_cb () {
    int64 user_id;
    string screen_name;

    if (tweet.retweeted_tweet != null) {
      user_id = tweet.retweeted_tweet.author.id;
      screen_name = tweet.retweeted_tweet.author.screen_name;
    } else {
      user_id = tweet.source_tweet.author.id;
      screen_name = tweet.source_tweet.author.screen_name;
    }

    var bundle = new Bundle ();
    bundle.put_int64 ("user_id", user_id);
    bundle.put_string ("screen_name", screen_name);
    main_window.main_widget.switch_page (Page.PROFILE, bundle);
  }

  private void quote_name_button_clicked_cb () {
    assert (tweet.quoted_tweet != null);
    var bundle = new Bundle ();
    bundle.put_int64 ("user_id", tweet.quoted_tweet.author.id);
    bundle.put_string ("screen_name", tweet.quoted_tweet.author.screen_name);
    main_window.main_widget.switch_page (Page.PROFILE, bundle);
  }


  [GtkCallback]
  private void reply_button_clicked_cb () {
    ComposeTweetWindow ctw = new ComposeTweetWindow (this.main_window, this.account, this.tweet,
                                                     ComposeTweetWindow.Mode.REPLY);
    ctw.show ();
    if (shows_actions)
      toggle_mode ();
  }

  private void show_media_clicked_cb () {
    media_stack.visible_child = mm_widget;
  }

  private void quote_activated () {
    ComposeTweetWindow ctw = new ComposeTweetWindow (this.main_window, this.account, this.tweet,
                                                     ComposeTweetWindow.Mode.QUOTE);
    ctw.show ();
    toggle_mode ();
  }

  private void reply_tweet_activated () {
    ComposeTweetWindow ctw = new ComposeTweetWindow (this.main_window, this.account, this.tweet,
                                                     ComposeTweetWindow.Mode.REPLY);
    ctw.show ();
  }

  private void delete_activated () {
    delete_first_activated = true;
    delete_tweet ();
    toggle_mode ();
  }

  [GtkCallback]
  private bool link_activated_cb (string uri) {
    if (this._read_only) {
      return false;
    }

    this.grab_focus ();

    return TweetUtils.activate_link (uri, main_window);
  }

  [GtkCallback]
  private void populate_popup_cb (Gtk.Label source, Gtk.Menu menu) {
    var link_text = source.get_current_uri ();
    if (link_text.has_prefix ("#")) {
      var item = new Gtk.MenuItem.with_label (_("Block %s").printf (link_text));
      item.show ();
      item.activate.connect (() => {
        Utils.create_persistent_filter (link_text, account);
        main_window.rerun_filters ();
      });
      menu.add (item);
    }
  }

  private void media_invalid_cb () {
    Cb.TransformFlags flags = Settings.get_text_transform_flags ()
                              & ~Cb.TransformFlags.REMOVE_MEDIA_LINKS;

    string new_text;
    if (tweet.retweeted_tweet != null)
      new_text = Cb.TextTransform.tweet (ref tweet.retweeted_tweet, flags, 0);
    else
      new_text = Cb.TextTransform.tweet (ref tweet.source_tweet, flags, 0);

    this.text_label.label = new_text;

    if (tweet.quoted_tweet != null) {
      string new_quote_text = Cb.TextTransform.tweet (ref tweet.quoted_tweet,
                                                      flags, 0);
      this.quote_label.label = new_quote_text;
    }
  }

  private void state_changed_cb () {
    this.values_set = false;
    this.fav_status_image.visible = tweet.is_flag_set (Cb.TweetState.FAVORITED);
    this.favorite_button.active = tweet.is_flag_set (Cb.TweetState.FAVORITED);

    this.retweet_button.active = tweet.is_flag_set (Cb.TweetState.RETWEETED);
    this.rt_status_image.visible = tweet.is_flag_set (Cb.TweetState.RETWEETED);

    if (tweet.is_flag_set (Cb.TweetState.DELETED)) {
      this.sensitive = false;
      stack.visible_child = grid;
    }

    this.values_set = true;
  }

  public void set_avatar (Cairo.Surface surface) {
    /* This should only ever be called from the settings page. */
    this.avatar_image.surface = surface;
  }


  /**
   * Updates the time delta label in the upper right
   *
   * @return The seconds between the current time and
   *         the time the tweet was created
   */
  public int update_time_delta (GLib.DateTime? now = null) {
    GLib.DateTime cur_time;
    if (now == null)
      cur_time = new GLib.DateTime.now_local ();
    else
      cur_time = now;

    GLib.DateTime then = new GLib.DateTime.from_unix_local (
                             tweet.retweeted_tweet != null ? tweet.retweeted_tweet.created_at :
                                                             tweet.source_tweet.created_at);
    time_delta_label.label = Utils.get_time_delta (then, cur_time);
    return (int)(cur_time.difference (then) / 1000.0 / 1000.0);
  }


  public void toggle_mode () {
    if (this._read_only)
      return;

    if (stack.visible_child == action_box) {
      stack.visible_child = grid;
      this.activatable = true;
    } else {
      stack.visible_child = action_box;
      this.activatable = false;
    }
  }


  private int64 start_time;
  private int64 end_time;

  private bool anim_tick (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
    int64 now = frame_clock.get_frame_time ();

    if (now > end_time) {
      this.opacity = 1.0;
      return false;
    }

    double t = (now - start_time) / (double)(end_time - start_time);

    t = ease_out_cubic (t);

    this.opacity = t;

    return true;
  }

  public void fade_in () {
    if (this.get_realized ()) {
      this.show ();
      return;
    }

    ulong realize_id = 0;
    realize_id = this.realize.connect (() => {
      this.start_time = this.get_frame_clock ().get_frame_time ();
      this.end_time = start_time + TRANSITION_DURATION;
      this.add_tick_callback (anim_tick);
      this.disconnect (realize_id);
    });

    this.show ();
  }

  private void create_media_widget (bool nsfw) {
    this.mm_widget = new MultiMediaWidget ();
    mm_widget.halign = Gtk.Align.FILL;
    mm_widget.hexpand = true;
    mm_widget.margin_top = 6;

    if (nsfw) {
      this.media_stack = new Gtk.Stack ();
      media_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
      media_stack.add (mm_widget);
      var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
      box.valign = Gtk.Align.CENTER;
      var label = new Gtk.Label (_("This tweet contains images marked as inappropriate"));
      label.margin_start = 12;
      label.margin_end = 12;
      label.wrap = true;
      label.wrap_mode = Pango.WrapMode.WORD_CHAR;
      box.add (label);

      var button = new Gtk.Button.with_label (_("Show anyway"));
      button.halign = Gtk.Align.CENTER;
      button.valign = Gtk.Align.CENTER;
      button.clicked.connect (show_media_clicked_cb);
      box.add (button);

      media_stack.add_named (box, "nsfw");
      media_stack.show_all ();
      if (Settings.hide_nsfw_content ())
        media_stack.visible_child_name = "nsfw";
      else
        media_stack.visible_child = mm_widget;

      if (this.tweet.quoted_tweet != null) {
        media_stack.margin_start = 12;
        this.quote_grid.attach (media_stack, 0, 2, 2, 1);
      } else {
        this.grid.attach (media_stack, 1, 6, 7, 1);
      }
    } else {
      /* We will never have to hide mm_widget */
      mm_widget.show_all ();

      if (this.tweet.quoted_tweet != null) {
        mm_widget.margin_start = 12;
        this.quote_grid.attach (mm_widget, 0, 2, 2, 1);
      } else {
        this.grid.attach (mm_widget, 1, 6, 7, 1);
      }
    }
  }



  private bool quote_link_activated_cb (string uri) {
    if (this._read_only) {
      return false;
    }

    this.grab_focus ();

    return TweetUtils.activate_link (uri, main_window);
  }

  private void create_quote_grid () {
    this.quote_grid = new Gtk.Grid ();
    quote_grid.margin_top = 6;
    quote_grid.get_style_context ().add_class ("quote");

    this.quote_name = new TextButton ();
    quote_name.halign = Gtk.Align.START;
    quote_name.valign = Gtk.Align.BASELINE;
    quote_name.margin_start = 12;
    quote_name.margin_end = 6;
    quote_name.margin_bottom = 4;
    quote_name.clicked.connect (quote_name_button_clicked_cb);
    quote_grid.attach (quote_name, 0, 0, 1, 1);

    this.quote_screen_name = new Gtk.Label ("");
    quote_screen_name.halign = Gtk.Align.START;
    quote_screen_name.valign = Gtk.Align.BASELINE;
    quote_screen_name.hexpand = true;
    quote_screen_name.get_style_context ().add_class ("dim-label");
    quote_grid.attach (quote_screen_name, 1, 0, 1, 1);

    this.quote_label = new Gtk.Label ("");
    quote_label.halign = Gtk.Align.START;
    quote_label.hexpand = true;
    quote_label.xalign = 0;
    quote_label.use_markup = true;
    quote_label.wrap = true;
    quote_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
    quote_label.track_visited_links = false;
    quote_label.margin_start = 12;
    quote_label.activate_link.connect (quote_link_activated_cb);
    quote_label.populate_popup.connect (populate_popup_cb);
    var attrs = new Pango.AttrList ();
    attrs.insert (Pango.attr_style_new (Pango.Style.ITALIC));
    quote_label.set_attributes (attrs);
    quote_grid.attach (quote_label, 0, 1, 2, 1);

    quote_grid.show_all ();
    this.grid.attach (quote_grid, 1, 3, 6, 1);
  }
}
