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

class TweetListEntry : ITwitterItem, Gtk.ListBoxRow {
  public int64 sort_factor{
    get{ return timestamp; }
  }
  private static GLib.Regex? hashtag_regex = null;
  private static GLib.Regex? user_regex    = null;
  private ImageOverlay avatar          = new ImageOverlay();
  private Label text                   = new Label("");
  private TextButton author_button;
  private Label screen_name            = new Label("");
  private Label time_delta             = new Label("");
  private InvisibilityBin rt_bin     = new InvisibilityBin();
  private ToggleButton retweet_button  = new ToggleButton();
  private ToggleButton favorite_button = new ToggleButton();
  private Box text_box         = new Box(Orientation.HORIZONTAL, 3);
  private unowned  MainWindow window;
  private Gtk.Menu more_menu;
  private Gtk.Button more_button;
  // Timestamp used for sorting
  public int64 timestamp;
  private int64 tweet_id;
  private Tweet tweet;
  public bool seen{get;set; default=true;}
  private Gtk.Box box = new Box(Orientation.HORIZONTAL, 5);
  private bool is_user_tweet = false;
  private unowned Account acc;


  public TweetListEntry(Tweet tweet, MainWindow? window, Account acc){
    this.window  = window;
    this.vexpand = false;
    this.hexpand = false;
    this.acc     = acc;


    if (hashtag_regex == null){
      try{
        hashtag_regex = new GLib.Regex("(^|\\s)#\\w+",
                                       RegexCompileFlags.OPTIMIZE);
        user_regex    = new GLib.Regex("@\\w+", RegexCompileFlags.OPTIMIZE);
      }catch(GLib.RegexError e){
        warning("Error while creating regexes: %s", e.message);
      }
    }

    this.timestamp = tweet.created_at;
    this.tweet_id  = tweet.id;
    this.tweet     = tweet;


    // If the tweet's avatar changed, also reset it in the widgets
    tweet.notify["avatar"].connect( () => {
      avatar.pixbuf = tweet.avatar;
      avatar.queue_draw();
    });


    // Set the correct CSS style class
    get_style_context().add_class("tweet");
    get_style_context().add_class("row");



    if (tweet.screen_name == acc.screen_name){
      get_style_context().add_class("user-tweet");
      is_user_tweet = true;
    }




    this.state_flags_changed.connect ((previous) => {
      Gtk.StateFlags flags = this.get_state_flags ();

      bool buttons_visible = (bool)(flags & (StateFlags.PRELIGHT | StateFlags.SELECTED));
      toggle_button_visibility (buttons_visible);
    });

    this.button_press_event.connect( (evt) => {
      if (evt.type == Gdk.EventType.@2BUTTON_PRESS) {
        message ("Implement inline replies");
      }
      return true;
    });


    var left_box = new Box(Orientation.VERTICAL, 3);
    avatar.set_valign(Align.START);
    if(tweet.verified)
      avatar.overlay_image = Twitter.verified_icon;
    avatar.pixbuf = tweet.avatar;
    left_box.pack_start(avatar, false, false);

    var status_box = new Box(Orientation.HORIZONTAL, 3);
    retweet_button.get_style_context().add_class("retweet-button");
    retweet_button.active = tweet.retweeted;
    if(!tweet.retweeted)
      retweet_button.no_show_all = true;
    retweet_button.set_tooltip_text("Retweet");
    retweet_button.toggled.connect(retweet_tweet);
    rt_bin.add(retweet_button);
    status_box.pack_start(rt_bin, false, false);

    favorite_button.get_style_context().add_class("favorite-button");
    favorite_button.active = tweet.favorited;
    if(!tweet.favorited)
      favorite_button.no_show_all = true;
    favorite_button.set_tooltip_text("Favorite");
    favorite_button.toggled.connect(favorite_tweet);

    status_box.pack_start(favorite_button, false, false);


    more_button = new Button();
    more_button.get_style_context().add_class("more-button");
    more_button.set_tooltip_text("More…");
    more_button.clicked.connect(more_button_clicked);
    more_button.no_show_all = true;
    status_box.pack_start(more_button, false, false);

    left_box.pack_start(status_box, true, false);
    box.pack_start(left_box, false, false);


    var right_box = new Box(Orientation.VERTICAL, 4);
    var top_box = new Box(Orientation.HORIZONTAL, 5);



    author_button = new TextButton(tweet.user_name);
    author_button.clicked.connect(() => {
      if(window != null){
        window.switch_page(MainWindow.PAGE_PROFILE,
                           ProfilePage.BY_ID, tweet.user_id);
      }else
        critical("main window instance is null!");
    });
    top_box.pack_start(author_button, false, false);
    screen_name.set_use_markup(true);
    screen_name.label = "<small>@%s</small>".printf(tweet.screen_name);
    screen_name.get_style_context().add_class("dim-label");
    screen_name.ellipsize = Pango.EllipsizeMode.END;
    top_box.pack_start(screen_name, false, false);


    time_delta.set_use_markup(true);
    update_time_delta();
    time_delta.set_alignment(1, 0.5f);
    time_delta.get_style_context().add_class("dim-label");
    time_delta.margin_right = 3;
    top_box.pack_end(time_delta, false, false);

    right_box.pack_start(top_box, false, true);

    if(tweet.reply_id != 0){
      var conv_button = new Button();
      conv_button.get_style_context().add_class("conversation-button");
      conv_button.set_tooltip_text("View Conversation");
      conv_button.vexpand = false;
      top_box.pack_end(conv_button, false, false);
    }


    // Also set User/Hashtag links
    string display_text = tweet.text;
    try {
      display_text = user_regex.replace(display_text, display_text.length, 0,
                                        "<a href='\\0'>\\0</a>");
      display_text = hashtag_regex.replace(display_text, display_text.length, 0,
                                           "<a href='\\0'>\\0</a>");
    } catch (GLib.RegexError e) {
      warning (e.message);
    }
    display_text = Tweet.replace_links(display_text);
    text.label = display_text;
    text.set_use_markup(true);
    text.set_line_wrap(true);
    text.wrap_mode = Pango.WrapMode.WORD_CHAR;
    text.set_alignment(0, 0);
    text.activate_link.connect(handle_uri);
    text_box.pack_start(text, true, true);


    right_box.pack_start(text_box, true, true);

    box.pack_start(right_box, true, true);

    tweet.inline_media_added.connect((pic) => {
      add_inline_media(text_box);
    });
    // If the has_inline_media flag is already set, add the inline media immediately
    if(tweet.has_inline_media) {
      add_inline_media(text_box);
    }

    if(tweet.is_retweet) {
      // TODO: Use rt image here
      var rt_label = new Label("<small>RT by "+tweet.retweeted_by+"</small>");
      rt_label.set_use_markup(true);
      rt_label.set_justify(Justification.RIGHT);
      rt_label.set_halign(Align.END);
      rt_label.set_valign(Align.START);
      rt_label.margin_bottom = 4;
      rt_label.get_style_context().add_class("dim-label");
      right_box.pack_end(rt_label, true, true);
    }

    DeltaUpdater.get().add(this);

    this.set_size_request(20, 80);
    this.add(box);
    this.show_all();
  }

  private void add_inline_media(Box box) {
    Gdk.Pixbuf pic = null;
    try {
      pic = new Gdk.Pixbuf.from_file(tweet.media_thumb);
    } catch (GLib.Error e) {
      critical (e.message);
    }
    var media_button = new ImageButton();
    media_button.set_bg(pic);
    media_button.visible = true;
    media_button.vexpand = false;
    media_button.set_valign(Align.START);
    media_button.clicked.connect(() => {
      ImageDialog id = new ImageDialog(window, tweet.media);
      id.show_all();
    });
    media_button.show_all();
    box.pack_start(media_button, false, false);
  }

  /**
   * Updates the time delta label in the upper right
   *
   * @return The seconds between the current time and
   *         the time the tweet was created
   */
  public int update_time_delta() {
    GLib.DateTime now = new GLib.DateTime.now_local();
    GLib.DateTime then = new GLib.DateTime.from_unix_local(
      tweet.is_retweet ? tweet.rt_created_at : tweet.created_at);
    string link = "https://twitter.com/%s/status/%s".printf(tweet.screen_name,
                                                            tweet.id.to_string());
    this.time_delta.label = "<small><a href='%s' title='Open in Browser'>%s</a></small>"
                  .printf(link, Utils.get_time_delta(then, now));
    return (int)(now.difference(then) / 1000.0 / 1000.0);
  }

  private void favorite_tweet() {
    var spinner = new Spinner();
    spinner.start();
    WidgetReplacer.replace_tmp(favorite_button, spinner);

    var call = acc.proxy.new_call();
    if(favorite_button.active)
      call.set_function("1.1/favorites/create.json");
    else
      call.set_function("1.1/favorites/destroy.json");
    call.set_method("POST");
    call.add_param("id", tweet_id.to_string());
    call.invoke_async.begin(null, (obj, res) => {
      try{
        call.invoke_async.end(res);
      } catch (GLib.Error e) {
        critical(e.message);
      }

      try{
        Corebird.db.execute(@"UPDATE `cache` SET `favorited`='%d'
                            WHERE `id`='$tweet_id';"
                            .printf(favorite_button.active ? 1 : 0));
      } catch(SQLHeavy.Error e) {
        critical(e.message);
      }
      WidgetReplacer.replace_tmp_back(favorite_button);
    });
  }

  /**
   * (Un)retweets the tweet that is saved in this ListEntry.
   */
  private void retweet_tweet() {
    var spinner = new Spinner();
    spinner.start();
    WidgetReplacer.replace_tmp(retweet_button, spinner);

    var call = acc.proxy.new_call();
    call.set_method("POST");

    if(retweet_button.active) {
      call.set_function(@"1.1/statuses/retweet/$tweet_id.json");
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

        try{
          Corebird.db.execute(@"UPDATE `cache` SET `retweeted`='1',
                              `rt_id`='$new_id'
                              WHERE `id`='$tweet_id';");

        }catch (SQLHeavy.Error e) {
          critical(e.message);
        }
        tweet.rt_id = new_id;
        WidgetReplacer.replace_tmp_back(retweet_button);
      });
    } else {
      call.set_function("1.1/statuses/destroy/%s.json"
                        .printf(tweet.rt_id.to_string()));
      call.invoke_async.begin(null, (obj, res) => {
        try {
          call.invoke_async.end(res);
        } catch (GLib.Error e) {
          Utils.show_error_dialog(e.message);
          critical(e.message);
        }
        try{
          Corebird.db.execute(@"UPDATE `cache` SET `retweeted`='0'
                              WHERE `id`='$tweet_id';");
        }catch (SQLHeavy.Error e) {
          critical(e.message);
        }
        WidgetReplacer.replace_tmp_back(retweet_button);
      });
    }
  }



  public override bool draw(Cairo.Context c){
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


  /**
  * Handle uris in the tweets
  */
  private bool handle_uri(string uri){
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

  private void more_button_clicked() {
    if(more_menu == null)
      construct_more_menu();


    more_menu.popup(null, null, null, 0, 0);
  }

  private void construct_more_menu() {
    more_menu = new Gtk.Menu();

    Gtk.MenuItem reply_item = new Gtk.MenuItem.with_label("Reply");
    reply_item.activate.connect(() => {
      var compose_win = new ComposeTweetWindow(window, acc, tweet,
                                               window.get_application());
      compose_win.show_all();
    });
    more_menu.add(reply_item);
    Gtk.MenuItem details_item = new Gtk.MenuItem.with_label("Details");
    more_menu.add(details_item);

    more_menu.show_all();
  }

  private void toggle_button_visibility (bool visible) {
    if (visible) {
      favorite_button.show();
      rt_bin.show_child();
      more_button.show();
    } else {
      if(!favorite_button.active)
        favorite_button.hide();
      if(!retweet_button.active)
        rt_bin.hide_child();
      more_button.hide();
    }
  }
}
