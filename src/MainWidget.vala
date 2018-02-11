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

public class MainWidget : Gtk.Box {
  private unowned Account account;

  private Gtk.RadioButton dummy_button  = new Gtk.RadioButton (null);
  private IPage[] pages;
  private Cb.BundleHistory history      = new Cb.BundleHistory ();
  private bool page_switch_lock         = false;
  private ImpostorWidget stack_impostor  = new ImpostorWidget ();
  private Gtk.Box top_box;
  private Gtk.Stack stack;
  private Gtk.Revealer topbar_revealer;
  public int cur_page_id {
    get {
      return history.get_current ();
    }
  }

  public MainWidget (Account account, Cb.MainWindow parent, Corebird app) {
    this.account = account;
    app.start_account (account);

    /* Create widgets */
    this.set_orientation (Gtk.Orientation.VERTICAL);
    this.topbar_revealer = new Gtk.Revealer ();
    topbar_revealer.set_reveal_child (true);
    topbar_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_UP);
    this.top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
    top_box.set_hexpand (true);
    top_box.set_homogeneous (true);
    top_box.get_style_context ().add_class ("topbar");
    topbar_revealer.add (top_box);
    this.add (topbar_revealer);

    this.stack = new Gtk.Stack ();
    stack.set_hexpand (true);
    stack.set_vexpand (true);
    this.add (stack);

    stack.add (stack_impostor);

    pages     = new IPage[11];
    pages[0]  = new HomeTimeline (Page.STREAM, account);
    pages[1]  = new MentionsTimeline (Page.MENTIONS, account);
    pages[2]  = new FavoritesTimeline (Page.FAVORITES, account);
    pages[3]  = new DMThreadsPage (Page.DM_THREADS, account);
    pages[4]  = new ListsPage (Page.LISTS, account);
    pages[5]  = new FilterPage (Page.FILTERS, account);
    pages[6]  = new SearchPage (Page.SEARCH, account);
    pages[7]  = new ProfilePage (Page.PROFILE, account);
    pages[8]  = new TweetInfoPage (Page.TWEET_INFO, account);
    pages[9]  = new DMPage (Page.DM, account);
    pages[10] = new ListStatusesPage (Page.LIST_STATUSES, account);

    /* Initialize all containers */
    for (int i = 0; i < pages.length; i++) {
      IPage page = pages[i];
      page.main_window = parent;

      if (page is Cb.MessageReceiver)
        account.user_stream.register ((Cb.MessageReceiver)page);

      page.create_radio_button (dummy_button);
      stack.add (page);
      if (page.get_radio_button () != null) {
        top_box.add (page.get_radio_button ());
        page.get_radio_button ().clicked.connect (() => {
          if (page.get_radio_button ().active && !page_switch_lock) {
            switch_page (page.id);
          }
        });
      }
    }

    Settings.get ().bind ("sidebar-visible", this.topbar_revealer, "reveal-child",
                          SettingsBindFlags.DEFAULT);
  }


  /**
   * Switches the window's main notebook to the given page.
   *
   * @param page_id The id of the page to switch to.
   *                See the Page.* constants.
   *
   */
  public void switch_page (int page_id, Cb.Bundle? args = null) {
    if (page_id == history.get_current ()) {
      if (pages[page_id].handles_double_open ())
        pages[page_id].double_open ();

      if ((history.get_current_bundle () != null &&
          history.get_current_bundle ().equals (args)) ||
          history.get_current_bundle () == args)
        return;
    }

    bool push = true;


    // Set the correct transition type
    if (page_id == Page.PREVIOUS || page_id < history.get_current ())
      stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
    else if (page_id == Page.NEXT || page_id > history.get_current ())
      stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;

    int current_page = history.get_current ();
    // If we go forward/back, we don't need to update the history.
    if (page_id == Page.PREVIOUS) {
      if (history.at_start ())
        return;

      push = false;
      page_id = history.back ();
      args = history.get_current_bundle ();
    } else if (page_id == Page.NEXT) {
      if (history.at_end ())
        return;

      push = false;
      page_id = history.forward ();
      args = history.get_current_bundle ();
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

    /* on_join first, then set_visible_child so the new page is still !child-visible,
       so e.g. GtkStack transitions inside the page aren't animated */
    page.on_join (page_id, args);
    stack.set_visible_child (pages[page_id]);
    ((Cb.MainWindow)this.parent).set_window_title (page.get_title (), stack.transition_type);

    page_switch_lock = false;

    ((Cb.MainWindow)this.parent).back_button.sensitive = !history.at_start ();
  }

  public void remove_current_page () {
    this.history.remove_current ();
    this.switch_page (Page.PREVIOUS);
  }

  public IPage get_page (int page_id) {
    return pages[page_id];
  }

  public void stop () {
    for (int i = 0; i < pages.length; i++) {
      IPage page = pages[i];
      if (page is Cb.MessageReceiver)
        account.user_stream.unregister ((Cb.MessageReceiver)page);
    }

    ((Corebird)GLib.Application.get_default ()).stop_account (this.account);
  }
}
