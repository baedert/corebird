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

[GtkTemplate (ui = "/org/baedert/corebird/ui/lists-page.ui")]
class ListsPage : IPage, ScrollWidget {
  private BadgeRadioToolButton tool_button;
  public int unread_count                   { get; set; }
  public unowned MainWindow main_window     { get; set; }
  public unowned Account account            { get; set; }
  public unowned DeltaUpdater delta_updater { get; set; }
  public int id                             { get; set; }
  private bool inited = false;

  public ListsPage (int id) {
    this.id = id;
  }


  public void on_join (int page_id, va_list arg_list) {
    if (inited)
      return;

    inited = true;
  }

  public void on_leave () {

  }


  private void load_newest () { // {{{
    var call = account.proxy.new_call ();
    call.set_function ("1.1/lists/list.json");
    call.set_method ("GET");
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }

      var arr = parser.get_root ().get_array ();
      arr.foreach_element ((array, index, node) => {
        var obj = node.get_object ();

      });
      stdout.printf (call.get_payload () + "\n");
    });

  } // }}}



  public void create_tool_button (RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton (group, "corebird-stream-symbolic");
    tool_button.label = "Lists";
  }

  public RadioToolButton? get_tool_button () {
    return tool_button;
  }

}
