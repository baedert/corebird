/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2016 Timm Bäder
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

const int TIMEOUT_S = 30;

public class AccountService: GLib.Object {
  private unowned Account account;

  public AccountService (Account account) {
    this.account = account;
  }

  public void start () {
    debug ("AccountService for %s started", account.screen_name);

    GLib.Timeout.add (TIMEOUT_S * 1000, this.timeout_cb);
  }

  public void stop () {
    debug ("AccountService for %s stopped", account.screen_name);
  }

  private bool timeout_cb () {
    var call = account.proxy.new_call ();
    call.set_method ("GET");
    call.set_function ("1.1/statuses/retweets_of_me.json");
    call.add_param ("count", "20");

    call.sync ();

    stdout.printf ("%s\n", call.get_payload ());

    return GLib.Source.CONTINUE;
  }
}
