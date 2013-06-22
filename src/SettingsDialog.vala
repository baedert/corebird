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

	public SettingsDialog(MainWindow? win = null){
		this.win = win;
//		this.set_transient_for(win);
//		this.set_modal(true);
//		this.set_default_size(450, 120);
//		this.title = "Settings";

/*		var builder = new UIBuilder(DATADIR+"ui/settings-dialog.ui", "main_notebook");
		var main_notebook = builder.get_notebook("main_notebook");

		// this.add(main_box);
		this.get_content_area().pack_start(main_notebook, true, true);

		var upload_provider_combobox = builder.get_combobox("upload_provider_combobox");
		upload_provider_combobox.active = Settings.upload_provider();
		upload_provider_combobox.changed.connect(() => {
			Settings.set_int("upload-provider", upload_provider_combobox.active);
		});

		var primary_toolbar_switch = builder.get_switch("primary_toolbar_switch");
		primary_toolbar_switch.active = Settings.show_primary_toolbar();
		primary_toolbar_switch.notify["active"].connect(() => {
			Settings.set_bool("show-primary-toolbar", primary_toolbar_switch.active);
			win.set_show_primary_toolbar(primary_toolbar_switch.active);
		});

		var inline_media_switch = builder.get_switch("inline_media_switch");
		inline_media_switch.active = Settings.show_inline_media();
		inline_media_switch.notify["active"].connect(() => {
			Settings.set_bool("show-inline-media", inline_media_switch.active);
		});

		var dark_theme_switch = builder.get_switch("dark_theme_switch");
		dark_theme_switch.active = Settings.use_dark_theme();
		dark_theme_switch.notify["active"].connect(() => {
			bool val = dark_theme_switch.active;
			Settings.set_bool("use-dark-theme", val);
			Gtk.Settings.get_default().gtk_application_prefer_dark_theme = val;
		});

		var on_new_tweets_combobox = builder.get_combobox("on_new_tweets_combobox");
		on_new_tweets_combobox.active = Settings.notify_new_tweets();
		on_new_tweets_combobox.changed.connect(() => {
			Settings.set_int("new-tweets-notify", on_new_tweets_combobox.active);
		});

		var on_new_mentions_switch = builder.get_switch("on_new_mentions_switch");
		on_new_mentions_switch.active = Settings.notify_new_mentions();
		on_new_mentions_switch.notify["active"].connect(() => {
			Settings.set_bool("new-mentions-notify", on_new_mentions_switch.active);
		});

		var on_new_dms_switch = builder.get_switch("on_new_dms_switch");
		on_new_dms_switch.active = Settings.notify_new_dms();
		on_new_dms_switch.notify["active"].connect(() => {
			Settings.set_bool("new-dms-notify", on_new_dms_switch.active);
		});

    var on_new_followers_switch = builder.get_switch("on_new_followers_switch");
    on_new_followers_switch.active = Settings.notify_new_followers();
    on_new_followers_switch.notify["active"].connect(() => {
        Settings.set_bool("new-followers-notify", on_new_followers_switch.active);
    });
    */

    unowned SList<Account> accs = Account.list_accounts ();
    foreach (Account a in accs) {
      account_list.add (new AccountListEntry (a));
      account_info_stack.add_named (new AccountInfoWidget (a), a.screen_name);
    }
	}

  [GtkCallback]
  private void add_account_clicked () {
    Account dummy_acc = new Account(0, DUMMY_SCREEN_NAME, "<__>");
    Account.add_account (dummy_acc);
    ListBoxRow row = new ListBoxRow();
    row.add (new AccountListEntry (dummy_acc));
    account_list.add (row);
    account_info_stack.add_named (new AccountCreateWidget (dummy_acc), DUMMY_SCREEN_NAME);
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
    close ();
  }
}
