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

class ProfilePage : IPage, ScrollWidget {
  public int unread_count {
    get{return 0;}
    set{;}
  }
  private int id;
  private ProfileWidget profile_widget;
  public unowned MainWindow main_window { get; set; }
  public unowned Account account { get; set; }

  public ProfilePage(int id, MainWindow window, Account account){
    profile_widget = new ProfileWidget(window, account);
    this.main_window = window;
    this.id = id;
    this.add_with_viewport(profile_widget);
    this.button_press_event.connect (button_pressed_event_cb);
  }

  /**
   * see IPage#onJoin
   */
  public void on_join(int page_id, va_list arg_list) {
    int64 user_id = arg_list.arg();
    if (user_id == 0)
      return;
    profile_widget.set_user_id(user_id);
  }


  public void create_tool_button(RadioToolButton? group) {}

  public RadioToolButton? get_tool_button(){
    return null;
  }

  public int get_id(){
    return id;
  }
}
