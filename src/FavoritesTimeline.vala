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

using Gtk;

class FavoritesTimeline : IMessageReceiver, DefaultTimeline {

  public FavoritesTimeline(int id) {
    base (id);
  }

  private void stream_message_received (StreamMessageType type, Json.Node root) { // {{{
    if (type == StreamMessageType.EVENT_FAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
    } else if (type == StreamMessageType.EVENT_UNFAVORITE) {
      int64 id = root.get_object ().get_object_member ("target_object").get_int_member ("id");
      delete_tweet (id);
    }
  } // }}}


  public override void load_newest () {
    this.loading = true;
    this.load_newest_internal.begin ("1.1/favorites/list.json",  () => {
      this.loading = false;
    });
  }

  public override void load_older () {
    this.balance_next_upper_change (BOTTOM);
    main_window.start_progress ();
    this.loading = true;
    this.load_older_internal.begin ("1.1/favorites/list.json", () => {
      this.loading = false;
      main_window.stop_progress ();
    });
  }

  public override void create_tool_button(RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "corebird-favorite-symbolic");
    tool_button.tooltip_text = _("Favorites");
    tool_button.label = _("Favorites");
  }
}
