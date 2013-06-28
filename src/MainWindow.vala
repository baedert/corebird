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
  public static const int PAGE_STREAM    = 0;
  public static const int PAGE_MENTIONS  = 1;
  public static const int PAGE_SEARCH    = 2;
  // public static const int PAGE_FAVORITES = 2;

  public static const int PAGE_PROFILE   = 3;



  private Toolbar left_toolbar             = new Toolbar();
  private Toolbar primary_toolbar          = new Toolbar();
  private Box main_box                     = new Box(Orientation.VERTICAL, 0);
  private Box bottom_box                   = new Box(Orientation.HORIZONTAL, 0);
  private RadioToolButton dummy_button     = new RadioToolButton(null);
  private ITimeline[] timelines            = new ITimeline[3];
  private IPage[] pages                    = new IPage[1];
  private int active_page                  = 0;
  private int last_page                    = 0;
  private ToolButton avatar_button         = new ToolButton(null, null);
  private ToolButton new_tweet_button      = new ToolButton.from_stock(Stock.NEW);
  private SeparatorToolItem expander_item  = new SeparatorToolItem();
  private SeparatorToolItem left_separator = new SeparatorToolItem();
  private Gtk.Stack stack                  = new Gtk.Stack();

  public MainWindow(Gtk.Application app, Account? account = null){
    GLib.Object (application: app);
    this.set_icon_name("corebird");

    stack.transition_duration = Settings.get_animation_duration();
    stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;

    timelines[0] = new HomeTimeline(PAGE_STREAM);
    timelines[1] = new MentionsTimeline(PAGE_MENTIONS);
    timelines[2] = new SearchTimeline(PAGE_SEARCH);
    // timelines[2] = new FavoriteContainer(PAGE_FAVORITES);

    if (account == null) {
      app.lookup_action ("show-settings").activate (null);
      return;
    }


    /* Initialize all containers */
    for(int i = 0; i < timelines.length; i++){
      ITimeline tl = timelines[i];
      tl.account = account;
      if(!(tl is IPage))
        break;

      tl.main_window = this;
//      tl.load_cached();
      if (i == 0)
     tl.load_newest();
      tl.create_tool_button(dummy_button);
      tl.get_tool_button().toggled.connect(() => {
        if(tl.get_tool_button().active){
          switch_page(tl.get_id());
        }
      });
    }
    // Activate the first timeline
    timelines[0].get_tool_button().active = true;

    //Setup additional pages
    pages[0] = new ProfilePage(PAGE_PROFILE, this);

    // Start userstream
    UserStream.get().start();

    new_tweet_button.clicked.connect( () => {
      var cw = new ComposeTweetWindow(this, null, get_application ());
      cw.show();                                                     
    });

    left_toolbar.orientation = Orientation.VERTICAL;
    left_toolbar.set_style(ToolbarStyle.ICONS);

    primary_toolbar.orientation = Orientation.HORIZONTAL;
    primary_toolbar.set_style(ToolbarStyle.ICONS);
    primary_toolbar.get_style_context().add_class("primary-toolbar");
    primary_toolbar.set_visible(true);


    expander_item.draw = false;
    expander_item.set_expand(true);

    account.load_avatar ();
    avatar_button.set_icon_widget (new Image.from_pixbuf (account.avatar_small));
    account.notify["avatar_small"].connect(() => {
      avatar_button.set_icon_widget (new Image.from_pixbuf (account.avatar_small));
    });
    avatar_button.clicked.connect( () => {
        message("IMPLEMENT: Show account switcher");
    });

    // Add all tool buttons for the timelines
    foreach(var tl in timelines) {
      if(tl.get_tool_button() != null)
        left_toolbar.add(tl.get_tool_button());

      stack.add_named(tl, tl.get_id ().to_string ());
    }

    foreach(var page in pages){
      stack.add_named(page, page.get_id ().to_string ());
    }

    bottom_box.pack_start(left_toolbar, false, false);

    if (Settings.show_primary_toolbar()){
      main_box.pack_start(primary_toolbar, false, false);
      setup_primary_toolbar();
    }else{
      setup_left_toolbar();
    }

    bottom_box.pack_start (stack, true, true);
    main_box.pack_end(bottom_box, true, true);

    add_accels();

    this.add(main_box);
    this.load_geometry();
    this.show_all();
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
   * Adds/inserts the widgets into the left toolbar.
   */
  private void setup_left_toolbar(){
    left_toolbar.get_style_context().remove_class("sidebar");
    left_toolbar.get_style_context().add_class("primary-toolbar");

    left_toolbar.insert(avatar_button, 0);
    left_toolbar.insert(new_tweet_button, 1);
    left_toolbar.insert(left_separator, 2);
    left_toolbar.add(expander_item);
  }

  /**
   * Adds/inserts the widgets into the primary toolbar
   */
  private void setup_primary_toolbar(){
    primary_toolbar.add(avatar_button);
    primary_toolbar.add(new_tweet_button);
    primary_toolbar.add(expander_item);
    //Make the left toolbar a sidebar
    left_toolbar.get_style_context().remove_class("primary-toolbar");
    left_toolbar.get_style_context().add_class("sidebar");
  }

  public void set_show_primary_toolbar(bool show_primary_toolbar){
    // We just ASSUME that this value only toggles and that 2 subsequent calls
    // NEVER have the same value of show_primary_toolbar.
    if(show_primary_toolbar){
      main_box.pack_start(primary_toolbar, false, false);
      //Remove widgets
      left_toolbar.remove(avatar_button);
      left_toolbar.remove(new_tweet_button);
      left_toolbar.remove(expander_item);
      left_toolbar.remove(left_separator);
      //Add them again
      setup_primary_toolbar();
    }else{
      main_box.remove(primary_toolbar);
      //Remove widgets
      primary_toolbar.remove(avatar_button);
      primary_toolbar.remove(new_tweet_button);
      primary_toolbar.remove(expander_item);
      //add them again
      setup_left_toolbar();
    }
  }

  private void save_geometry(){
    int x, y, w, h;
    this.get_size(out w, out h);
    this.get_position(out x, out y);
    Settings.set_string("main-window-geometry", "%d,%d,%d,%d".printf(x,
                        y, w, h));
  }

  private void load_geometry(){
    // TODO: Use gtk_window_parse_geometry
    string geometry_str = Settings.get_string("main-window-geometry");
    string[] parts    = geometry_str.split(",");
    int x      = int.parse(parts[0]);
    int y      = int.parse(parts[1]);
    int width  = int.parse(parts[2]);
    int height = int.parse(parts[3]);
    this.move(x, y);
    this.resize(width, height);
  }



  /**
   * Switches the window's main notebook to the given page.
   *
   * @param page_id The id of the page to switch to.
   *                See the PAGE_* constants.
   * @param ... The parameters to pass to the page
   */
  public void switch_page(int page_id, ...){
    if(page_id == active_page)
      return;

    debug("switching page from %d to %d", active_page, page_id);


    if(page_id > active_page)
      stack.transition_type = StackTransitionType.SLIDE_LEFT;
    else
      stack.transition_type = StackTransitionType.SLIDE_RIGHT;

    this.last_page   = this.active_page;
    this.active_page = page_id;


    IPage page = timelines[0];
    if(page_id < timelines.length){
      page = timelines[page_id];
      page.get_tool_button().active = true;
    }else{
      page = pages[page_id - timelines.length];
      dummy_button.active = true;
    }


    page.on_join(page_id, va_list());
    stack.set_visible_child_name("%d".printf(page_id));
  }
}
