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



class ListStatusesPage : ScrollWidget, IPage {
  public int id                         { get; set; }
  public unowned MainWindow main_window { get; set; }
  public unowned Account account        { get; set; }
  private Gtk.ListBox tweet_list = new Gtk.ListBox ();
  private int64 list_id;

  public ListStatusesPage (int id) {
    this.id = id;
    this.add (tweet_list);
  }

  public void on_join (int page_id, va_list args) {
    int64 list_id = args.arg<int64> ();
    if (list_id == 0)
      list_id = this.list_id;

    message (@"Showing list with id $list_id");
    if (list_id == this.list_id) {
      this.list_id = list_id;
    } else {
      this.list_id = list_id;
      load_newest ();
    }

  }

  public void on_leave () {
  }

  private void load_newest () { // {{{
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/statuses.json");
    call.set_method ("GET");
    call.add_param ("list_id", list_id.to_string ());
    message (list_id.to_string ());
    call.invoke_async.begin (null, (o, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message);
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical (e.message);
        return;
      }

      var now = new GLib.DateTime.now_local ();
      var root_array = parser.get_root ().get_array ();
      root_array.foreach_element ((array, index, node) => {
        message ("a");
        Tweet t = new Tweet ();
        t.load_from_json (node, now);

        TweetListEntry entry = new TweetListEntry (t, main_window, account);
        entry.show_all ();
        tweet_list.add (entry);
      });
    });

  } // }}}



  public void create_tool_button (Gtk.RadioToolButton? group) {}
  public Gtk.RadioToolButton? get_tool_button () {return null;}
}
