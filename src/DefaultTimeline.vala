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

abstract class DefaultTimeline : ScrollWidget, IPage, ITimeline {
  protected bool initialized = false;
  public int id                          { get; set; }
  public int unread_count                { get; set; }
  public unowned MainWindow main_window  { set; get; }
  protected Gtk.ListBox tweet_list       { set; get; }
  public unowned Account account         { get; set; }
  protected BadgeRadioToolButton tool_button;
  public int64 lowest_id                 { get; set; default = int64.MAX-2; }
  protected uint tweet_remove_timeout    { get; set; }
  protected int64 max_id                 { get; set; default = 0; }
  public DeltaUpdater delta_updater      { get; set;}
  protected bool loading = false;


  public DefaultTimeline (int id) {
    this.id = id;
    this.scrolled_to_start.connect(handle_scrolled_to_start);
    this.scrolled_to_end.connect(() => {
      if(!loading) {
        loading = true;
        load_older();
      }
    });

    tweet_list = new Gtk.ListBox();
    tweet_list.get_style_context().add_class("stream");
    tweet_list.set_selection_mode(SelectionMode.NONE);
    tweet_list.set_sort_func(ITwitterItem.sort_func);
    this.add (tweet_list);


  }

  // TODO: Why is there a page_id parameter?
  public virtual void on_join (int page_id, va_list args) {
    if (!initialized) {
      load_cached ();
      load_newest ();
      initialized = true;
    }

    if (Settings.auto_scroll_on_new_tweets ()) {
      this.unread_count = 0;
      update_unread_count ();
    }

  }

  public virtual  void on_leave () {}

  public virtual  void load_cached () {}
  public abstract void load_newest ();
  public abstract void load_older ();



  public virtual void create_tool_button(RadioToolButton? group){}

  public RadioToolButton? get_tool_button() {
    return tool_button;
  }


  protected void update_unread_count() {
    tool_button.show_badge = (unread_count > 0);
    tool_button.queue_draw();
  }
  /**
   * Handle the case of the user scrolling to the start of the list,
   * i.e. remove all the items except a few ones after a timeout.
   */
  protected void handle_scrolled_to_start() { // {{{
    if (tweet_remove_timeout != 0)
      return;

    GLib.List<weak Gtk.Widget> entries = tweet_list.get_children ();
    uint item_count = entries.length ();
    if (item_count > ITimeline.REST) {
      tweet_remove_timeout = GLib.Timeout.add (5000, () => {
        if (!scrolled_up)
          return false;

        while (item_count > ITimeline.REST) {
          tweet_list.remove (tweet_list.get_row_at_index (ITimeline.REST));
          item_count--;
        }
        tweet_remove_timeout = 0;
        return false;
      });
    } else if (tweet_remove_timeout != 0) {
      GLib.Source.remove (tweet_remove_timeout);
      tweet_remove_timeout = 0;
    }
  } // }}}

}
