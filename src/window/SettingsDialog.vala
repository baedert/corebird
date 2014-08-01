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

[GtkTemplate (ui = "/org/baedert/corebird/ui/settings-dialog.ui")]
class SettingsDialog : Gtk.Window {
  private static const string DUMMY_SCREEN_NAME = "<Unnamed>";
  private MainWindow main_window;
  [GtkChild]
  private Gtk.ListBox account_list;
  [GtkChild]
  private Gtk.ToolButton add_account_button;
  [GtkChild]
  private Gtk.ToolButton remove_account_button;
  [GtkChild]
  private Gtk.Stack account_info_stack;
  [GtkChild]
  private Gtk.Switch on_new_mentions_switch;
  [GtkChild]
  private Gtk.Switch round_avatar_switch;
  [GtkChild]
  private Gtk.Switch on_new_dms_switch;
  [GtkChild]
  private Gtk.ComboBoxText on_new_tweets_combobox;
  [GtkChild]
  private Gtk.Switch auto_scroll_on_new_tweets_switch;
  [GtkChild]
  private Gtk.SpinButton max_media_size_spin_button;

  public SettingsDialog (MainWindow? main_window = null, Corebird? application = null){
    this.main_window = main_window;
    this.application = application;
    this.type_hint   = Gdk.WindowTypeHint.DIALOG;


    // Notifications Page
    Settings.get ().bind ("round-avatars", round_avatar_switch, "active",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-tweets-notify", on_new_tweets_combobox, "active-id",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-mentions-notify", on_new_mentions_switch, "active",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-dms-notify", on_new_dms_switch, "active",
                          SettingsBindFlags.DEFAULT);

    // Interface page
    auto_scroll_on_new_tweets_switch.notify["active"].connect (() => {
      on_new_tweets_combobox.sensitive = !auto_scroll_on_new_tweets_switch.active;
    });
    Settings.get ().bind ("auto-scroll-on-new-tweets", auto_scroll_on_new_tweets_switch, "active",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("max-media-size", max_media_size_spin_button, "value",
                          SettingsBindFlags.DEFAULT);

    unowned SList<Account> accs = Account.list_accounts ();
    foreach (Account a in accs) {
      a.load_avatar ();
      account_list.add (new AccountListEntry (a));
      account_info_stack.add_named (new AccountInfoWidget (a, this.application), a.screen_name);
    }
    if (accs.length() > 0)
      account_list.select_row (account_list.get_row_at_index (0));

    load_geometry ();
    show_all ();
  }

  [GtkCallback]
  private void add_account_clicked () {
    Account dummy_acc = new Account(0, DUMMY_SCREEN_NAME, "<__>");
    Account.add_account (dummy_acc);
    var row = new AccountListEntry (dummy_acc);
    account_list.add (row);
    var create_widget = new AccountCreateWidget (dummy_acc);
    create_widget.result_received.connect (on_account_access);
    account_info_stack.add_named (create_widget, DUMMY_SCREEN_NAME);
    row.show_all ();
    account_list.select_row (row);
    create_widget.open_pin_request_site ();

    add_account_button.sensitive = false;
  }

  [GtkCallback]
  private void remove_account_clicked () {
    AccountListEntry entry = (AccountListEntry)account_list.get_selected_row ();
    if (entry.screen_name == DUMMY_SCREEN_NAME) {
      account_list.remove (entry);
      account_info_stack.remove (account_info_stack.get_visible_child ());
      Account.remove_account (DUMMY_SCREEN_NAME);
      add_account_button.sensitive = true;
      // Select another account. We just take the first one
      if (account_list.get_children () != null)
        account_list.select_row ((Gtk.ListBoxRow)account_list.get_children ().data);
    } else {
      var remove_dialog = new RemoveAccountDialog ();
      remove_dialog.remove_clicked.connect (() => {
        real_remove_account (entry);
        remove_dialog.destroy ();
      });
      remove_dialog.show ();
    }
  }

  [GtkCallback]
  private void account_list_selected () {
    Gtk.ListBoxRow row = account_list.get_selected_row ();
    if (row == null) {
      remove_account_button.sensitive = false;
      return;
    }
    AccountListEntry entry = (AccountListEntry)row;
    account_info_stack.set_visible_child_name (entry.screen_name);
    remove_account_button.sensitive = true;
  }

  [GtkCallback]
  private bool window_destroy_cb () {
    Account.remove_account (DUMMY_SCREEN_NAME);
    save_geometry ();
//    destroy();
    return false;
  }

  private void on_account_access (bool result, Account acc) {
    if (result) {
      account_info_stack.remove (account_info_stack.get_visible_child ());
      var acc_widget = new AccountInfoWidget (acc, this.application);
      account_info_stack.add_named (acc_widget, acc.screen_name);
      account_info_stack.set_visible_child_name (acc.screen_name);
      account_list.remove (account_list.get_selected_row ());
      var new_entry = new AccountListEntry (acc);
      account_list.add (new_entry);
      account_list.select_row (new_entry);
    } else {
       //In this case, the account was already present so we just remove the item again
       //the given accoun is then the already defined one.
      account_info_stack.remove (account_info_stack.get_visible_child ());
      account_list.remove (account_list.get_selected_row ());
      select_account (acc.screen_name);
    }
  }

  private void real_remove_account (AccountListEntry entry) {
    var acc_menu = (GLib.Menu)Corebird.account_menu;
    int64 acc_id = entry.account.id;
    FileUtils.remove (Dirs.config ("accounts/$(acc_id).db"));
    FileUtils.remove (Dirs.config ("accounts/$(acc_id).png"));
    FileUtils.remove (Dirs.config ("accounts/$(acc_id)_small.png"));
    Corebird.db.exec (@"DELETE FROM `accounts` WHERE `id`='$(acc_id)';");
    account_info_stack.remove (account_info_stack.get_visible_child ());
    account_list.remove (entry);
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    for (int i = 0; i < startup_accounts.length; i++)
      if (startup_accounts[i] == entry.account.screen_name) {
        string[] sa_new = new string[startup_accounts.length - 1];
        for (int x = 0; x < i; i++)
          sa_new[x] = startup_accounts[x];
        for (int x = i+1; x < startup_accounts.length; x++)
          sa_new[x] = startup_accounts[x];
        Settings.get ().set_strv ("startup-accounts", sa_new);
      }

    for (int i = 0; i < acc_menu.get_n_items (); i++){
      Variant item_name = acc_menu.get_item_attribute_value (i,
                                       "label", VariantType.STRING);
      if (item_name.get_string () == "@"+entry.account.screen_name) {
        acc_menu.remove (i);
        break;
      }
    }
    Account.remove_account (entry.account.screen_name);
    MainWindow acc_window;
    if (((Corebird)this.application).is_window_open_for_screen_name (entry.account.screen_name,
                                                                     out acc_window)) {
      acc_window.close ();
    }

    // Select another account. We just take the first one
    if (account_list.get_children () != null)
      account_list.select_row ((Gtk.ListBoxRow)account_list.get_children ().data);
  }

  private void select_account (string screen_name) {
    GLib.List<weak Gtk.Widget> entries = account_list.get_children ();
    foreach (var entry in entries) {
      if (((AccountListEntry)entry).screen_name == screen_name) {
        account_list.select_row ((Gtk.ListBoxRow)entry);
        break;
      }
    }
  }

  private void load_geometry () {
    GLib.Variant geom = Settings.get ().get_value ("settings-geometry");
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    x = geom.get_child_value (0).get_int32 ();
    y = geom.get_child_value (1).get_int32 ();
    w = geom.get_child_value (2).get_int32 ();
    h = geom.get_child_value (3).get_int32 ();
    if (w == 0 || h == 0)
      return;

    move (x, y);
    resize (w, h);
  }

  private void save_geometry () {
    var builder = new GLib.VariantBuilder (GLib.VariantType.TUPLE);
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    get_position (out x, out y);
    w = get_allocated_width ();
    h = get_allocated_height ();
    builder.add_value (new GLib.Variant.int32(x));
    builder.add_value (new GLib.Variant.int32(y));
    builder.add_value (new GLib.Variant.int32(w));
    builder.add_value (new GLib.Variant.int32(h));
    Settings.get ().set_value ("settings-geometry", builder.end ());
  }
}
