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
  private Rest.OAuth2Proxy local_proxy;
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

    var uri = "https://mastodon.social/oauth/authorize?client_id=%s".printf ("9qtdj5xMeZBw9QqdcFFf3UBsyAPSDv3-jrZLQHHTjuI") +
              "&redirect_uri=urn:ietf:wg:oauth:2.0:oob" +
              "&scope=read+write+follow+push&response_type=code";
    debug ("Trying to open %s", uri);

    try {
      GLib.AppInfo.launch_default_for_uri (uri, null);
    } catch (GLib.Error e) {
      this.show_error (_("Could not open %s").printf ("<a href=\"" + uri + "\">" + uri + "</a>"));
      Utils.show_error_dialog (e.message, this.main_window);
      critical ("Could not open %s", uri);
      critical (e.message);
    }

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
    Json.Parser parser;
    local_proxy = new Rest.OAuth2Proxy ("9qtdj5xMeZBw9QqdcFFf3UBsyAPSDv3-jrZLQHHTjuI",
                                        "8-d9jiW1cwhrDf15YK9bdXj--mBmQAT8m6piAcePoNA",
                                        "https://mastodon.social/",
                                        false);
    var call = local_proxy.new_call ();
    call.set_method ("POST");
    call.set_function ("oauth/token");
    call.add_param ("client_id", "9qtdj5xMeZBw9QqdcFFf3UBsyAPSDv3-jrZLQHHTjuI");
    call.add_param ("client_secret", "8-d9jiW1cwhrDf15YK9bdXj--mBmQAT8m6piAcePoNA");
    call.add_param ("redirect_uri", "urn:ietf:wg:oauth:2.0:oob");
    call.add_param ("grant_type", "authorization_code");
    call.add_param ("code", pin_entry.get_text ().strip ());
    call.add_param ("scope", "read write follow push");

    try {
      yield call.invoke_async (null);
    } catch (GLib.Error e) {
      show_error (e.message);
      pin_entry.sensitive = true;
      confirm_button.sensitive = true;
      request_pin_button.sensitive = true;
      return;
    }
    parser = new Json.Parser ();
    try {
      parser.load_from_data (call.get_payload ());
    } catch (GLib.Error e) {
      show_error ("Invalid JSON:%s".printf (e.message));
      pin_entry.sensitive = true;
      confirm_button.sensitive = true;
      request_pin_button.sensitive = true;
      return;
    }

    var root = parser.get_root ().get_object ();
    string access_token = root.get_string_member ("access_token");

    // Verify token
    call = local_proxy.new_call ();
    call.set_method ("GET");
    call.set_function ("api/v1/accounts/verify_credentials");
    call.add_header ("Authorization", "Bearer %s".printf (access_token));

    try {
      yield call.invoke_async (null);
    } catch (GLib.Error e) {
      show_error ("Error verifying PIN: %s".printf (e.message));
      pin_entry.sensitive = true;
      confirm_button.sensitive = true;
      request_pin_button.sensitive = true;
      return;
    }

    message ("%s", call.get_payload ());
    parser = new Json.Parser ();
    try {
      parser.load_from_data (call.get_payload ());
    } catch (GLib.Error e) {
      show_error ("Invalid JSON:%s".printf (e.message));
      pin_entry.sensitive = true;
      confirm_button.sensitive = true;
      request_pin_button.sensitive = true;
      return;
    }

    yield acc.set_info_from_json (parser.get_root ().get_object ());

    debug ("user info call");
    acc.init_database ();
    acc.save_info ();
    acc.db.insert ("common")
          .val ("access_token", access_token)
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

  public override void dispose () {
    Account.remove_account (Account.DUMMY);
    base.dispose ();
  }
}
