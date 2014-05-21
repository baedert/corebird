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


[GtkTemplate (ui = "/org/baedert/corebird/ui/main-widget.ui")]
class MainWidget : Gtk.Box {
  private unowned Account account;
  private unowned Corebird app;

  private Gtk.RadioToolButton dummy_button = new Gtk.RadioToolButton(null);
  private IPage[] pages                    = new IPage[11];
  private IntHistory history               = new IntHistory (5);
  private DeltaUpdater delta_updater       = new DeltaUpdater ();
  private bool page_switch_lock            = false;


  [GtkChild]
  private Gtk.Toolbar left_toolbar;
  [GtkChild]
  private Gtk.Stack stack;
  [GtkChild]
  private Gtk.Spinner progress_spinner;
  [GtkChild]
  private Gtk.Revealer sidebar_revealer;
  public int cur_page_id {
    get {
      return history.current;
    }
  }
  private uint progress_holders            = 0;



  public MainWidget (Account account, MainWindow parent, Corebird app) {
    this.account = account;
    this.app = app;

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


    // TODO: Just always pass the account instance to the constructor.
    pages[0]  = new HomeTimeline (Page.STREAM);
    pages[1]  = new MentionsTimeline (Page.MENTIONS);
    pages[2]  = new FavoritesTimeline (Page.FAVORITES);
    pages[3]  = new DMThreadsPage (Page.DM_THREADS, account);
    pages[4]  = new ListsPage (Page.LISTS);
    pages[5]  = new FilterPage (Page.FILTERS);
    pages[6]  = new SearchPage (Page.SEARCH);
    pages[7]  = new ProfilePage (Page.PROFILE);
    pages[8]  = new TweetInfoPage (Page.TWEET_INFO);
    pages[9]  = new DMPage (Page.DM);
    pages[10] = new ListStatusesPage (Page.LIST_STATUSES);

    /* Initialize all containers */
    for (int i = 0; i < pages.length; i++) {
      IPage page = pages[i];
      page.main_window = parent;
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
    ((SearchPage)pages[Page.SEARCH]).delta_updater = this.delta_updater;
    ((DMThreadsPage)pages[Page.DM_THREADS]).delta_updater = this.delta_updater;
    ((DMPage)pages[Page.DM]).delta_updater = this.delta_updater;
    ((ProfilePage)pages[Page.PROFILE]).delta_updater = this.delta_updater;
    ((ListStatusesPage)pages[Page.LIST_STATUSES]).delta_updater = this.delta_updater;

    Settings.get ().bind ("sidebar-visible", sidebar_revealer, "reveal-child",
                          SettingsBindFlags.DEFAULT);


      // Activate the first timeline
    pages[0].get_tool_button ().active = true;
  }

  /**
   * Switches the window's main notebook to the given page.
   *
   * @param page_id The id of the page to switch to.
   *                See the Page.* constants.
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
    if (page_id == Page.PREVIOUS || page_id < history.current)
      stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
    else if (page_id == Page.NEXT || page_id > history.current)
      stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;

    // If we go forward/back, we don't need to update the history.
    if (page_id == Page.PREVIOUS) {
      push = false;
      page_id = history.back ();
    } else if (page_id == Page.NEXT) {
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
    page_switch_lock = false;
  } // }}}


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
}
