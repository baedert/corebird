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
  public static const int PAGE_STREAM        = 0;
  public static const int PAGE_MENTIONS      = 1;
  public static const int PAGE_FAVORITES     = 2;
  public static const int PAGE_DM_THREADS    = 3;
  public static const int PAGE_LISTS         = 4;
  public static const int PAGE_FILTERS       = 5;
  public static const int PAGE_SEARCH        = 6;
  public static const int PAGE_PROFILE       = 7;
  public static const int PAGE_TWEET_INFO    = 8;
  public static const int PAGE_DM            = 9;
  public static const int PAGE_LIST_STATUSES = 10;

  public static const int PAGE_PREVIOUS   = 1024;
  public static const int PAGE_NEXT       = 2048;

  [GtkChild]
  private Toolbar left_toolbar;
  [GtkChild]
  private HeaderBar headerbar;
  [GtkChild]
  private Gtk.Stack stack;
  [GtkChild]
  private Image avatar_image;
  [GtkChild]
  private Spinner progress_spinner;
  [GtkChild]
  private Gtk.Revealer sidebar_revealer;
  public int cur_page_id {
    get {
      return history.current;
    }
  }
  private uint progress_holders            = 0;
  private RadioToolButton dummy_button     = new RadioToolButton(null);
  private IPage[] pages                    = new IPage[11];
  private IntHistory history               = new IntHistory (5);
  private DeltaUpdater delta_updater       = new DeltaUpdater ();
  public unowned Account account           {public get; private set;}
  private bool page_switch_lock = false;


  public MainWindow(Gtk.Application app, Account? account = null){
    GLib.Object (application: app);
    set_default_size (480, 700);
    this.account = account;

    if (account != null) {
      account.init_proxy ();
      account.query_user_info_by_scren_name.begin (account.screen_name, account.load_avatar);
      var acc_menu = (GLib.Menu)Corebird.account_menu;
      for (int i = 0; i < acc_menu.get_n_items (); i++){
        Variant item_name = acc_menu.get_item_attribute_value (i,
                                         "label", VariantType.STRING);
        if (item_name.get_string () == "@"+account.screen_name){
          ((SimpleAction)app.lookup_action("show-"+account.screen_name)).set_enabled(false);
          break;
        }
      }
      account.user_stream.start ();
    } else {
      warning ("account == NULL");
      new SettingsDialog (null, (Corebird)app).show_all ();
      return;
    }

    this.add_action_entries (win_entries, this);

    // TODO: Just always pass the account instance to the constructor.
    pages[0]  = new HomeTimeline (PAGE_STREAM);
    pages[1]  = new MentionsTimeline (PAGE_MENTIONS);
    pages[2]  = new FavoritesTimeline (PAGE_FAVORITES);
    pages[3]  = new DMThreadsPage (PAGE_DM_THREADS, account);
    pages[4]  = new ListsPage (PAGE_LISTS);
    pages[5]  = new FilterPage (PAGE_FILTERS);
    pages[6]  = new SearchPage (PAGE_SEARCH);
    pages[7]  = new ProfilePage (PAGE_PROFILE);
    pages[8]  = new TweetInfoPage (PAGE_TWEET_INFO);
    pages[9]  = new DMPage (PAGE_DM);
    pages[10] = new ListStatusesPage (PAGE_LIST_STATUSES);

    /* Initialize all containers */
    for (int i = 0; i < pages.length; i++) {
      IPage page = pages[i];
      page.main_window = this;
      page.account = account;

      if (page is IMessageReceiver)
        account.user_stream.register ((IMessageReceiver)page);

      page.create_tool_button (dummy_button);
      stack.add_named (page, page.id.to_string ());
      if (page.get_tool_button () != null) {
        left_toolbar.insert (page.get_tool_button (), page.id);
        page.get_tool_button ().clicked.connect (() => {
          if (page.get_tool_button ().active && !page_switch_lock) {
            switch_page (page.id);
          }
        });
      }


      if (!(page is ITimeline))
        continue;

      ITimeline tl = (ITimeline)page;
      tl.delta_updater = delta_updater;
    }

    // TODO: Gnarf this sucks
    // SearchPage still needs a delta updater
    ((SearchPage)pages[PAGE_SEARCH]).delta_updater = this.delta_updater;
    ((DMThreadsPage)pages[PAGE_DM_THREADS]).delta_updater = this.delta_updater;
    ((DMPage)pages[PAGE_DM]).delta_updater = this.delta_updater;
    ((ProfilePage)pages[PAGE_PROFILE]).delta_updater = this.delta_updater;
    ((ListStatusesPage)pages[PAGE_LIST_STATUSES]).delta_updater = this.delta_updater;


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

    Settings.get ().bind ("sidebar-visible", sidebar_revealer, "reveal-child",
                          SettingsBindFlags.DEFAULT);

    load_geometry ();

    this.show_all();



    // Activate the first timeline
    pages[0].get_tool_button ().active = true;
  }

  /**
   * Adds the accelerators to the GtkWindow
   */
  private void add_accels() { // {{{
    AccelGroup ag = new AccelGroup();

    ag.connect (Gdk.Key.Left, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {switch_page (PAGE_PREVIOUS); return true;});
    ag.connect (Gdk.Key.Right, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {switch_page (PAGE_NEXT); return true;});
    ag.connect (Gdk.Key.Back, 0, AccelFlags.LOCKED,
        () => {switch_page (PAGE_PREVIOUS); return true;});
    ag.connect (Gdk.Key.Forward, 0, AccelFlags.LOCKED,
        () => {switch_page (PAGE_NEXT); return true;});

    this.add_accel_group(ag);
  } // }}}

  [GtkCallback]
  private bool button_press_event_cb (Gdk.EventButton evt) {
    if (evt.button == 9) {
      // Forward thumb button
      switch_page (MainWindow.PAGE_NEXT);
      return true;
    } else if (evt.button == 8) {
      // backward thumb button
      switch_page (MainWindow.PAGE_PREVIOUS);
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
   * Switches the window's main notebook to the given page.
   *
   * @param page_id The id of the page to switch to.
   *                See the PAGE_* constants.
   * @param ... The parameters to pass to the page
   *
   * TODO: Refactor this.
   */
  public void switch_page (int page_id, ...) { // {{{
    if (page_id == history.current) {
      if (pages[page_id].handles_double_open ())
        pages[page_id].double_open ();
      else
        pages[page_id].on_join (page_id, va_list ());

      return;
    }

    bool push = true;

    if (history.current != -1)
      pages[history.current].on_leave ();

    // Set the correct transition type
    if (page_id == PAGE_PREVIOUS || page_id < history.current)
      stack.transition_type = StackTransitionType.SLIDE_RIGHT;
    else if (page_id == PAGE_NEXT || page_id > history.current)
      stack.transition_type = StackTransitionType.SLIDE_LEFT;

    // If we go forward/back, we don't need to update the history.
    if (page_id == PAGE_PREVIOUS) {
      push = false;
      page_id = history.back ();
    } else if (page_id == PAGE_NEXT) {
      push = false;
      page_id = history.forward ();
    }

    if (page_id == -1)
      return;

    if (push)
      history.push (page_id);


    /* XXX The following will cause switch_page to be called twice
       because setting the active property of the button will cause
       the clicked event to be emitted, which will call switch_page. */
    IPage page = pages[page_id];
    Gtk.RadioToolButton button = page.get_tool_button ();
    page_switch_lock = true;
    if (button != null)
      button.active = true;
    else
      dummy_button.active = true;

    page.on_join (page_id, va_list ());
    stack.set_visible_child_name (page_id.to_string ());
    if (page.get_title () != null)
      this.set_title (page.get_title ());
    page_switch_lock = false;
  } // }}}

  /**
   * GSimpleActionActivateCallback version of switch_page, used
   * for keyboard accelerators.
   */
  private void simple_switch_page (GLib.SimpleAction a, GLib.Variant? param) {
    switch_page (param.get_int32 ());
  }

  /**
   * Indicates that the caller is doing a long-running operation.
   */
  public void start_progress () {
    progress_holders ++;
    progress_spinner.show ();
  }

  public void stop_progress () {
    progress_holders --;
    if (progress_holders == 0)
      progress_spinner.hide ();
  }


  public IPage get_page (int page_id) {
    return pages[page_id];
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
