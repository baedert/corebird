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

// TODO: Add timeout that removes all entries after X seconds when switched away
[GtkTemplate (ui = "/org/baedert/corebird/ui/search-page.ui")]
class SearchPage : IPage, Box {
  private int id;
  /** The unread count here is always zero */
  public int unread_count{
    get{return 0;}
    set{;}
  }
  public unowned Account account        { get; set; }
  public unowned MainWindow main_window { set; get; }
  [GtkChild]
  private SearchEntry search_entry;
  [GtkChild]
  private Button search_button;
  [GtkChild]
  private ListBox tweet_list { get; set; } // TODO: Rename tweet_list
  protected int64 lowest_id  { get; set; default = int64.MAX-2; }
  private RadioToolButton tool_button;
  private DeltaUpdater delta_updater;


  public SearchPage (int id) {
    GLib.Object(orientation: Orientation.VERTICAL);
    this.id = id;
    search_entry.margin = 5;
    search_entry.placeholder_text = "Search keyword(s)";
    search_entry.primary_icon_name = "find";
    search_entry.icon_press.connect( (pos) => {
      if (pos == EntryIconPosition.PRIMARY){
        search_for (search_entry.get_text ());
      }
    });
    this.pack_start(search_entry, false, true);

    tweet_list = new Gtk.ListBox();
    tweet_list.set_header_func ((row, row_before) => {
      if (row_before == null)
        return;

      Widget header = row.get_header ();
      if (header == null) {
        header = new Gtk.Separator (Orientation.HORIZONTAL);
        header.show ();
        row.set_header (header);
      }

    });
    var result_scroller = new ScrollWidget();
    result_scroller.add (tweet_list);
    this.pack_start(result_scroller, true, true);

    tweet_list.set_sort_func(ITwitterItem.sort_func);
    this.button_press_event.connect (button_pressed_event_cb);
  }

  /**
   * see IPage#onJoin
   */
  public void on_join (int page_id, va_list arg_list) {
    string term = arg_list.arg<string>();
    if(term != null)
      search_for (term, true);
  }

  public void on_leave () {

  }

  public void search_for(string search_term, bool set_text = false){
    if(search_term.length == 0)
      return;

    if (set_text)
      search_entry.set_text(search_term);


    var call = account.proxy.new_call ();
    call.set_function ("1.1/search/tweets.json");
    call.set_method ("GET");
    call.add_param ("q", GLib.Uri.escape_string (search_entry.get_text ()));
    call.invoke_async.begin (null, (obj, res) => {
      try{
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        warning ("Error while ending search call: %s", e.message);
        return;
      }
      string back = call.get_payload ();
      stdout.printf (back + "\n");
      Json.Parser parser = new Json.Parser ();
      try {
        parser.load_from_data(back);
      } catch (GLib.Error e) {
        critical(" %s\nDATA:\n%s", e.message, back);
      }
      var statuses = parser.get_root().get_object().get_array_member("statuses");
      statuses.foreach_element ((array, index, node) => {

      });
    });
  }



  public void create_tool_button(RadioToolButton? group){
    tool_button = new RadioToolButton.from_widget (group);
    tool_button.icon_name = "corebird-search-symbolic";
    tool_button.label = "Search";
  }

  public RadioToolButton? get_tool_button(){
    return tool_button;
  }

  public int get_id(){
    return id;
  }
}
