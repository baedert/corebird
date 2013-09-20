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
class MainWindow : ApplicationWindow {
  public static const int PAGE_STREAM     = 0;
  public static const int PAGE_MENTIONS   = 1;
  public static const int PAGE_DM_THREADS = 2;
  public static const int PAGE_SEARCH     = 3;
  public static const int PAGE_PROFILE    = 4;
  public static const int PAGE_TWEET_INFO = 5;
  public static const int PAGE_DM         = 6;

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
  private RadioToolButton dummy_button     = new RadioToolButton(null);
  private IPage[] pages                    = new IPage[7];
  private IntHistory history               = new IntHistory (5);
  private Button new_tweet_button          = new Button ();
  private DeltaUpdater delta_updater       = new DeltaUpdater();
  public unowned Account account           {public get; private set;}
  private WarningService warning_service;


  public MainWindow(Gtk.Application app, Account? account = null){
    GLib.Object (application: app);
    set_default_size (480, 700);
    this.destroy.connect (window_destroy_cb);
    this.account = account;

    if (account != null) {
      account.init_proxy ();
      account.query_user_info_by_scren_name.begin (account.screen_name, account.load_avatar);
      this.set_title ("Corebird(@%s)".printf (account.screen_name));
      this.set_role ("corebird-"+account.screen_name);
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
      warning_service = new WarningService (account.screen_name);
      account.user_stream.register (warning_service);
    } else {
      warning ("account == NULL");
      return;
    }

    headerbar.set_subtitle ("@" + account.screen_name);
    //TODO: Move new_tweet_button into the gtktemplate
    new_tweet_button.get_style_context ().add_class ("image-button");
    headerbar.pack_start (new_tweet_button);
    set_titlebar (headerbar);

    stack.transition_duration = Settings.get_animation_duration ();

    pages[0] = new HomeTimeline (PAGE_STREAM);
    pages[1] = new MentionsTimeline (PAGE_MENTIONS);
    pages[2] = new DMThreadsPage (PAGE_DM_THREADS);
    pages[3] = new SearchPage (PAGE_SEARCH);
    pages[4] = new ProfilePage (PAGE_PROFILE, this, account);
    pages[5] = new TweetInfoPage (PAGE_TWEET_INFO);
    pages[6] = new DMPage (PAGE_DM);

    /* Initialize all containers */
    for (int i = 0; i < pages.length; i++) {
      IPage page = pages[i];
      page.main_window = this;
      page.account = account;

      if (page is IMessageReceiver)
        account.user_stream.register ((IMessageReceiver)page);

      page.create_tool_button (dummy_button);
      stack.add_named (page, page.get_id ().to_string ());
      if (page.get_tool_button () != null) {
        left_toolbar.add (page.get_tool_button ());
        page.get_tool_button ().toggled.connect (() => {
          if (page.get_tool_button ().active){
            switch_page (page.get_id ());
          }
        });
      }


      if (!(page is ITimeline))
        continue;

      ITimeline tl = (ITimeline)page;
      tl.delta_updater = delta_updater;
    }

    if (!Gtk.Settings.get_default ().gtk_shell_shows_app_menu) {
      MenuButton app_menu_button = new MenuButton ();
      app_menu_button.image = new Gtk.Image.from_icon_name ("emblem-system-symbolic", IconSize.MENU);
      app_menu_button.get_style_context ().add_class ("image-button");
      app_menu_button.menu_model = this.application.app_menu;
      headerbar.pack_end (app_menu_button);
      this.show_menubar = false;
    }

    new_tweet_button.always_show_image = true;
    new_tweet_button.relief = ReliefStyle.NONE;
    new_tweet_button.image = new Gtk.Image.from_icon_name ("document-new", IconSize.MENU);
    new_tweet_button.clicked.connect(show_compose_window);

    account.load_avatar ();
    avatar_image.pixbuf = account.avatar_small;
    account.notify["avatar_small"].connect(() => {
      avatar_image.pixbuf = account.avatar_small;
    });

    add_accels();

    this.show_all();

    // Activate the first timeline
    this.switch_page (0);
  }

  /**
   * Adds the accelerators to the GtkWindow
   */
  private void add_accels() {
    AccelGroup ag = new AccelGroup();
    ag.connect (Gdk.Key.@1, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {switch_page(0);return true;});
    ag.connect (Gdk.Key.@2, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {switch_page(1);return true;});
    ag.connect (Gdk.Key.@3, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {switch_page(2);return true;});
    ag.connect (Gdk.Key.@4, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {switch_page(3);return true;});

    ag.connect (Gdk.Key.Left, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {switch_page (PAGE_PREVIOUS); return true;});
    ag.connect (Gdk.Key.Right, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
        () => {switch_page (PAGE_NEXT); return true;});
    ag.connect (Gdk.Key.Back, 0, AccelFlags.LOCKED,
        () => {switch_page (PAGE_PREVIOUS); return true;});
    ag.connect (Gdk.Key.Forward, 0, AccelFlags.LOCKED,
        () => {switch_page (PAGE_NEXT); return true;});

    ag.connect (Gdk.Key.t, Gdk.ModifierType.CONTROL_MASK, AccelFlags.LOCKED,
        () => { show_compose_window (); return true;});


    this.add_accel_group(ag);
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
   */
  public void switch_page (int page_id, ...) {
    if (page_id == history.current)
     return;

    bool push = true;

    if (page_id == PAGE_PREVIOUS) {
      page_id = history.back ();
      push = false;
      stack.transition_type = StackTransitionType.SLIDE_RIGHT;
    } else if (page_id == PAGE_NEXT) {
      page_id = history.forward ();
      push = false;
      stack.transition_type = StackTransitionType.SLIDE_LEFT;
    } else {
      if (page_id > history.current)
        stack.transition_type = StackTransitionType.SLIDE_LEFT;
      else
        stack.transition_type = StackTransitionType.SLIDE_RIGHT;
    }


    if (page_id == -1)
      return;

    if (history.current != -1)
      pages[history.current].on_leave ();

    if (push)
      history.push (page_id);


    IPage page = pages[page_id];
    if (page.get_tool_button () != null)
      page.get_tool_button().active = true;
    else
      dummy_button.active = true;

    page.on_join (page_id, va_list ());
    stack.set_visible_child_name (page_id.to_string ());
  }

  /**
    *
    *
    */
  private void window_destroy_cb() {
    account.user_stream.stop ();

    unowned GLib.List<weak Window> ws = this.application.get_windows ();
    message("Windows: %u", ws.length ());

    // Enable the account's entry in the app menu again
    var acc_menu = (GLib.Menu)Corebird.account_menu;
    for (int i = 0; i < acc_menu.get_n_items (); i++){
      Variant item_name = acc_menu.get_item_attribute_value (i,
                                       "label", VariantType.STRING);
      if (item_name.get_string () == "@"+account.screen_name){
        ((SimpleAction)this.application.lookup_action("show-"+account.screen_name)).set_enabled(true);
        break;
      }
    }

    if (ws.length () == 1) {
      // This is the last window so we save this one anyways...
      string[] startup_accounts = new string[1];
      startup_accounts[0] = ((MainWindow)ws.nth_data (0)).account.screen_name;
      Settings.get ().set_strv ("startup-accounts", startup_accounts);
      message ("Saving the account %s", ((MainWindow)ws.nth_data (0)).account.screen_name);
    }

  }
}
