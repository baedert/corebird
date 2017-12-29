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

public class MainWindow : Gtk.ApplicationWindow {
  private const GLib.ActionEntry[] win_entries = {
    {"compose-tweet",       show_hide_compose_window},
    {"toggle-topbar",       Settings.toggle_topbar_visible},
    {"switch-page",         simple_switch_page, "i"},
    {"show-account-dialog", show_account_dialog},
    {"show-account-list",   show_account_list},
    {"previous",            previous},
    {"next",                next}
  };
  private Gtk.HeaderBar headerbar;
  private AvatarWidget avatar_image;
  private Gtk.ListBox account_list;
  private Gtk.Popover account_popover;
  private Gtk.Box header_box;
  private Gtk.ToggleButton account_button;
  private Gtk.Label title_label;
  private Gtk.Label last_page_label;
  private Gtk.Stack title_stack;
  public Gtk.Button back_button;
  public Gtk.ToggleButton compose_tweet_button;

  private Gtk.MenuButton app_menu_button = null;
  public MainWidget main_widget;
  public unowned Account? account;
  private ComposeTweetWindow? compose_tweet_window = null;
  private Gtk.GestureMultiPress thumb_button_gesture;

  public int cur_page_id {
    get {
      return main_widget.cur_page_id;
    }
  }

  public MainWindow (Gtk.Application app, Account? account = null) {
    set_default_size (530, 700);

    var group = new Gtk.WindowGroup ();
    group.add_window (this);

#if DEBUG
    this.set_focus.connect ((w) => {
      debug ("Focus widget now: %s %p", w != null ? __class_name (w) : "(null)", w);
    });
#endif


    /* Create widgets */
    this.set_show_menubar (false);
    this.set_icon_name ("corebird");
    this.delete_event.connect (window_delete_cb);

    this.headerbar = new Gtk.HeaderBar ();
    headerbar.set_title ("Corebird");
    headerbar.set_show_title_buttons (true);

    this.title_stack = new Gtk.Stack ();
    this.title_label = new Gtk.Label ("");
    title_label.set_ellipsize (Pango.EllipsizeMode.MIDDLE);
    title_label.get_style_context ().add_class ("title");
    title_stack.add (title_label);
    this.last_page_label = new Gtk.Label ("");
    last_page_label.set_ellipsize (Pango.EllipsizeMode.MIDDLE);
    last_page_label.get_style_context ().add_class ("title");
    title_stack.add (last_page_label);
    headerbar.set_custom_title (title_stack);

    this.header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    this.account_button = new Gtk.ToggleButton ();
    account_button.set_tooltip_text (_("Show configured accounts"));
    account_button.clicked.connect (account_button_clicked_cb);
    account_button.get_style_context ().add_class ("account-button");
    this.avatar_image = new AvatarWidget ();
    avatar_image.size = 24;
    avatar_image.set_valign (Gtk.Align.CENTER);
    account_button.add (avatar_image);
    header_box.add (account_button);
    this.compose_tweet_button = new Gtk.ToggleButton ();
    compose_tweet_button.add (new Gtk.Image.from_icon_name ("corebird-compose-symbolic"));
    compose_tweet_button.set_tooltip_text (_("Compose Tweet"));
    compose_tweet_button.set_action_name ("win.compose-tweet");
    header_box.add (compose_tweet_button);
    this.back_button = new Gtk.Button.from_icon_name ("go-previous-symbolic");
    back_button.clicked.connect (back_button_clicked_cb);
    header_box.add (back_button);
    headerbar.pack_start (header_box);
    this.set_titlebar (headerbar);

    this.account_popover = new Gtk.Popover (account_button);
    account_popover.closed.connect (account_popover_closed_cb);
    var frame = new Gtk.Frame (null);
    frame.set_margin_start (6);
    frame.set_margin_end (6);
    frame.set_margin_top (6);
    frame.set_margin_bottom (6);
    this.account_list = new Gtk.ListBox ();
    account_list.set_selection_mode (Gtk.SelectionMode.NONE);
    account_list.row_activated.connect (account_row_activated_cb);
    frame.add (account_list);
    account_popover.add (frame);

    change_account (account);

    account_list.set_sort_func (account_sort_func);
    account_list.set_header_func (default_header_func);
    var add_entry = new AddListEntry (_("Add new Account"));
    account_list.add (add_entry);

    for (uint i = 0; i < Account.get_n (); i ++) {
      var acc = Account.get_nth (i);
      if (acc.screen_name == Account.DUMMY)
          continue;
      var e = new UserListEntry.from_account (acc);
      e.action_clicked.connect (() => {
        account_popover.popdown ();
      });
      account_list.add (e);
    }

    ((Corebird)app).account_added.connect ((new_acc) => {
      var entries = account_list.get_children ();
      foreach (Gtk.Widget ule in entries)
        if (ule is UserListEntry &&
            new_acc.screen_name == ((UserListEntry)ule).screen_name)
          return;

      var ule = new UserListEntry.from_account (new_acc);
      ule.show_settings = true;
      ule.action_clicked.connect (() => {
        account_popover.popdown ();
      });
      account_list.add (ule);
    });

    ((Corebird)app).account_removed.connect ((acc) => {
      var entries = account_list.get_children ();
      foreach (Gtk.Widget ule in entries)
        if (ule is UserListEntry &&
            acc.screen_name == ((UserListEntry)ule).screen_name) {
          account_list.remove (ule);
          break;
        }
    });

    this.add_action_entries (win_entries, this);


    headerbar.key_press_event.connect ((evt) => {
      uint keyval;

      evt.get_keyval (out keyval);

      if (keyval == Gdk.Key.Down && main_widget != null) {
        main_widget.get_page (main_widget.cur_page_id).focus (Gtk.DirectionType.RIGHT);
        return true;
      }
      return false;
    });

    this.thumb_button_gesture = new Gtk.GestureMultiPress (this);
    thumb_button_gesture.set_button (0);
    thumb_button_gesture.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
    thumb_button_gesture.pressed.connect (thumb_button_pressed_cb);

    load_geometry ();
  }

  private void back_button_clicked_cb () {
    main_widget.switch_page (Page.PREVIOUS);
  }

  public void change_account (Account? account) {
    int64? old_user_id = null;
    if (this.account != null) {
      old_user_id = this.account.id;
      this.account.info_changed.disconnect (account_info_changed);
    }
    this.account = account;

    if (main_widget != null) {
      main_widget.stop ();
    }

    if (get_child () != null) {
      remove (get_child ());
    }

    Corebird cb = (Corebird) GLib.Application.get_default ();

    if (account != null && account.screen_name != Account.DUMMY) {
      header_box.show ();
      main_widget = new MainWidget (account, this, cb);
      this.add (main_widget);
      main_widget.switch_page (0);
      this.set_window_title (main_widget.get_page (0).get_title ());
      avatar_image.surface = account.avatar_small;
      account.notify["avatar-small"].connect(() => {
        avatar_image.surface = this.account.avatar_small;
      });

      account.info_changed.connect (account_info_changed);
      this.set_title ("Corebird - @%s".printf (account.screen_name));

      cb.account_window_changed (old_user_id, account.id);

      if (!Gtk.Settings.get_default ().gtk_shell_shows_app_menu) {
        if (app_menu_button == null) {
          app_menu_button = new Gtk.MenuButton ();
          app_menu_button.set_icon_name ("emblem-system-symbolic");
          app_menu_button.menu_model = cb.app_menu;
          headerbar.pack_end (app_menu_button);
        } else
          app_menu_button.show ();
      }
    } else {
      /* "Special case" when creating a new account */
      header_box.hide ();
      if (app_menu_button != null)
        app_menu_button.hide ();

      Account acc_;
      if (account == null)
        acc_ = new Account (0, Account.DUMMY, "name");
      else
        acc_ = account;

      this.account = acc_;

      this.title_label.label = "Corebird";
      this.set_title ("Corebird");

      Account.add_account (acc_);
      var create_widget = new AccountCreateWidget (acc_, cb, this);
      create_widget.result_received.connect ((result, acc) => {
        if (result) {
          change_account (acc);
        } else {
          //Account.remove ("screen_name");
        }
      });
      this.add (create_widget);
    }

  }

  private void account_row_activated_cb (Gtk.ListBoxRow row) {
    if (row is AddListEntry) {
      account_popover.popdown ();
      Account dummy_acc = new Account (0, Account.DUMMY, "name");
      var window = new MainWindow (application, dummy_acc);
      get_application ().add_window (window);
      window.show ();
      return;
    }
    var e = (UserListEntry)row;
    int64 user_id = e.user_id;
    Corebird cb = (Corebird)this.get_application ();

    MainWindow? account_window = null;
    if (user_id == this.account.id ||
        cb.is_window_open_for_user_id (user_id, out account_window)) {
      account_popover.popdown ();

      if (account_window != null)
        account_window.present ();

      return;
    }

    Account? acc = Account.query_account_by_id (user_id);
    if (acc != null) {
      change_account (acc);
      account_popover.popdown ();
    } else
      warning ("account == null");
  }

  private void thumb_button_pressed_cb (Gtk.GestureMultiPress gesture,
                                        int                   n_press,
                                        double                x,
                                        double                y) {
    uint button = gesture.get_current_button ();
    if (button == 9) {
      // Forward thumb button
      main_widget.switch_page (Page.NEXT);
      gesture.set_state (Gtk.EventSequenceState.CLAIMED);
    } else if (button == 8) {
      // backward thumb button
      main_widget.switch_page (Page.PREVIOUS);
      gesture.set_state (Gtk.EventSequenceState.CLAIMED);
    }
  }

  private void show_hide_compose_window () {
    if (this.account == null ||
        this.account.screen_name == Account.DUMMY)
      return;

    if (compose_tweet_window == null) {
      compose_tweet_window = new ComposeTweetWindow (this, account, null,
                                                     ComposeTweetWindow.Mode.NORMAL);
      compose_tweet_window.show ();
      compose_tweet_window.hide.connect (() => {
        compose_tweet_button.active = false;
      });

      compose_tweet_window.destroy.connect (() => {
        compose_tweet_window = null;
      });
    } else {
      compose_tweet_window.hide ();
      compose_tweet_window.destroy ();
    }
  }

  /**
   * GSimpleActionActivateCallback version of switch_page, used
   * for keyboard accelerators.
   */
  private void simple_switch_page (GLib.SimpleAction a, GLib.Variant? param) {
    main_widget.switch_page (param.get_int32 ());
  }

  private void previous (GLib.SimpleAction a, GLib.Variant? param) {
    if (this.account == null ||
        this.account.screen_name == Account.DUMMY)
      return;

    main_widget.switch_page (Page.PREVIOUS);
  }

  private void next (GLib.SimpleAction a, GLib.Variant? param) {
    if (this.account == null ||
        this.account.screen_name == Account.DUMMY)
      return;

    main_widget.switch_page (Page.NEXT);
  }

  /* result of the show-account-dialog GAction */
  private void show_account_dialog () {
    if (this.account == null ||
        this.account.screen_name == Account.DUMMY)
      return;

    var dialog = new AccountDialog (this.account);
    dialog.set_transient_for (this);
    dialog.modal = true;
    dialog.show ();
  }

  /* for show-account-list GAction */
  private void show_account_list () {
    if (this.account != null && this.account.screen_name != Account.DUMMY) {
      this.account_popover.popup ();
    }
  }

  public IPage get_page (int page_id) {
    return main_widget.get_page (page_id);
  }

  private void account_button_clicked_cb () {
    if (account_popover.visible) {
      account_popover.popdown ();
    } else {
      account_popover.popup ();
    }
  }

  private void account_popover_closed_cb () {
    account_button.active = false;
  }

  private bool window_delete_cb (Gdk.EventAny evt) {
    if (main_widget != null)
      main_widget.stop ();

    if (account == null)
      return Gdk.EVENT_PROPAGATE;

    unowned GLib.List<weak Gtk.Window> ws = this.application.get_windows ();
    debug("Windows: %u", ws.length ());

    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    if (startup_accounts.length == 1 && startup_accounts[0] == "")
      startup_accounts.resize (0);

    save_geometry ();

    if (startup_accounts.length > 0)
      return Gdk.EVENT_PROPAGATE;

    int n_main_windows = 0;
    foreach (Gtk.Window win in ws)
      if (win is MainWindow &&
          ((MainWindow) win).account != null &&
          ((MainWindow) win).account.screen_name != Account.DUMMY)
        n_main_windows ++;


    if (n_main_windows == 1) {
      // This is the last window so we save this one anyways...
      string[] new_startup_accounts = new string[1];
      new_startup_accounts[0] = ((MainWindow)ws.nth_data (0)).account.screen_name;
      Settings.get ().set_strv ("startup-accounts", new_startup_accounts);
      debug ("Saving the account %s", ((MainWindow)ws.nth_data (0)).account.screen_name);
    }
    return Gdk.EVENT_PROPAGATE;
  }


  private void account_info_changed (string        screen_name,
                                     string        name,
                                     Cairo.Surface small_avatar,
                                     Cairo.Surface avatar) {
    this.set_window_title (main_widget.get_page (main_widget.cur_page_id).get_title ());
    this.set_title ("Corebird - @%s".printf (screen_name));
  }

  /**
   *
   */
  private void load_geometry () {
    if (account == null || account.screen_name == Account.DUMMY) {
      debug ("Could not load geometry, account == null");
      return;
    }
    GLib.Variant win_geom = Settings.get ().get_value ("window-geometry");
    int x = 0,
        y = 0,
        w = 0,
        h = 0;

    if (!win_geom.lookup (account.screen_name, "(iiii)", &x, &y, &w, &h)) {
      warning ("Couldn't load window geometry for screen_name `%s'", account.screen_name);
      return;
    }

    if (w == 0 || h == 0)
      return;

    move (x, y);
    this.set_default_size (w, h);
  }

  /**
   * Saves this window's geometry in the window-geometry gsettings key.
   */
  public void save_geometry () {
    if (account == null || account.screen_name == Account.DUMMY)
      return;

    GLib.Variant win_geom = Settings.get ().get_value ("window-geometry");
    GLib.Variant new_geom;
    GLib.VariantBuilder builder = new GLib.VariantBuilder (new GLib.VariantType("a{s(iiii)}"));
    var iter = win_geom.iterator ();
    string? key = null;
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    while (iter.next ("{s(iiii)}", &key, &x, &y, &w, &h)) {
      if (key != account.screen_name) {
        builder.add ("{s(iiii)}", key, x, y, w, h);
      }
      key = null; // Otherwise we leak key
    }
    /* Finally, add this window */
    this.get_position (out x, out y);
    this.get_size (out w, out h);
    builder.add ("{s(iiii)}", account.screen_name, x, y, w, h);
    new_geom = builder.end ();
    debug ("Saving geomentry for %s: %d,%d,%d,%d", account.screen_name, x, y, w, h);

    Settings.get ().set_value ("window-geometry", new_geom);
  }

  private int account_sort_func (Gtk.ListBoxRow a,
                                 Gtk.ListBoxRow b) {
    if (a is AddListEntry)
      return 1;

    return ((UserListEntry)a).screen_name.ascii_casecmp (((UserListEntry)b).screen_name);
  }

  public void rerun_filters () {
    /* We only do this for stream + mentions at the moment */
    ((DefaultTimeline)get_page (Page.STREAM)).rerun_filters ();
    ((DefaultTimeline)get_page (Page.MENTIONS)).rerun_filters ();
  }

  public void set_window_title (string title,
                                Gtk.StackTransitionType transition_type = Gtk.StackTransitionType.NONE) {
    this.last_page_label.label = this.title_label.label;
    this.title_stack.transition_type = Gtk.StackTransitionType.NONE;
    this.title_stack.visible_child = last_page_label;

    this.title_stack.transition_type = transition_type;
    this.title_label.label = title;
    this.title_stack.visible_child = title_label;
  }

  public void reply_to_tweet (int64 tweet_id) {
    Cb.Tweet? tweet = null;
    tweet = ((DefaultTimeline)this.main_widget.get_page(Page.STREAM)).tweet_list.model.get_for_id (tweet_id,
                                                                                                   0);
    if (tweet == null) {
      warning ("tweet with id %s could not be found", tweet_id.to_string ());
      return;
    }

    var ctw = new ComposeTweetWindow (this, this.account, tweet,
                                      ComposeTweetWindow.Mode.REPLY);
    ctw.show ();
  }

  public void mark_tweet_as_read (int64 tweet_id) {
    DefaultTimeline home_timeline     = ((DefaultTimeline)this.main_widget.get_page(Page.STREAM));
    DefaultTimeline mentions_timeline = ((DefaultTimeline)this.main_widget.get_page(Page.MENTIONS));
    Cb.Tweet? tweet = null;
    tweet = home_timeline.tweet_list.model.get_for_id (tweet_id,
                                                       0);
    if (tweet != null) {
      tweet.set_seen (true);
      home_timeline.unread_count --;
    }

    // and now with the MentionsTimeline
    tweet = mentions_timeline.tweet_list.model.get_for_id (tweet_id,
                                                           0);
    if (tweet != null) {
      tweet.set_seen (true);
      mentions_timeline.unread_count --;
    }
  }
}
