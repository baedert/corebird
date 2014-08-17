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

public class AvatarBannerWidget : Gtk.Widget {
  private Gdk.Pixbuf? banner;
  private Gdk.Pixbuf? avatar;
  public int avatar_size { get; set; default = 48; }

  public AvatarBannerWidget (Account account) {
    this.avatar = account.avatar;
  }

  construct {
    this.set_has_window (false);
  }

  private async void load_banner () {

  }

  public override bool draw (Cairo.Context ct) {

    return true;
  }

  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void get_preferred_width (out int min,
                                            out int nat) {

    min = avatar_size + 40; // 20px margin on either side

    if (banner != null) {
      nat = banner.get_width ();
    } else {
      nat = min;
    }
  }

  public override void get_preferred_height_for_width (int width,
                                                   out int min,
                                                   out int nat){
    if (banner != null) {
      double ratio = (double) banner.get_width () / (double) banner.get_height ();
      nat = (int)(banner.get_height () * ratio);
      min = (int)(banner.get_height () * ratio);
    } else {
      nat = avatar_size;
      min = avatar_size;
    }
  }
}
