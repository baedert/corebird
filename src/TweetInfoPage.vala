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

class TweetInfoPage : IPage , Gtk.Box {
  public int unread_count { get{return 0;} set {} }
  private int id;
  private unowned Account account;
  private unowned MainWindow window;



  public TweetInfoPage (int id, MainWindow window, Account account) {
    this.id = id;
    this.account = account;
    this.window = window;
  }

  public void on_join (int page_id, va_list args){

  }

  public int get_id () {
    return id;
  }


  public void create_tool_button (Gtk.RadioToolButton? group) {
  }


  public Gtk.RadioToolButton? get_tool_button () {
    return null;
  }

}
