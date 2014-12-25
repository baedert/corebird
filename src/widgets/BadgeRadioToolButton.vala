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


public class BadgeRadioToolButton : Gtk.RadioButton {
  private static const int BADGE_SIZE = 10;
  public bool show_badge{ get; set; default = false;}

  public BadgeRadioToolButton (Gtk.RadioButton group, string icon_name, string text="") {
    GLib.Object (group: group);
    this.get_style_context ().add_class ("image-button");
    var i = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.BUTTON);
    this.add (i);
    this.set_mode (false);
    this.focus_on_click = false;

    if (text != "") {
      this.tooltip_text = text;
      Atk.Object accessible = this.get_accessible ();
      accessible.set_name (text);
    }
  }

  public override bool draw (Cairo.Context c){
    var context = this.get_style_context ();
    base.draw (c);
    if (!show_badge)
      return false;


    int width = get_allocated_width ();
    context.save ();
    context.add_class ("badge");
    context.render_background (c, width - BADGE_SIZE, 0, BADGE_SIZE, BADGE_SIZE);
    context.render_frame (c, width - BADGE_SIZE, 0, BADGE_SIZE, BADGE_SIZE);
    context.restore ();
    return false;
  }
}
