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
  private static const string PAGE_NORMAL = "normal";
  private static const string PAGE_DELETE = "delete";
  [GtkChild]
  private Gtk.Entry name_entry;
  [GtkChild]
  private AvatarBannerWidget avatar_banner_widget;
  [GtkChild]
  private Gtk.Stack delete_stack;
  [GtkChild]
  private Gtk.Switch autostart_switch;
  [GtkChild]
  private Gtk.Entry website_entry;
  [GtkChild]
  private CompletionTextView description_text_view;

  private unowned Account account;
  private string old_user_name;
  private string old_description;
  private string old_website;
  private Gdk.Pixbuf? new_avatar = null;
  private Gdk.Pixbuf? new_banner = null;



  public AccountDialog (Account account) {
    GLib.Object (use_header_bar: Gtk.Settings.get_default ().gtk_dialogs_use_header ? 1 : 0);
    set_default_response (Gtk.ResponseType.CLOSE);
    this.account = account;
    name_entry.text = account.name;
    avatar_banner_widget.set_account (account);
    description_text_view.set_account (account);
    set_transient_data (account.website, account.description);

    autostart_switch.freeze_notify ();
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    foreach (unowned string acc in startup_accounts) {
      if (acc == this.account.screen_name) {
        autostart_switch.active = true;
        break;
      }
    }
    autostart_switch.thaw_notify ();

    avatar_banner_widget.avatar_changed.connect ((p) => {
       new_avatar = p;
    });

    avatar_banner_widget.banner_changed.connect ((b) => {
      new_banner = b;
    });

    if (account.proxy == null) {
      account.init_proxy ();
      account.query_user_info_by_screen_name.begin (null, (obj, res) => {
        set_transient_data (account.website, account.description);
      });
    }
  }

  private void set_transient_data (string? website, string? description) {
    website_entry.text = account.website ?? "";
    old_user_name = account.name;
    old_website = account.website ?? "";
    old_description = account.description ?? "";
    description_text_view.get_buffer ().set_text (account.description ?? "");
  }

  public override void response (int response_id) {
    if (response_id == Gtk.ResponseType.CLOSE) {
      save_data ();
      this.destroy ();
    } else if (response_id == Gtk.ResponseType.CANCEL) {
      this.destroy ();
    }
  }

  [GtkCallback]
  private void delete_button_clicked_cb () {
    delete_stack.visible_child_name = PAGE_DELETE;
  }

  private void save_data () {
    bool needs_save = (old_user_name != name_entry.text) ||
                      (old_description != description_text_view.buffer.text) ||
                      (old_website != website_entry.text);

    bool needs_init = needs_save || (new_avatar != null) || (new_banner != null);

    if (needs_init && account.proxy == null) {
      account.init_proxy ();
    }


    if (needs_save) {
      debug ("Saving data...");
      var call = account.proxy.new_call ();
      call.set_function ("1.1/account/update_profile.json");
      call.set_method ("POST");
      call.add_param ("url", website_entry.text);
      call.add_param ("name", name_entry.text);
      call.add_param ("description", description_text_view.buffer.text);
      call.invoke_async.begin (null, (obj, res) => {
        try {
          call.invoke_async.end (res);
        } catch (GLib.Error e) {
          warning (e.message);
          Utils.show_error_object (call.get_payload (), "Could not update profile",
                                   GLib.Log.LINE, GLib.Log.FILE, this);
        }
      });

      /* Update local user data */
      account.name = name_entry.text;
      account.description = description_text_view.buffer.text;
      account.website = website_entry.text;
    }

    if (new_avatar != null) {
      debug ("Updating avatar...");
      uint8[] buffer;
      try {
        new_avatar.save_to_buffer (out buffer, "png", null);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }
      string b64 = GLib.Base64.encode (buffer);

      var call = account.proxy.new_call ();
      call.set_function ("1.1/account/update_profile_image.json");
      call.set_method ("POST");
      call.add_param ("skip_status", "true");
      call.add_param ("include_entities", "false");
      call.add_param ("image", b64);
      call.invoke_async.begin (null, (obj, res) => {
        try {
          call.invoke_async.end (res);
        } catch (GLib.Error e) {
          Utils.show_error_object (call.get_payload (), "Could not update your avatar",
                                   GLib.Log.LINE, GLib.Log.FILE, this);
          return;
        }

        /* Locally set new avatar */
        var s = Gdk.cairo_surface_create_from_pixbuf (new_avatar, 1, null);
        account.set_new_avatar (s);
      });
    }

    if (new_banner != null) {
      debug ("Updating banner...");
      uint8[] buffer;
      // XXX With large banners, this can be too slow...
      try {
        new_banner.save_to_buffer (out buffer, "png", null);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }
      string b64 = GLib.Base64.encode (buffer);

      var call = account.proxy.new_call ();
      call.set_function ("1.1/account/update_profile_banner.json");
      call.set_method ("POST");

      call.add_param ("banner", b64);
      call.invoke_async.begin (null, (obj, res) => {
        try {
          call.invoke_async.end (res);
        } catch (GLib.Error e) {
          Utils.show_error_object (call.get_payload (), "Could not update your avatar",
                                   GLib.Log.LINE, GLib.Log.FILE, this);
        }
      });
    }
  }

  [GtkCallback]
  private void delete_confirm_button_clicked_cb () {
    /*
       - Close open window of that account
       - Remove the account from the db, disk, etc.
       - Remove the account from the app menu
       - If this would close the last opened window,
         set the account of that window to NULL
     */
    int64 acc_id = account.id;
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id).db"));
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id).png"));
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id)_small.png"));
    Corebird.db.exec (@"DELETE FROM `accounts` WHERE `id`='$(acc_id)';");

    /* Remove account from startup accounts, if it's in there */
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
    Account acc_to_remove = Account.query_account_by_id (account.id);
    cb.account_removed (acc_to_remove);
    Account.remove_account (account.screen_name);


    /* Close this dialog */
    this.destroy ();
  }

  [GtkCallback]
  private void delete_cancel_button_clicked_cb () {
    delete_stack.visible_child_name = PAGE_NORMAL;
  }

  [GtkCallback]
  private void autostart_switch_activate_cb () {
    bool active = autostart_switch.active;
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    if (active) {
      foreach (unowned string acc in startup_accounts) {
        if (acc == this.account.screen_name) {
          return;
        }
      }

      string[] new_startup_accounts = new string[startup_accounts.length + 1];
      int i = 0;
      foreach (unowned string s in startup_accounts) {
        new_startup_accounts[i] = s;
        i ++;
      }
      new_startup_accounts[new_startup_accounts.length - 1] = this.account.screen_name;
      Settings.get ().set_strv ("startup-accounts", new_startup_accounts);
    } else {
      string[] new_startup_accounts = new string[startup_accounts.length - 1];
      int i = 0;
      foreach (unowned string acc in startup_accounts) {
        if (acc != this.account.screen_name) {
          new_startup_accounts[i] = acc;
          i ++;
        }
      }
      Settings.get ().set_strv ("startup-accounts", new_startup_accounts);
    }
  }
}
