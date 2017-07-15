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

public class AccountManager : GLib.Object {
  private GLib.GenericArray<Account> accounts;

  public AccountManager () {
    this.accounts = new GLib.GenericArray<Account> ();

    Corebird.db.select ("accounts").cols ("id", "screen_name", "name", "avatar_url").run ((vals) => {
      Account acc = new Account (int64.parse(vals[0]), vals[1], vals[2]);
      acc.avatar_url = vals[3];
      this.accounts.add (acc);
      return true;
    });
  }

  public Account get_nth (uint i) {
    return accounts.get (i);
  }

  public uint get_n () {
    return accounts.length;
  }

  public void add_account (Account acc) {
    this.accounts.add (acc);
  }

  public void remove_account (string screen_name) {
    for (uint i = 0; i < accounts.length; i ++) {
      var a = accounts.get (i);
      if (a.screen_name == screen_name) {
        accounts.remove (a);
        return;
      }
    }
  }

  public Account? query_account_by_screen_name (string screen_name) {
    for (uint i = 0; i < accounts.length; i ++) {
      unowned Account a = accounts.get (i);

      if (screen_name == a.screen_name ||
          screen_name == "@" + a.screen_name)
        return a;
    }
    return null;
  }

  public Account? query_account_by_id (int64 id) {
    for (uint i = 0; i < accounts.length; i ++) {
      unowned Account a = accounts.get (i);
      if (id == a.id)
        return a;
    }
    return null;
  }
}
