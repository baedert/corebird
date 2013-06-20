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

using Notify;


class NotificationManager {

  public static void init(MainWindow window){
    Notify.init("Corebird");
  }


  public static void notify(string summary, string body="",
                            Urgency urgency = Urgency.LOW,
                            Gdk.Pixbuf? pixbuf = null){

    Notification n = new Notification (summary, body, null);

    n.set_urgency(urgency);
    n.set_icon_from_pixbuf(pixbuf);

    try{
      n.show();
    }catch(GLib.Error e){
      message("Error while showing notification: %s", e.message);
    }
  }


  /**
   * Uninitializes the notification manager
   * Should be called when the application gets closed completely.
   */
  public static void uninit(){
    Notify.uninit();
  }

}
