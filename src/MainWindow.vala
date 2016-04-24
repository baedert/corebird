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

[GtkTemplate (ui = "/org/baedert/corebird/ui/main-window.ui")]
public class MainWindow : Gtk.ApplicationWindow {
  private const GLib.ActionEntry[] win_entries = {
    {"compose-tweet",       show_hide_compose_window},
    {"toggle-sidebar",      Settings.toggle_sidebar_visible},
    {"switch-page",         simple_switch_page, "i"},
    {"show-account-dialog", show_account_dialog},
    {"show-account-list",   show_account_list},
    {"previous",            previous},
    {"next",                next}
  };
  [GtkChild]
  private Gtk.HeaderBar headerbar;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.ListBox account_list;
  [GtkChild]
  private Gtk.Popover account_popover;
  [GtkChild]
  private Gtk.Box header_box;
  [GtkChild]
  private Gtk.ToggleButton account_button;
  [GtkChild]
  public Gtk.Button back_button;
  [GtkChild]
  public Gtk.ToggleButton compose_tweet_button;
  [GtkChild]
  private Gtk.Label title_label;
  [GtkChild]
  private Gtk.Label last_page_label;
  [GtkChild]
  private Gtk.Stack title_stack;

  private Gtk.MenuButton app_menu_button = null;
  public MainWidget main_widget;
  public unowned Account? account;
  private ComposeTweetWindow? compose_tweet_window = null;

  public int cur_page_id {
    get {
      return main_widget.cur_page_id;
    }
  }

  public MainWindow (Gtk.Application app, Account? account = null) {
    set_default_size (480, 700);

#if DEBUG
    this.set_focus.connect ((w) => {
      debug ("Focus widget now: %s %p", w != null ? __class_name (w) : "(null)", w);
    });
#endif
    change_account (account);

    account_list.set_sort_func (account_sort_func);
    account_list.set_header_func (default_header_func);
    var add_entry = new AddListEntry (_("Add new Account"));
    add_entry.show_all ();
    account_list.add (add_entry);

    for (uint i = 0; i < Account.get_n (); i ++) {
      var acc = Account.get_nth (i);
      if (acc.screen_name == Account.DUMMY)
          continue;
      var e = new UserListEntry.from_account (acc);
      e.show_settings = true;
      e.action_clicked.connect (() => { account_popover.hide ();});
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
      ule.action_clicked.connect (() => { account_popover.hide ();});
      account_list.add (ule);
      ule.show ();
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
      if (evt.keyval == Gdk.Key.Down && main_widget != null) {
        main_widget.get_page (main_widget.cur_page_id).focus (Gtk.DirectionType.RIGHT);
        return true;
      }
      return false;
    });

    load_geometry ();
  }

  [GtkCallback]
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

    if (!header_box.visible) {
      header_box.visible = true;
    }

    Corebird cb = (Corebird) GLib.Application.get_default ();

    if (account != null && account.screen_name != Account.DUMMY) {
      main_widget = new MainWidget (account, this, cb);
      main_widget.show_all ();
      this.add (main_widget);
      main_widget.switch_page (0);
      this.set_window_title (main_widget.get_page (0).get_title ());
      avatar_image.surface = account.avatar_small;
      account.notify["avatar-small"].connect(() => {
        avatar_image.surface = account.avatar_small;
      });

      account.info_changed.connect (account_info_changed);

      cb.account_window_changed (old_user_id, account.id);

      if (!Gtk.Settings.get_default ().gtk_shell_shows_app_menu) {
        if (app_menu_button == null) {
          app_menu_button = new Gtk.MenuButton ();
          app_menu_button.image = new Gtk.Image.from_icon_name ("emblem-system-symbolic", Gtk.IconSize.MENU);
          app_menu_button.get_style_context ().add_class ("image-button");
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

      this.set_title (_("Corebird"));

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

  [GtkCallback]
  private void account_row_activated_cb (Gtk.ListBoxRow row) {
    if (row is AddListEntry) {
      account_popover.hide ();
      Account dummy_acc = new Account (0, Account.DUMMY, "name");
      var window = new MainWindow (application, dummy_acc);
      get_application ().add_window (window);
      window.show_all ();
      return;
    }
    var e = (UserListEntry)row;
    int64 user_id = e.user_id;
    Corebird cb = (Corebird)this.get_application ();

    if (user_id == this.account.id ||
        cb.is_window_open_for_user_id (user_id)) {
      account_popover.hide ();
      return;
    }

    Account? acc = Account.query_account_by_id (user_id);
    if (acc != null) {
      change_account (acc);
      account_popover.hide ();
    } else
      warning ("account == null");
  }


  [GtkCallback]
  private bool button_press_event_cb (Gdk.EventButton evt) {
    if (evt.button == 9) {
      // Forward thumb button
      main_widget.switch_page (Page.NEXT);
      return Gdk.EVENT_STOP;
    } else if (evt.button == 8) {
      // backward thumb button
      main_widget.switch_page (Page.PREVIOUS);
      return Gdk.EVENT_STOP;
    }
    return Gdk.EVENT_PROPAGATE;
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
    if (this.account != null && this.account.screen_name != Account.DUMMY)
      this.account_popover.show ();
  }

  public IPage get_page (int page_id) {
    return main_widget.get_page (page_id);
  }

  [GtkCallback]
  private void account_button_clicked_cb () {
    account_popover.visible = !account_popover.visible;
  }

  [GtkCallback]
  private void account_popover_closed_cb () {
    account_button.active = false;
    account_popover.hide ();
  }

  [GtkCallback]
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
}
