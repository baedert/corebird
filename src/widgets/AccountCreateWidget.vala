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
public class AccountCreateWidget : Gtk.Box {
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
  [GtkChild]
  private Gtk.Stack content_stack;
  private unowned Account acc;
  private unowned Corebird corebird;
  private unowned Cb.MainWindow main_window;
  private bool request_pin_clicked = false;
  private Rest.OAuthProxy local_proxy;
  public signal void result_received (bool result, Account acc);

  public AccountCreateWidget (Account acc, Corebird corebird, Cb.MainWindow main_window) {
    this.acc = acc;
    this.corebird = corebird;
    this.main_window = main_window;
    info_label.label = "%s <a href=\"https://twitter.com/signup\">%s</a>"
                       .printf (_("Don’t have a Twitter account yet?"), _("Create one"));
    pin_entry.buffer.deleted_text.connect (pin_changed_cb);
    pin_entry.buffer.inserted_text.connect (pin_changed_cb);
  }

  private void open_pin_request_site () {
    local_proxy = new Rest.OAuthProxy (Settings.get_consumer_key (),
                                       Settings.get_consumer_secret (),
                                       "https://api.twitter.com/",
                                       false);
    local_proxy.request_token_async.begin ("oauth/request_token", "oob", null, (obj, res) => {
      try {
        local_proxy.request_token_async.end (res);
      } catch (GLib.Error e) {
        if (e.message.down() == "unauthorized") {
          Utils.show_error_dialog (_("Unauthorized. Most of the time, this means that there’s something wrong with the Twitter servers and you should try again later"), this.main_window);
        } else {
          Utils.show_error_dialog (e.message, this.main_window);
        }
        critical (e.message);
        return;
      }

      string uri = "http://twitter.com/oauth/authorize?oauth_token=" + local_proxy.get_token();
      debug ("Trying to open %s", uri);

      try {
        GLib.AppInfo.launch_default_for_uri (uri, null);
      } catch (GLib.Error e) {
        this.show_error (_("Could not open %s").printf ("<a href=\"" + uri + "\">" + uri + "</a>"));
        Utils.show_error_dialog (e.message, this.main_window);
        critical ("Could not open %s", uri);
        critical (e.message);
      }
    });

    request_pin_clicked = true;
  }

  [GtkCallback]
  private void request_pin_clicked_cb () {
    open_pin_request_site ();
    content_stack.visible_child_name = "pin";
  }

  [GtkCallback]
  private async void confirm_button_clicked_cb () {
    pin_entry.sensitive = false;
    confirm_button.sensitive = false;
    request_pin_button.sensitive = false;

    this.do_confirm.begin ();
  }

  private async void do_confirm () {
    assert (local_proxy != null);
    try {
      yield local_proxy.access_token_async ("oauth/access_token", pin_entry.get_text (), null);
    } catch (GLib.Error e) {
      critical (e.message);
      // We just assume that it was the wrong code
      show_error (_("Wrong PIN"));
      pin_entry.sensitive = true;
      confirm_button.sensitive = true;
      request_pin_button.sensitive = true;
      return;
    }

    var call = local_proxy.new_call ();
    call.set_function ("1.1/account/settings.json");
    call.set_method ("GET");

    Json.Node? root_node;
    try {
      root_node = yield Cb.Utils.load_threaded_async (call, null);
    } catch (GLib.Error e) {
      warning ("Could not get json data: %s", e.message);
      return;
    }

    Json.Object root = root_node.get_object ();
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

    var info_call = local_proxy.new_call ();
    info_call.set_method ("GET");
    info_call.set_function ("1.1/users/show.json");
    info_call.add_param ("screen_name", screen_name);
    info_call.add_param ("skip_status", "true");

    try {
      yield info_call.invoke_async (null);
    } catch (GLib.Error e) {
      warning (e.message);
      return;
    }

    Json.Parser parser = new Json.Parser ();
    try {
      parser.load_from_data (info_call.get_payload ());
    } catch (GLib.Error e) {
      warning ("JSON error: %s.\nData:\n%s", e.message, info_call.get_payload ());
    }

    yield acc.set_info_from_json (parser.get_root ().get_object ());
    debug ("user info call");
    acc.init_database ();
    acc.save_info();
    acc.db.insert ("common")
          .val ("token", local_proxy.token)
          .val ("token_secret", local_proxy.token_secret)
          .run ();
    acc.init_proxy ();
    corebird.account_added (acc);
    result_received (true, acc);
  }

  private void show_error (string err) {
    info_label.visible = false;
    error_label.visible = true;
    error_label.label = err;
  }

  private void pin_changed_cb () {
    message ("Pin changed");
    string text = pin_entry.get_text ();
    bool confirm_possible = text.length > 0 && request_pin_clicked;
    confirm_button.sensitive = confirm_possible;
  }

  public override void destroy () {
    Account.remove_account (Account.DUMMY);
    base.destroy ();
  }
}
