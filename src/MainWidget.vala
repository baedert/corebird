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
public class MainWidget : Gtk.Box {
  private unowned Account account;

  private Gtk.RadioButton dummy_button = new Gtk.RadioButton (null);
  private IPage[] pages                = new IPage[12];
  private BundleHistory history        = new BundleHistory (5);
  private DeltaUpdater delta_updater   = new DeltaUpdater ();
  private bool page_switch_lock        = false;
  private ImpostorWidget stack_impostor = new ImpostorWidget ();


  [GtkChild]
  private Gtk.Box left_box;
  [GtkChild]
  private Gtk.Stack stack;
  [GtkChild]
  private Gtk.Revealer sidebar_revealer;
  public int cur_page_id {
    get {
      return history.current;
    }
  }



  public MainWidget (Account account, MainWindow parent, Corebird app) {
    this.account = account;

    account.init_proxy ();
    var acc_menu = (GLib.Menu)Corebird.account_menu;
    for (int i = 0; i < acc_menu.get_n_items (); i++){
      int64 item_id = acc_menu.get_item_attribute_value (i, "user-id", VariantType.INT64).get_int64 ();
      if (item_id == account.id) {
        ((SimpleAction)app.lookup_action ("show-" + account.id.to_string ())).set_enabled (false);
        break;
      }
    }
    account.user_stream.start ();
    account.init_information.begin ();

    stack.add (stack_impostor);

    pages[0]  = new HomeTimeline (Page.STREAM, account);
    pages[1]  = new MentionsTimeline (Page.MENTIONS, account);
    pages[2]  = new FavoritesTimeline (Page.FAVORITES, account);
    pages[3]  = new DMThreadsPage (Page.DM_THREADS, account, delta_updater);
    pages[4]  = new ListsPage (Page.LISTS, account);
    pages[5]  = new FilterPage (Page.FILTERS, account);
    pages[6]  = new TrendingTopicsPage (Page.TRENDS, account, delta_updater);
    pages[7]  = new SearchPage (Page.SEARCH, account, delta_updater);
    pages[8]  = new ProfilePage (Page.PROFILE, account, delta_updater);
    pages[9]  = new TweetInfoPage (Page.TWEET_INFO, account, delta_updater);
    pages[10] = new DMPage (Page.DM, account, delta_updater);
    pages[11] = new ListStatusesPage (Page.LIST_STATUSES, account, delta_updater);

    /* Initialize all containers */
    for (int i = 0; i < pages.length; i++) {
      IPage page = pages[i];
      page.main_window = parent;

      if (page is IMessageReceiver)
        account.user_stream.register ((IMessageReceiver)page);

      page.create_radio_button (dummy_button);
      stack.add (page);
      if (page.get_radio_button () != null) {
        left_box.add (page.get_radio_button ());
        page.get_radio_button ().clicked.connect (() => {
          if (page.get_radio_button ().active && !page_switch_lock) {
            switch_page (page.id);
          }
        });
      }


      if (!(page is ITimeline))
        continue;

      ITimeline tl = (ITimeline)page;
      tl.delta_updater = delta_updater;
    }

    Settings.get ().bind ("sidebar-visible", sidebar_revealer, "reveal-child",
                          SettingsBindFlags.DEFAULT);
  }


  /**
   * Switches the window's main notebook to the given page.
   *
   * @param page_id The id of the page to switch to.
   *                See the Page.* constants.
   *
   */
  public void switch_page (int page_id, Bundle? args = null) {
    if (page_id == history.current) {
      if (pages[page_id].handles_double_open ())
        pages[page_id].double_open ();

      if ((history.current_bundle != null &&
          history.current_bundle.equals (args)) ||
          history.current_bundle == args)
        return;
    }

    bool push = true;


    // Set the correct transition type
    if (page_id == Page.PREVIOUS || page_id < history.current)
      stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
    else if (page_id == Page.NEXT || page_id > history.current)
      stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;

    int current_page = history.current;
    // If we go forward/back, we don't need to update the history.
    if (page_id == Page.PREVIOUS) {
      if (history.at_start ())
        return;

      push = false;
      page_id = history.back ();
      args = history.current_bundle;
    } else if (page_id == Page.NEXT) {
      if (history.at_end ())
        return;

      push = false;
      page_id = history.forward ();
      args = history.current_bundle;
    }

    if (page_id == current_page) {
      stack_impostor.clone (pages[page_id]);
      var transition_type = stack.transition_type;
      stack.transition_type = Gtk.StackTransitionType.NONE;
      stack.set_visible_child (stack_impostor);
      stack.transition_type = transition_type;
    }

    if (current_page != -1)
      pages[current_page].on_leave ();


    if (push) {
      history.push (page_id, args);
    }


    /* XXX The following will cause switch_page to be called twice
       because setting the active property of the button will cause
       the clicked event to be emitted, which will call switch_page. */
    IPage page = pages[page_id];
    Gtk.ToggleButton button = page.get_radio_button ();
    page_switch_lock = true;
    if (button != null)
      button.active = true;
    else
      dummy_button.active = true;

    page.on_join (page_id, args);
    stack.set_visible_child (pages[page_id]);
    if (page.get_title () != null)
      ((MainWindow)this.parent).set_title (page.get_title ());

    page_switch_lock = false;

    ((MainWindow)this.parent).back_button.sensitive = !history.at_start ();
  }

  public IPage get_page (int page_id) {
    return pages[page_id];
  }

  public void stop () {
    account.uninit ();
  }
}
