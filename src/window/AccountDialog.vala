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
[GtkTemplate (ui = "/org/baedert/corebird/ui/account-dialog.ui")]
class AccountDialog : Gtk.Dialog {
  private static const int RESPONSE_CLOSE = 0;
  [GtkChild]
  private Gtk.Entry screen_name_entry;
  [GtkChild]
  private AvatarWidget avatar_image;

  private unowned Account account;



  public AccountDialog (Account account) {
    this.account = account;
    avatar_image.pixbuf = account.avatar;
    screen_name_entry.text = account.screen_name;
  }

  public override void response (int response_id) {
    if (response_id == RESPONSE_CLOSE) {
      this.destroy ();
    }
  }

  [GtkCallback]
  private void delete_button_clicked_cb () {
    /*
       - Close open window of that account
       - Remove the account from the db, disk, etc.
       - If this would close the last opened window,
         set the account of that window to NULL
     */
  }
}
