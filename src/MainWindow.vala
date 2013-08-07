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




class MainWindow : ApplicationWindow {
  public static const int PAGE_STREAM     = 0;
  public static const int PAGE_MENTIONS   = 1;
  public static const int PAGE_SEARCH     = 2;

  public static const int PAGE_PROFILE    = 3;
  public static const int PAGE_TWEET_INFO = 4;



  private Toolbar left_toolbar             = new Toolbar();
  private Box main_box                     = new Box(Orientation.VERTICAL, 0);
  private Box bottom_box                   = new Box(Orientation.HORIZONTAL, 0);
  private RadioToolButton dummy_button     = new RadioToolButton(null);
  private ITimeline[] timelines            = new ITimeline[3];
  private IPage[] pages                    = new IPage[2];
  private int active_page                  = -1;
  private int last_page                    = 0;
  private Button avatar_button             = new Button();
  private Button new_tweet_button          = new Button ();
  private SeparatorToolItem expander_item  = new SeparatorToolItem();
  private SeparatorToolItem left_separator = new SeparatorToolItem();
  private Gtk.Stack stack                  = new Gtk.Stack();
  public unowned Account account {public get; private set;}

  public MainWindow(Gtk.Application app, Account? account = null){
    GLib.Object (application: app);
    set_default_size (480, 700);
    this.set_icon_name("corebird");
    this.destroy.connect (window_destroy_cb);
    this.account = account;

    if (account != null) {
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
    } else {
      warning ("account == NULL");
      return;
    }

    var f = new Gtk.HeaderBar ();
    f.set_title ("Corebird");
    f.set_subtitle ("@"+account.screen_name);
    f.set_show_close_button (true);
    f.pack_start (avatar_button);
    new_tweet_button.get_style_context ().add_class ("image_button");
    f.pack_start (new_tweet_button);
    this.set_titlebar(f);

    stack.transition_duration = Settings.get_animation_duration();
    stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;

    timelines[0] = new HomeTimeline(PAGE_STREAM);
    timelines[1] = new MentionsTimeline(PAGE_MENTIONS);
    timelines[2] = new SearchTimeline(PAGE_SEARCH);

    /* Initialize all containers */
    for (int i = 0; i < timelines.length; i++) {
      ITimeline tl = timelines[i];
      tl.account = account;
      if (!(tl is IPage))
        break;

      if (tl is IMessageReceiver)
        account.user_stream.register ((IMessageReceiver)tl);

      tl.main_window = this;
      tl.load_cached ();
      tl.load_newest ();
      tl.create_tool_button (dummy_button);
      tl.get_tool_button ().toggled.connect (() => {
        if (tl.get_tool_button ().active){
          switch_page (tl.get_id ());
        }
      });
    }

    if (!Gtk.Settings.get_default ().gtk_shell_shows_app_menu) {
      MenuButton app_menu_button = new MenuButton ();
      app_menu_button.image = new Gtk.Image.from_icon_name ("emblem-system-symbolic", IconSize.MENU);
      app_menu_button.get_style_context ().add_class ("image-button");
      app_menu_button.menu_model = this.application.app_menu;
      f.pack_end (app_menu_button);
      this.show_menubar = false;
    }

    //Setup additional pages
    pages[0] = new ProfilePage (PAGE_PROFILE, this, account);
    pages[1] = new TweetInfoPage (PAGE_TWEET_INFO, this, account);

    new_tweet_button.always_show_image = true;
    new_tweet_button.relief = ReliefStyle.NONE;
    new_tweet_button.image = new Gtk.Image.from_icon_name ("document-new", IconSize.MENU);
    new_tweet_button.clicked.connect( () => {
      var cw = new ComposeTweetWindow(this, account, null, get_application ());
      cw.show();
    });

    left_toolbar.orientation = Orientation.VERTICAL;
    left_toolbar.set_style (ToolbarStyle.ICONS);


    expander_item.draw = false;
    expander_item.set_expand(true);

    account.load_avatar ();
    avatar_button.set_image (new Image.from_pixbuf (account.avatar_small));
    avatar_button.relief = ReliefStyle.NONE;
    account.notify["avatar_small"].connect(() => {
      avatar_button.set_image (new Image.from_pixbuf (account.avatar_small));
    });
    avatar_button.clicked.connect( () => {
        message("IMPLEMENT: Show account switcher");
    });

    // Add all tool buttons for the timelines
    foreach (var tl in timelines) {
      if (tl.get_tool_button () != null)
        left_toolbar.add (tl.get_tool_button ());

      stack.add_named (tl, tl.get_id ().to_string ());
    }

    foreach(var page in pages){
      stack.add_named(page, page.get_id ().to_string ());
    }

    left_toolbar.add (expander_item);
    bottom_box.pack_start(left_toolbar, false, false);


    bottom_box.pack_start (stack, true, true);
    main_box.pack_end(bottom_box, true, true);

    add_accels();

    this.add(main_box);
    this.show_all();

    // Activate the first timeline
    timelines[0].get_tool_button().active = true;
  }

  /**
   * Adds the accelerators to the GtkWindow
   */
  private void add_accels() {
    AccelGroup ag = new AccelGroup();
    ag.connect(Gdk.Key.@1, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
      () => {switch_page(0);return true;});
    ag.connect(Gdk.Key.@2, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
      () => {switch_page(1);return true;});
    ag.connect(Gdk.Key.@3, Gdk.ModifierType.MOD1_MASK, AccelFlags.LOCKED,
      () => {switch_page(2);return true;});


    this.add_accel_group(ag);
  }

  /**
   * Switches the window's main notebook to the given page.
   *
   * @param page_id The id of the page to switch to.
   *                See the PAGE_* constants.
   * @param ... The parameters to pass to the page
   */
  public void switch_page (int page_id, ...) {
    if (page_id == active_page)
      return;

    debug ("switching page from %d to %d", active_page, page_id);


    if (page_id > active_page)
      stack.transition_type = StackTransitionType.SLIDE_LEFT;
    else
      stack.transition_type = StackTransitionType.SLIDE_RIGHT;

    this.last_page   = this.active_page;
    this.active_page = page_id;


    IPage page = timelines[0];
    if (page_id < timelines.length) {
      page = timelines[page_id];
      page.get_tool_button().active = true;
    } else {
      page = pages[page_id - timelines.length];
      dummy_button.active = true;
    }


    page.on_join (page_id, va_list ());
    stack.set_visible_child_name ("%d".printf (page_id));
  }

  private void window_destroy_cb() {
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
    }

  }
}
