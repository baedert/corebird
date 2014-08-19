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
  private Gtk.Entry name_entry;
  [GtkChild]
  private AvatarBannerWidget avatar_banner_widget;

  private unowned Account account;



  public AccountDialog (Account account) {
    this.account = account;
    screen_name_entry.text = account.screen_name;
    name_entry.text = account.name;
    avatar_banner_widget.set_account (account);
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
       - Remove the account from the app menu
       - If this would close the last opened window,
         set the account of that window to NULL
       - XXX Confirmation?
     */
    var acc_menu = (GLib.Menu) Corebird.account_menu;
    int64 acc_id = account.id;
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id).db"));
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id).png"));
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id)_small.png"));
    Corebird.db.exec (@"DELETE FROM `accounts` WHERE `id`='$(acc_id)';");

    /* Remove account from startup accounts, if it's in there */
    // XXX Is there a better way do do this?
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    for (int i = 0; i < startup_accounts.length; i++)
      if (startup_accounts[i] == account.screen_name) {
        string[] sa_new = new string[startup_accounts.length - 1];
        for (int x = 0; x < i; i++)
          sa_new[x] = startup_accounts[x];
        for (int x = i+1; x < startup_accounts.length; x++)
          sa_new[x] = startup_accounts[x];
        Settings.get ().set_strv ("startup-accounts", sa_new);
      }

    /* Remove account from account app menu */
    for (int i = 0; i < acc_menu.get_n_items (); i++){
      Variant item_name = acc_menu.get_item_attribute_value (i,
                                       "label", VariantType.STRING);
      if (item_name.get_string () == "@"+account.screen_name) {
        acc_menu.remove (i);
        break;
      }
    }


    Corebird cb = (Corebird) GLib.Application.get_default ();

    /* Handle windows, i.e. if this MainWindow is the last open one,
       we want to use it to show the "new account" UI, otherwise we
       just close it. */
    unowned GLib.List<Gtk.Window> windows = cb.get_windows ();
    Gtk.Window? account_window = null;
    int n_main_windows = 0;
    foreach (Gtk.Window win in windows) {
      if (win is MainWindow) {
        n_main_windows ++;
        if (((MainWindow)win).account.id == this.account.id) {
          account_window = win;
        }
      }
    }
    debug ("Open main windows: %d", n_main_windows);

    if (account_window != null) {
      if (n_main_windows > 1)
        account_window.destroy ();
      else
        ((MainWindow)account_window).change_account (null);
    }


    /* Remove the account from the global list of accounts */
    Account acc_to_remove = Account.query_account (account.screen_name);
    cb.account_removed (acc_to_remove);
    Account.remove_account (account.screen_name);


    /* Close this dialog */
    this.destroy ();
  }
}
