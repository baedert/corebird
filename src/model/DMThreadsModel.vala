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

class DMThread : GLib.Object {
  public UserIdentity user; /* id, name, screen_name */
  public int64  last_message_id;
  public string last_message;
  public int unread_count = 0;
  public string? notification_id = null;

  public Cairo.Surface? avatar_surface = null;

  public async void load_avatar (Account account, int scale_factor) {
    assert (this.user.id != 0);

    if (this.avatar_surface != null)
      return;

    this.avatar_surface = yield Twitter.get ().load_avatar_for_user_id (account,
                                                                        user.id,
                                                                        48 * scale_factor);
    Twitter.get ().ref_avatar (this.avatar_surface);
  }

  ~DMThread () {
    if (this.avatar_surface != null)
      Twitter.get ().unref_avatar (this.avatar_surface);
  }
}

/* Let's hope there aren't a lof of threads */
class DMThreadsModel : GLib.ListModel, GLib.Object {
  private Gee.ArrayList<DMThread> threads = new Gee.ArrayList<DMThread> ();

  public GLib.Object? get_item (uint index) {
    return this.threads.get ((int)index);
  }

  public uint get_n_items () {
    return (uint) this.threads.size;
  }

  public GLib.Type get_item_type () {
    return typeof (DMThread);
  }

  public void add (DMThread thread) {
    bool added = false;
    for (int i = 0; i < threads.size; i ++) {
      if (thread.last_message_id > threads.get (i).last_message_id) {
        this.threads.insert (i, thread);
        this.items_changed (i, 0, 1);
        added = true;
        break;
      }
    }

    if (!added) {
      this.threads.add (thread);
      this.items_changed (this.threads.size - 1, 0, 1);
    }

  }

  public void update_last_message (int64 sender_id, int64 message_id, string message_text) {
#if DEBUG
    assert (this.has_thread (sender_id));
#endif

    int index = 0;
    foreach (var thread in this.threads) {
      if (thread.user.id == sender_id) {
        if (message_id > thread.last_message_id) {
          thread.last_message_id = message_id;
          thread.last_message = message_text;
          this.threads.remove (thread);
          this.items_changed (index, 1, 0);
          this.add (thread);
        } else {
          warning ("id %s is < than %s", message_id.to_string (), thread.last_message_id.to_string ());
        }
        /* Don't call items_changed, the caller DMManager has to call thread_changed */
        break;
      }
      index ++;
    }
  }

  public bool has_thread (int64 user_id) {
    foreach (var thread in this.threads) {
      if (thread.user.id == user_id)
        return true;
    }

    return false;
  }

  public int reset_unread_count (int64 user_id) {
    foreach (var thread in this.threads) {
      if (thread.user.id == user_id) {
        int k = thread.unread_count;
        thread.unread_count = 0;
        return k;
      }
    }

    return 0;
  }

  public string? reset_notification_id (int64 user_id) {
    foreach (var thread in this.threads) {
      if (thread.user.id == user_id) {
        string k = thread.notification_id;
        thread.notification_id = null;
        return k;
      }
    }

    return null;
  }

  public void increase_unread_count (int64 user_id, int amount = 1) {
    foreach (var thread in this.threads) {
      if (thread.user.id == user_id) {
        thread.unread_count += amount;
        /* Don't call items_changed, the caller DMManager has to call thread_changed */
        break;
      }
    }
  }

  public DMThread? get_thread (int64 user_id) {
    foreach (var thread in this.threads) {
      if (thread.user.id == user_id) {
        return thread;
      }
    }

    return null;
  }
}
