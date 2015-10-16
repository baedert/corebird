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



int dm_thread_entry_sort_func (Gtk.ListBoxRow r1,
                               Gtk.ListBoxRow r2) {
  if (r1 is StartConversationEntry)
    return -1;
  else if (r2 is StartConversationEntry)
    return 1;

  if (!(r1 is DMThreadEntry))
    return 1;

  if (((DMThreadEntry)r1).last_message_id >
      ((DMThreadEntry)r2).last_message_id)
    return -1;
  return 1;
}


[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-thread-entry.ui")]
class DMThreadEntry : Gtk.ListBoxRow {
  public static bool equal_func (DMThreadEntry a, DMThreadEntry b) {
    return a.user_id == b.user_id;
  }
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
  private Gtk.Label screen_name_label;
  [GtkChild]
  private Gtk.Label last_message_label;
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Label unread_count_label;
  public string avatar_url;
  public int64 user_id {public get; private set;}
  public new string name {
    get {
      return name_label.label;
    }
    set {
      name_label.label = value;
    }
  }
  public string screen_name {
    get{
      return screen_name_label.label;
    }
    set {
      screen_name_label.label = "@" + value;
    }
  }
  public string last_message {
    get {
      return last_message_label.label;
    }
    set {
      last_message_label.label = value;
    }
  }
  public int64 last_message_id {get; set;}
  public Cairo.Surface avatar {
    set { avatar_image.surface = value;}
    owned get { return avatar_image.surface; }
  }

  private int _unread_count = 0;
  public int unread_count {
    get {
      return this._unread_count;
    }
    set {
      this._unread_count = value;
      this.update_unread_count ();
    }
  }
  public string? notification_id = null;


  public DMThreadEntry (int64 user_id) {
    this.user_id = user_id;
    update_unread_count ();
  }

  public void load_avatar () {
    string url = avatar_url;
    if (this.get_scale_factor () == 2)
      url = url.replace ("_normal", "_bigger");

    avatar_image.surface = Twitter.get ().get_avatar (user_id, url, (a) => {
      avatar_image.surface = a;
    }, 48 * this.get_scale_factor ());
  }

  private void update_unread_count () {
    if (unread_count == 0)
      unread_count_label.hide ();
    else {
      unread_count_label.show ();
      unread_count_label.label = ngettext ("(%d unread)",
                                           "(%d unread)",
                                           unread_count).printf(unread_count);
    }
  }
}

