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
  private Database db        {public get; private set;}
  

  public Account (int64 id) {
    this.id = id;
  }




  /** Static stuff */
  private static GLib.List<Account> accounts = null;

  public static unowned GLib.List<Account> list_accounts () {
    return accounts;
  }
  /**
   * Look up the accounts. Each account has a <id>.db in ~/.corebird/accounts/
   * The accounts are initialized with only their screen_name and their ID.
   */
  private static void lookup_accounts () {
    File accounts_dir = File.new_for_path (Utils.user_file ("accounts/"));
    var enumerator = accounts_dir.enumerate_children (FileAttribute.STANDARD_NAME, 
                                                      FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
    // Each of the accounts files ends with '.db'
    FileInfo info = null;
    while ((info = enumerator.next_file ()) != null) {
      string file_name = info.get_name ();
      int64 user_id = int64.parse (file_name.substring (file_name.length - 3));
      Account acc = new Account (user_id);
      
      accounts.append (acc);
    }

  }

}
