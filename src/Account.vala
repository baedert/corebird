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
  public int64 id            {public get; private set;}
  public string screen_name  {public get; private set;}
  public string name         {public get; private set;}
  public Database db         {public get; private set;}
  public Rest.Proxy proxy    {public get; private set;}
  

  public Account (int64 id, string screen_name, string name) {
    this.id = id;
    this.screen_name = screen_name;
    this.name = name;
    this.proxy = Twitter.proxy;
  }

  public void init_database () {
    this.db = new VersionedDatabase (Utils.user_file (@"accounts/$id.db"),
                                     DATADIR+"/sql/accounts");
  }

  public async void query_user_info_by_scren_name (string screen_name) {
    this.screen_name = screen_name;
    var call = proxy.new_call ();
    call.set_function ("1.1/users/show.json");
    call.set_method ("GET");
    call.add_param ("screen_name", screen_name);
    call.invoke_async.begin (null, (obj, res) => {
      var parser = new Json.Parser ();
      parser.load_from_data (call.get_payload ());
      var root = parser.get_root ().get_object ();
      this.id = root.get_int_member ("id");
      this.name = root.get_string_member ("name");
      query_user_info_by_scren_name.callback();
      message("Name: %s", name);
    });

    yield;
  }

  public void save_info () {
    Query q = new Query (db, @"INSERT OR REPLACE INTO `info`(id,screen_name,name) VALUES
        ('$id','$screen_name','$name');");
    q.execute ();

    q = new Query (Corebird.db, @"INSERT OR REPLACE INTO `accounts`(id,screen_name,name) VALUES
        ('$id','$screen_name','$name');");
    q.execute ();
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
    while (!res.finished) {
      Account acc = new Account (res.fetch_int64 (0),
                                 res.fetch_string (1),
                                 res.fetch_string (2));
      accounts.append (acc);
      res.next();
      message("add accounts");
    }
    message("Lookup accounts");
  }
  public static void add_account (Account acc) {
    accounts.append (acc);
  }

}
