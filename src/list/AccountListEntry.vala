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



[GtkTemplate (ui = "/org/baedert/corebird/ui/account-list-entry.ui")]
class AccountListEntry : Gtk.Box {
  [GtkChild]
  private Label screen_name_label;
  [GtkChild]
  private Image avatar_image;

  public string screen_name{
    get { return screen_name_label.label; }
  }

  public AccountListEntry (Account acc) {
    screen_name_label.label = acc.screen_name;
    avatar_image.pixbuf = acc.avatar_small;
    acc.notify["avatar-small"].connect(() => {
      avatar_image.pixbuf = acc.avatar_small;
      message("hihi");
    });
  }
}
