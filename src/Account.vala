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

using SQLHeavy;

class Account : GLib.Object {
  private int64 id           {public get; private set;}
  private string screen_name {public get; private set;}
  private string name        {public get; private set;}
  private Database db        {public get; private set;}
  

  public Account (int64 id, string screen_name, string name) {
    this.id = id;
    this.screen_name = screen_name;
    this.name = name;
  }




  /** Static stuff */
  private static GLib.SList<Account> accounts = null;

  /**
   * Simply returns a list of user-specified accounts.
   * The list is lazily loaded from the database
   *
   * @return A singly-linked list of accounts
   */
  public static unowned GLib.SList<Account> list_accounts () {
    if (accounts == null)
      lookup_accounts ();
    return accounts;
  }
  /**
   * Look up the accounts. Each account has a <id>.db in ~/.corebird/accounts/
   * The accounts are initialized with only their screen_name and their ID.
   */
  private static void lookup_accounts () {
    accounts = new GLib.SList<Account> ();
    Query q = new Query (Corebird.db, "SELECT id,screen_name,name FROM `accounts`;");
    QueryResult res = q.execute ();
    while (res.finished) {
      Account acc = new Account (res.fetch_int64 (0),
                                 res.fetch_string (1),
                                 res.fetch_string (2));
      accounts.append (acc);
      res.next();
    }
  }

}
