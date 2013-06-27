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

[GtkTemplate (ui = "/org/baedert/corebird/ui/settings-dialog.ui")]
class SettingsDialog : Gtk.Dialog {
  private static const string DUMMY_SCREEN_NAME = "<Unnamed>";
	private MainWindow win;
  [GtkChild]
  private ListBox account_list;
  [GtkChild]
  private ToolButton add_account_button;
  [GtkChild]
  private ToolButton remove_account_button;
  [GtkChild]
  private Gtk.Stack account_info_stack;
  [GtkChild]
  private Switch on_new_mentions_switch;
  [GtkChild]
  private Switch on_new_followers_switch;
  [GtkChild]
  private Switch on_new_dms_switch;
  [GtkChild]
  private Switch primary_toolbar_switch;
  [GtkChild]
  private Switch inline_media_switch;
  [GtkChild]
  private Switch dark_theme_switch;
  [GtkChild]
  private ComboBoxText upload_provider_combobox;
  [GtkChild]
  private ComboBoxText on_new_tweets_combobox;

	public SettingsDialog(MainWindow? win = null){
		this.win = win;
    Settings.get ().bind ("new-tweets-notify", on_new_tweets_combobox, "active-id",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-mentions-notify", on_new_mentions_switch, "active", 
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-followers-notify", on_new_followers_switch, "active",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-dms-notify", on_new_dms_switch, "active",
                          SettingsBindFlags.DEFAULT);

    // Interface page
    Settings.get ().bind ("show-primary-toolbar", primary_toolbar_switch, "active",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("show-inline-media", inline_media_switch, "active",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("use-dark-theme", dark_theme_switch, "active",
                          SettingsBindFlags.DEFAULT);

    // General Page
    Settings.get ().bind ("upload-provider", upload_provider_combobox, "active_id",
                          SettingsBindFlags.DEFAULT);

    unowned SList<Account> accs = Account.list_accounts ();
    foreach (Account a in accs) {
      a.load_avatar ();
      account_list.add (new AccountListEntry (a));
      account_info_stack.add_named (new AccountInfoWidget (a), a.screen_name);
    }
    if (accs.length() > 0)
      account_list.select_row (account_list.get_row_at_index (0));
	}

  [GtkCallback]
  private void add_account_clicked () {
    Account dummy_acc = new Account(0, DUMMY_SCREEN_NAME, "<__>");
    Account.add_account (dummy_acc);
    ListBoxRow row = new ListBoxRow();
    row.add (new AccountListEntry (dummy_acc));
    account_list.add (row);
    var create_widget = new AccountCreateWidget (dummy_acc);
    create_widget.result_received.connect (on_account_access);
    account_info_stack.add_named (create_widget, DUMMY_SCREEN_NAME);
    row.show_all ();
    account_list.select_row (row);

    add_account_button.sensitive = false;   
  }

  [GtkCallback]
  private void remove_account_clicked () {
    ListBoxRow row = account_list.get_selected_row ();
    AccountListEntry entry = (AccountListEntry)row.get_child ();
    if (entry.screen_name == DUMMY_SCREEN_NAME) {
      account_list.remove (row);
      account_info_stack.remove (account_info_stack.get_visible_child ());
      Account.remove_account (DUMMY_SCREEN_NAME);
      add_account_button.sensitive = true;
    }
  }

  [GtkCallback]
  private void account_list_selected () {
    ListBoxRow row = account_list.get_selected_row ();
    if (row == null) {
      remove_account_button.sensitive = false;
      return;
    }
    AccountListEntry entry = (AccountListEntry)row.get_child ();
    account_info_stack.set_visible_child_name (entry.screen_name);
    remove_account_button.sensitive = true;
  }

  [GtkCallback]
  private void close_button_clicked () {
    Account.remove_account (DUMMY_SCREEN_NAME);
    destroy();
  }

  private void on_account_access (bool result, Account acc) {
    if (result) {
      account_info_stack.remove (account_info_stack.get_visible_child ());
      var acc_widget = new AccountInfoWidget (acc);
      account_info_stack.add_named (acc_widget, acc.screen_name);
      account_info_stack.set_visible_child_name (acc.screen_name);
      account_list.remove (account_list.get_selected_row ());
      account_list.add (new AccountListEntry (acc));
    } else {
      warning ("Wrong token!");
    }
  }
}
