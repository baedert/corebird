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
    {"compose_tweet",  show_compose_window},
    {"toggle_sidebar", Settings.toggle_sidebar_visible},
    {"switch_page",    simple_switch_page, "i"}
  };
  [GtkChild]
  private Gtk.HeaderBar headerbar;
  [GtkChild]
  private Gtk.Image avatar_image;
  [GtkChild]
  private Gtk.ListBox account_list;
  [GtkChild]
  private Gtk.Popover account_popover;
  [GtkChild]
  private Gtk.Box header_box;

  private Gtk.MenuButton app_menu_button = null;
  public MainWidget main_widget;
  public unowned Account account  {public get; private set;}

  public int cur_page_id {
    get {
      return main_widget.cur_page_id;
    }
  }



  public MainWindow(Gtk.Application app, Account? account = null){
    GLib.Object (application: app);
    set_default_size (480, 700);

    if (account != null && account.screen_name != Account.DUMMY) {
      change_account (account);
    } else {
      header_box.hide ();
      if (app_menu_button != null)
        app_menu_button.hide ();

      Account acc_;
      if (account == null)
        acc_ = new Account (0, Account.DUMMY, "name");
      else
        acc_ = account;

      Account.add_account (acc_);
      var create_widget = new AccountCreateWidget (acc_);
      create_widget.margin_top = 50;
      create_widget.margin_bottom = 20;
      create_widget.result_received.connect ((result, acc) => {
        if (result) {
          change_account (acc);
        } else {
          //Account.remove ("screen_name");
        }
      });
      this.add (create_widget);
    }

    foreach (Account acc in Account.list_accounts ()) {
      var e = new UserListEntry.from_account (acc);
      account_list.add (e);
    }


    this.add_action_entries (win_entries, this);

    add_accels();
    load_geometry ();
    show_all ();
  }

  /**
   * Adds the accelerators to the GtkWindow
   * XXX We can't use gtk_application_set_accels_for_action because the binding is broken in vala-0.24
   */
  private void add_accels() { // {{{
    Gtk.AccelGroup ag = new Gtk.AccelGroup();

    ag.connect (Gdk.Key.Left, Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.LOCKED,
        () => {main_widget.switch_page (Page.PREVIOUS); return true;});
    ag.connect (Gdk.Key.Right, Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.LOCKED,
        () => {main_widget.switch_page (Page.NEXT); return true;});
    ag.connect (Gdk.Key.Back, 0, Gtk.AccelFlags.LOCKED,
        () => {main_widget.switch_page (Page.PREVIOUS); return true;});
    ag.connect (Gdk.Key.Forward, 0, Gtk.AccelFlags.LOCKED,
        () => {main_widget.switch_page (Page.NEXT); return true;});

    this.add_accel_group(ag);
  } // }}}



  private void change_account (Account account) {
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

    main_widget = new MainWidget (account, this, (Corebird)this.application);
    main_widget.show_all ();
    this.add (main_widget);
    headerbar.set_subtitle ("@" + account.screen_name);
    avatar_image.pixbuf = account.avatar_small;
    account.notify["avatar_small"].connect(() => {
      avatar_image.pixbuf = account.avatar_small;
    });

    if (!Gtk.Settings.get_default ().gtk_shell_shows_app_menu) {
      if (app_menu_button == null) {
        app_menu_button = new Gtk.MenuButton ();
        app_menu_button.image = new Gtk.Image.from_icon_name ("emblem-system-symbolic", Gtk.IconSize.MENU);
        app_menu_button.get_style_context ().add_class ("image-button");
        app_menu_button.menu_model = this.application.app_menu;
        app_menu_button.set_relief (Gtk.ReliefStyle.NONE);
        headerbar.pack_end (app_menu_button);
      } else
        app_menu_button.show ();
    }

  }

  [GtkCallback]
  private void account_row_activated_cb (Gtk.ListBoxRow row) {
    var e = (UserListEntry)row;
    string screen_name = e.screen_name.substring(1);

    if (screen_name == this.account.screen_name) {
      account_popover.hide ();
      return;
    }

    Account? acc = Account.query_account (screen_name);
    if (acc != null) {
      change_account (acc);
      account_popover.hide ();
    }
  }


  [GtkCallback]
  private bool button_press_event_cb (Gdk.EventButton evt) {
    if (evt.button == 9) {
      // Forward thumb button
      main_widget.switch_page (Page.NEXT);
      return true;
    } else if (evt.button == 8) {
      // backward thumb button
      main_widget.switch_page (Page.PREVIOUS);
      return true;
    }
    return false;
  }

  private void show_compose_window () {
    var cw = new ComposeTweetWindow(this, account, null,
                                    ComposeTweetWindow.Mode.NORMAL,
                                    get_application ());
    cw.show();
  }


  /**
   * GSimpleActionActivateCallback version of switch_page, used
   * for keyboard accelerators.
   */
  private void simple_switch_page (GLib.SimpleAction a, GLib.Variant? param) {
    main_widget.switch_page (param.get_int32 ());
  }

  /**
   * Indicates that the caller is doing a long-running operation.
   */
  public void start_progress () {
    main_widget.start_progress ();
  }

  public void stop_progress () {
    main_widget.stop_progress ();
  }


  public IPage get_page (int page_id) {
    return main_widget.get_page (page_id);
  }

  [GtkCallback]
  private void account_button_clicked_cb () {
    account_popover.show ();
  }

  [GtkCallback]
  private bool window_delete_cb (Gdk.EventAny evt) {
    if (main_widget != null)
      main_widget.stop ();

    if (account == null)
      return false;

    unowned GLib.List<weak Gtk.Window> ws = this.application.get_windows ();
    debug("Windows: %u", ws.length ());

     // Enable the account's entry in the app menu again
    var acc_menu = (GLib.Menu)Corebird.account_menu;
    for (int i = 0; i < acc_menu.get_n_items (); i++){
      Variant item_name = acc_menu.get_item_attribute_value (i, "label", VariantType.STRING);
      if (item_name.get_string () == "@" + account.screen_name){
        ((SimpleAction)this.application.lookup_action ("show-" + account.screen_name)).set_enabled (true);
        break;
      }
    }

    if (ws.length () == 1) {
      // This is the last window so we save this one anyways...
      string[] startup_accounts = new string[1];
      startup_accounts[0] = ((MainWindow)ws.nth_data (0)).account.screen_name;
      Settings.get ().set_strv ("startup-accounts", startup_accounts);
      debug ("Saving the account %s", ((MainWindow)ws.nth_data (0)).account.screen_name);
    }
    save_geometry ();
    return false;
  }

  /**
   *
   */
  private void load_geometry () {
    if (account == null) {
      debug ("Could not load geometry, account == null");
      return;
    }
    GLib.Variant win_geom = Settings.get ().get_value ("window-geometry");
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    win_geom.lookup (account.screen_name, "(iiii)", &x, &y, &w, &h);
    if (w == 0 || h == 0)
      return;

    move (x, y);
    resize (w, h);
  }

  /**
   * Saves this window's geometry in the window-geometry gsettings key.
   */
  public void save_geometry () {

    GLib.Variant win_geom = Settings.get ().get_value ("window-geometry");
    GLib.Variant new_geom;
    GLib.VariantBuilder builder = new GLib.VariantBuilder (new GLib.VariantType("a{s(iiii)}"));
    var iter = win_geom.iterator ();
    string key = "";
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    while (iter.next ("{s(iiii)}", &key, &x, &y, &w, &h)) {
      if (key != account.screen_name) {
        builder.add ("{s(iiii)}", key, x, y, w, h);
      }
    }
    /* Finally, add this window */
    get_position (out x, out y);
    w = get_allocated_width ();
    h = get_allocated_height ();
    builder.add ("{s(iiii)}", account.screen_name, x, y, w, h);
    new_geom = builder.end ();
    debug ("Saving geomentry for %s: %d,%d,%d,%d", account.screen_name, x, y, w, h);

    Settings.get ().set_value ("window-geometry", new_geom);
  }
}
