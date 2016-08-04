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

public abstract class NotificationItem : GLib.Object {
  public abstract bool should_merge (NotificationItem item);
  public abstract void merge        (NotificationItem item);
}

public class RetweetNotificationItem : NotificationItem {
  private GLib.GenericArray<Cb.UserIdentity?> users;
  public int64 tweet_id = 0;
  public string tweet_text = "PENIS";

  public RetweetNotificationItem (int64 tweet_id, string tweet_text) {
    this.users = new GLib.GenericArray<Cb.UserIdentity?> ();
    this.tweet_id = tweet_id;
    this.tweet_text = tweet_text;
  }

  public override bool should_merge (NotificationItem other) {
    if (!(other is RetweetNotificationItem))
      return false;

    var other_rt = (RetweetNotificationItem) other;

    return other_rt.tweet_id == this.tweet_id;
  }

  public override void merge (NotificationItem other) {

  }
}
