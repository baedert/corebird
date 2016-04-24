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

[GtkTemplate (ui = "/org/baedert/corebird/ui/account-create-widget.ui")]
class AccountCreateWidget : Gtk.Box {
  [GtkChild]
  private Gtk.Entry pin_entry;
  [GtkChild]
  private Gtk.Label error_label;
  [GtkChild]
  private Gtk.Button confirm_button;
  [GtkChild]
  private Gtk.Button request_pin_button;
  [GtkChild]
  private Gtk.Label info_label;
  private unowned Account acc;
  private unowned Corebird corebird;
  private unowned MainWindow main_window;
  public signal void result_received (bool result, Account acc);

  public AccountCreateWidget (Account acc, Corebird corebird, MainWindow main_window) {
    this.acc = acc;
    this.corebird = corebird;
    this.main_window = main_window;
    info_label.label = "%s <a href=\"http://twitter.com/signup\">%s</a>"
                       .printf (_("Don't have an account yet?"), _("Create one"));
    pin_entry.buffer.deleted_text.connect (pin_changed_cb);
    pin_entry.buffer.inserted_text.connect (pin_changed_cb);
  }

  public void open_pin_request_site () {
    acc.init_proxy (false, true);

    string? uri = null;
    try {
      acc.proxy.request_token ("oauth/request_token", "oob");
      uri = "http://twitter.com/oauth/authorize?oauth_token=" + acc.proxy.get_token();
      debug ("Trying to open %s", uri);
    } catch (GLib.Error e) {
      if (e.message.down() == "unauthorized") {
        Utils.show_error_dialog (_("Unauthorized. Most of the time, this means that there's something wrong with the Twitter servers and you should try again later"), this.main_window);
      } else {
        Utils.show_error_dialog (e.message, this.main_window);
      }
      critical (e.message);
      return;
    }

    /* Try to open URI in browser */
    try {
      GLib.AppInfo.launch_default_for_uri (uri, null);
    } catch (GLib.Error e) {
      this.show_error (_("Could not open %s").printf ("<a href=\"" + uri + "\">" + uri + "</a>"));
      Utils.show_error_dialog (e.message, this.main_window);
      critical ("Could not open %s", uri);
      critical (e.message);
    }
  }

  [GtkCallback]
  private void request_pin_clicked_cb () {
    open_pin_request_site ();
  }

  [GtkCallback]
  private void confirm_button_clicked_cb () {
    pin_entry.sensitive = false;
    confirm_button.sensitive = false;
    request_pin_button.sensitive = false;
    try {
      acc.proxy.access_token("oauth/access_token", pin_entry.get_text());
    } catch (GLib.Error e) {
      critical (e.message);
      // We just assume that it was the wrong code
      show_error (_("Wrong PIN"));
      pin_entry.sensitive = true;
      confirm_button.sensitive = true;
      request_pin_button.sensitive = true;
      return;
    }

    // The token and token secret have been successfully received
    // So, get some account information
    var call = acc.proxy.new_call ();
    call.set_function ("1.1/account/settings.json");
    call.set_method ("GET");
    call.invoke_async.begin (null, (obj, res) => {
      var parser = new Json.Parser ();
      try {
        parser.load_from_data (call.get_payload ());
      } catch (GLib.Error e) {
        critical ("Problem with JSON Data: %s\n%s", e.message, call.get_payload ());
      }
      var root = parser.get_root ().get_object ();
      string screen_name = root.get_string_member ("screen_name");
      debug ("Checking for %s", screen_name);
      Account? existing_account = Account.query_account (screen_name);
      if (existing_account != null) {
        result_received (false, existing_account);
        critical ("Account is already in use");
        show_error (_("Account already in use"));
        pin_entry.sensitive = true;
        pin_entry.text = "";
        request_pin_button.sensitive = true;
        return;

      }

      acc.query_user_info_by_screen_name.begin (screen_name, (obj, res) => {
        acc.query_user_info_by_screen_name.end (res);
        debug ("user info call");
        acc.init_database ();
        acc.save_info();
        acc.db.insert ("common")
              .val ("token", acc.proxy.token)
              .val ("token_secret", acc.proxy.token_secret)
              .run ();
        acc.init_proxy (true, true);
        corebird.account_added (acc);
        result_received (true, acc);
      });
    });
  }

  private void show_error (string err) {
    info_label.visible = false;
    error_label.visible = true;
    error_label.label = err;
  }

  private void pin_changed_cb () {
    string text = pin_entry.get_text ();
    bool confirm_possible = text.length > 0 && acc.proxy != null;
    confirm_button.sensitive = confirm_possible;
  }

  [GtkCallback]
  private bool delete_event_cb () {
    Account.remove_account (Account.DUMMY);
    return false;
  }
}
