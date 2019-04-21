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

/* We use the AvatarWidget as a parent of the AvatarContainer widget
   so we can move the latter up in the overlap=TRUE case. */
public class AvatarWidget : Gtk.Widget {
  private const int OVERLAP_DIST = 40;
  public bool overlap  { get; set; default = false; }
  public bool verified {
    get {
      return container_widget.verified;
    }
    set {
      container_widget.verified = value;
      this.queue_draw ();
    }
  }
  private Gdk.Texture _texture;
  public Gdk.Texture texture {
    get { return _texture; }
    set {
      if (this._texture == value) {
        return;
      }

      bool animate = false;

      if (this._texture != null)
        Twitter.get ().unref_avatar (this._texture);
      else
        animate = true;

      this._texture = value;

      if (this._texture != null) {
        Twitter.get ().ref_avatar (this._texture);
        if (animate)
          this.start_animation ();
        else
          container_widget.set_opacity (1.0);
      }

      container_widget.texture = this._texture;
      container_widget.queue_draw ();
    }
  }
  private int _size = 48;
  public int size {
    set {
      this._size = value;
      container_widget.size = value;
      this.queue_resize ();
    }
    get {
      return _size;
    }
  }

  private int64 start_time;
  private AvatarContainer container_widget;

  static construct {
    set_css_name ("avatar");
  }

  construct {
    this.set_has_surface (false);

    container_widget = new AvatarContainer ();
    container_widget.set_parent (this);
    container_widget.set_opacity (0.0);
  }

  ~AvatarWidget () {
    container_widget.unparent ();
  }

  public override void measure (Gtk.Orientation orientation,
                                int for_size,
                                out int min, out int nat,
                                out int min_baseline, out int nat_baseline) {

    int s = _size;
    int m;

    container_widget.measure (orientation, for_size, out m, null, null, null);

    s = int.max (_size, m);

    if (orientation == Gtk.Orientation.HORIZONTAL) {
      min = s;
      nat = s;
    } else {
      if (overlap) {
        min = s - OVERLAP_DIST;
        nat = s - OVERLAP_DIST;
      } else {
        min = s;
        nat = s;
      }
    }

    min_baseline = -1;
    nat_baseline = -1;
  }

  public override void size_allocate (int width, int height, int baseline) {
    Gtk.Allocation child_alloc = {0, 0, width, height};
    if (overlap) {
      int child_height;
      container_widget.measure (Gtk.Orientation.VERTICAL, -1, out child_height, null, null, null);

      child_alloc.y -= OVERLAP_DIST;
      child_alloc.height = child_height;
    }

    container_widget.size_allocate_emit (child_alloc, -1);
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    this.snapshot_child (container_widget, snapshot);
  }

  /* We do the animation here so we can just set the avatar container's opacity,
     which will make the border etc. also transition. */
  public void start_animation () {
    if (!this.get_realized ()) {
      container_widget.set_opacity (1.0);
      return;
    }

    container_widget.set_opacity (0.0);
    this.start_time = this.get_frame_clock ().get_frame_time ();
    this.add_tick_callback (fade_in_cb);
  }

  private bool fade_in_cb (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
    int64 now = frame_clock.get_frame_time ();
    double t = (now - start_time) / (double) TRANSITION_DURATION;

    if (t >= 1.0) {
      t = 1.0;
    }

    container_widget.set_opacity (ease_out_cubic (t));
    this.queue_draw ();

    return t < 1.0;
  }


}

public class AvatarContainer : Gtk.Widget {
  public bool verified = false;
  public int size = 48;
  private const int SMALL = 0;
  private const int LARGE = 1;
  private bool _round = true;
  public bool make_round {
    get {
      return _round;
    }
    set {
      if (value == _round)
        return;

      if (value) {
        this.get_style_context ().add_class ("avatar-round");
      } else {
        this.get_style_context ().remove_class ("avatar-round");
      }
      this._round = value;
      this.queue_draw ();
    }
  }

  public Gdk.Texture texture;


  static Gdk.Texture[] verified_textures;
  const int[] VERIFIED_SIZES = {12, 25};
  static construct {
    try {
      verified_textures = {
        Gdk.Texture.from_resource ("/org/baedert/corebird/data/verified-small.png"),
        Gdk.Texture.from_resource ("/org/baedert/corebird/data/verified-large.png"),
        Gdk.Texture.from_resource ("/org/baedert/corebird/data/verified-small@2.png"),
        Gdk.Texture.from_resource ("/org/baedert/corebird/data/verified-large@2.png"),
      };
    } catch (GLib.Error e) {
      critical (e.message);
    }

    set_css_name ("container");
  }

  construct {
    this.set_has_surface (false);
    Settings.get ().bind ("round-avatars", this, "make_round",
                          GLib.SettingsBindFlags.DEFAULT);
    this.get_style_context ().add_class ("avatar-round"); // default is TRUE
  }

  ~AvatarContainer () {
    if (this.texture != null)
      Twitter.get ().unref_avatar (this.texture);
  }

  public override void snapshot (Gtk.Snapshot snapshot) {
    int width  = this.size;
    int height = this.size;

    if (this.texture == null) {
      return;
    }

    Graphene.Rect bounds = {};
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    bounds.size.width = width;
    bounds.size.height = height;

    if (_round) {
      Gsk.RoundedRect round_clip = {};
      round_clip.init_from_rect (bounds, width); // radius = width => round.
      snapshot.push_rounded_clip (round_clip);
    }

    snapshot.append_texture (this.texture, bounds);

    if (_round) {
      snapshot.pop ();
    }

    if (verified) {
      Graphene.Rect verified_bounds = {};
      float verified_scale = 1.0f;
      int index = SMALL;
      if (width > 48)
        index = LARGE;

      if (index == LARGE && this.size < 100) {
        verified_scale = (float)this.size / 100.0f;
      }

      int scale_factor = this.get_scale_factor () - 1;
      var verified_texture = verified_textures[scale_factor * 2 + index];
      verified_bounds.origin.x = width - (VERIFIED_SIZES[index] * verified_scale);
      verified_bounds.origin.y = 0;
      verified_bounds.size.width = VERIFIED_SIZES[index] * verified_scale;
      verified_bounds.size.height = VERIFIED_SIZES[index] * verified_scale;

      snapshot.append_texture (verified_texture, verified_bounds);
    }
  }

  public override void measure (Gtk.Orientation orientation,
                                int for_size,
                                out int min, out int nat,
                                out int min_baseline, out int nat_baseline) {
    min = size;
    nat = size;

    min_baseline = -1;
    nat_baseline = -1;
  }
}
