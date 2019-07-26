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

public class BadgeRadioButton : Gtk.Widget {
  private Gtk.RadioButton button;
  private const int BADGE_SIZE = 10;
  private bool _show_badge = false;
  public bool show_badge {
    set {
      debug ("New show_badge value: %s", value ? "true" : "false");
      if (value != this._show_badge) {
        this._show_badge = value;
        this.queue_draw ();
      }
    }
    get {
      return this._show_badge;
    }
  }

  public bool active {
    set { this.button.active = value; }
    get { return this.button.active;  }
  }

  public BadgeRadioButton (Gtk.RadioButton group, string icon_name, string text="") {
    this.button = new Gtk.RadioButton.from_widget (group);
    this.button.set_parent (this);

    this.button.get_style_context ().add_class ("image-button");
    var i = new Gtk.Image.from_icon_name (icon_name);
    this.button.add (i);
    this.focus_on_click = false;
    this.hexpand = true;
    this.button.set_draw_indicator (false);

    if (text != "") {
      this.tooltip_text = text;
      Atk.Object accessible = this.get_accessible ();
      accessible.set_name (text);
    }
  }

  public Gtk.Widget get_child () {
    return this.button.get_child ();
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    base.snapshot (snapshot);

    if (show_badge && this.get_child () != null) {
      Gtk.Allocation child_allocation;
      Gtk.Allocation allocation;
      this.get_child ().get_allocation (out child_allocation);
      this.get_allocation (out allocation);

      Graphene.Rect bounds = {};
      bounds.origin.x = allocation.x - child_allocation.x + child_allocation.width - BADGE_SIZE;
      bounds.origin.y = 5;
      bounds.size.width  = BADGE_SIZE;
      bounds.size.height = BADGE_SIZE;

      //snapshot.append (bounds, "badge", null);
      var context = this.get_style_context ();

      context.save ();
      context.add_class ("badge");
      snapshot.render_background (context, bounds.origin.x, bounds.origin.y, BADGE_SIZE, BADGE_SIZE);
      snapshot.render_frame      (context, bounds.origin.x, bounds.origin.y, BADGE_SIZE, BADGE_SIZE);
      context.restore ();
    }
  }

  public override void measure (Gtk.Orientation orientation, int for_size,
                                out int minimum, out int natural,
                                out int minimum_baseline, out int natural_baseline) {
    int min, nat;

    this.button.measure (orientation, for_size, out min, out nat, null, null);

    minimum = min;
    natural = nat;
    minimum_baseline = -1;
    natural_baseline = -1;
  }

  public override void size_allocate (int width, int height, int baseline) {
    Gtk.Allocation a = {0, 0, width, height};
    this.button.size_allocate_emit (a, baseline);
  }

  public Gtk.RadioButton get_radio_button () {
    return this.button;
  }
}
