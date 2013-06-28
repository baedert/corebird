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


[GtkTemplate (ui = "/org/baedert/corebird/ui/account-create-widget.ui")]
class AccountCreateWidget : Gtk.Grid {
  [GtkChild]
  private Entry pin_entry;
  private unowned Account acc;
  public signal void result_received (bool result, Account acc);

  public AccountCreateWidget (Account acc){
    this.acc = acc;
  }

  [GtkCallback]
  private void request_pin_button_clicked () {
    acc.init_proxy (false);
    acc.proxy.request_token ("oauth/request_token", "oob");
    GLib.AppInfo.launch_default_for_uri(
					"http://twitter.com/oauth/authorize?oauth_token=%s"
	              .printf(acc.proxy.get_token()), null);

  }

  [GtkCallback]
  private void confirm_button_clicked () {
    try {
      acc.proxy.access_token("oauth/access_token", pin_entry.get_text());
    } catch (GLib.Error e) {
      critical (e.message);
      result_received (false, acc);
      return;
    }
    
    // The token and token secret have been successfully received
    // So, get some account information
    var call = acc.proxy.new_call ();
    call.set_function ("1.1/account/settings.json");
    call.set_method ("GET");
    call.invoke_async.begin (null, (obj, res) => {
      message ("settings call");
      var parser = new Json.Parser ();
      parser.load_from_data (call.get_payload ());
      var root = parser.get_root ().get_object ();
      string screen_name = root.get_string_member ("screen_name");
      acc.query_user_info_by_scren_name.begin (screen_name, (obj, res) => {
        acc.query_user_info_by_scren_name.end (res);
        message ("user info call");
        acc.init_database ();
        acc.save_info();
        try {
          acc.db.execute ("INSERT INTO `common`(token, token_secret) VALUES ('%s', '%s');"
                          .printf (acc.proxy.token, acc.proxy.token_secret));
        } catch (SQLHeavy.Error e) {
          critical (e.message);
        }
        result_received (true, acc);
      });
    });
  }

}
