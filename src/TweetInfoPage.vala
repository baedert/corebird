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
using Gtk;
[GtkTemplate (ui = "/org/baedert/corebird/ui/tweet-info-page.ui")]
class TweetInfoPage : IPage , Gtk.Box {
  public int unread_count { get{return 0;} set {} }
  private int id;
  public unowned MainWindow main_window { get; set; }
  public unowned Account account { get; set; }

  [GtkChild]
  private Label text_label;
  [GtkChild]
  private Label author_label;
  [GtkChild]
  private Image avatar_image;
  [GtkChild]
  private Label retweets_label;
  [GtkChild]
  private Label favorites_label;



  public TweetInfoPage (int id) {
    this.id = id;
  }

  public void on_join (int page_id, va_list args){
    Tweet tweet = args.arg ();
    if (tweet == null)
      return;

    GLib.DateTime created_at = new GLib.DateTime.from_unix_local (tweet.created_at);
    string time_format = created_at.format ("%x, %X");

    text_label.label = "<b><i><big><big><big>»"+tweet.get_formatted_text ()+"«</big></big></big></i></b>";
    author_label.label = "- "+tweet.user_name + " at " + time_format;
    avatar_image.pixbuf = tweet.avatar;
    retweets_label.label = _("Retweets: ") + tweet.retweet_count.to_string ();
    favorites_label.label = _("Favorites: ") + tweet.favorite_count.to_string ();

    if (tweet.reply_id != 0) {

    }
  }

  public int get_id () {
    return id;
  }

  public void create_tool_button (Gtk.RadioToolButton? group) {
  }

  public Gtk.RadioToolButton? get_tool_button () {
    return null;
  }

}
