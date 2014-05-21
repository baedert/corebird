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



[GtkTemplate (ui = "/org/baedert/corebird/ui/main-window.ui")]
public class MainWindow : ApplicationWindow {
  private const GLib.ActionEntry[] win_entries = {
    {"compose_tweet",  show_compose_window},
    {"toggle_sidebar", Settings.toggle_sidebar_visible},
    {"switch_page",    simple_switch_page, "i"}
  };
  [GtkChild]
  private HeaderBar headerbar;
  [GtkChild]
  private Image avatar_image;

  private MainWidget main_widget;
  public unowned Account account           {public get; private set;}

  public int cur_page_id {
    get {
      return main_widget.cur_page_id;
    }
  }



  public MainWindow(Gtk.Application app, Account? account = null){
    GLib.Object (application: app);
    set_default_size (480, 700);
    this.account = account;

    if (account != null) {
      main_widget = new MainWidget (account, this, (Corebird)app);
      this.add (main_widget);

      headerbar.set_subtitle ("@" + account.screen_name);
    } else
      error ("F");

    this.add_action_entries (win_entries, this);

    if (!Gtk.Settings.get_default ().gtk_shell_shows_app_menu) {
      MenuButton app_menu_button = new MenuButton ();
      app_menu_button.image = new Gtk.Image.from_icon_name ("emblem-system-symbolic", IconSize.MENU);
      app_menu_button.get_style_context ().add_class ("image-button");
      app_menu_button.menu_model = this.application.app_menu;
      app_menu_button.set_relief (Gtk.ReliefStyle.NONE);
      headerbar.pack_end (app_menu_button);
      this.show_menubar = false;
    }

    account.load_avatar ();
    avatar_image.pixbuf = account.avatar_small;
    account.notify["avatar_small"].connect(() => {
      avatar_image.pixbuf = account.avatar_small;
    });

    add_accels();

    load_geometry ();

    this.show_all();



  }

  /**
   * Adds the accelerators to the GtkWindow
   */
  private void add_accels() { // {{{
    AccelGroup ag = new AccelGroup();

    ag.connect (Gdk.Key.Left, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {main_widget.switch_page (Page.PREVIOUS); return true;});
    ag.connect (Gdk.Key.Right, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {main_widget.switch_page (Page.NEXT); return true;});
    ag.connect (Gdk.Key.Back, 0, AccelFlags.LOCKED,
        () => {main_widget.switch_page (Page.PREVIOUS); return true;});
    ag.connect (Gdk.Key.Forward, 0, AccelFlags.LOCKED,
        () => {main_widget.switch_page (Page.NEXT); return true;});

    this.add_accel_group(ag);
  } // }}}

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
    return null;
  }

  public void switch_page (int page_id, ...) {
    // XXX ?
    main_widget.switch_page (page_id, va_list ());
  }



  [GtkCallback]
  private bool window_delete_cb (Gdk.EventAny evt) {
    account.user_stream.stop ();
    account.user_counter.save (account.db);

    unowned GLib.List<weak Window> ws = this.application.get_windows ();
    debug("Windows: %u", ws.length ());

     // Enable the account's entry in the app menu again
    var acc_menu = (GLib.Menu)Corebird.account_menu;
    for (int i = 0; i < acc_menu.get_n_items (); i++){
      Variant item_name = acc_menu.get_item_attribute_value (i, "label", VariantType.STRING);
      if (item_name.get_string () == "@" + account.screen_name){
        ((SimpleAction)this.application.lookup_action("show-" + account.screen_name)).set_enabled(true);
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

    Settings.get ().set_value ("window-geometry", new_geom);
  }
}
