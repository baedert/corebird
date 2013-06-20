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
  




  /** Static stuff */
  private static Account[] accounts;

  public static unowned Account[] list_accounts () {
    return accounts;
  }


}
