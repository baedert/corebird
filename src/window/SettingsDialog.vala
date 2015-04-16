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

[GtkTemplate (ui = "/org/baedert/corebird/ui/settings-dialog.ui")]
class SettingsDialog : Gtk.Window {
  [GtkChild]
  private Gtk.Switch on_new_mentions_switch;
  [GtkChild]
  private Gtk.Switch round_avatar_switch;
  [GtkChild]
  private Gtk.Switch on_new_dms_switch;
  [GtkChild]
  private Gtk.ComboBoxText on_new_tweets_combobox;
  [GtkChild]
  private Gtk.Switch auto_scroll_on_new_tweets_switch;
  [GtkChild]
  private Gtk.SpinButton max_media_size_spin_button;
  [GtkChild]
  private Gtk.Stack main_stack;
  [GtkChild]
  private Gtk.Switch double_click_activation_switch;
  [GtkChild]
  private Gtk.ListBox sample_tweet_list;
  [GtkChild]
  private Gtk.Switch remove_trailing_hashtags_switch;
  [GtkChild]
  private Gtk.Switch remove_media_links_switch;

  private TweetListEntry sample_tweet_entry;

  public SettingsDialog (Corebird application) {
    this.application = application;
    this.type_hint   = Gdk.WindowTypeHint.DIALOG;

    // Notifications Page
    Settings.get ().bind ("round-avatars", round_avatar_switch, "active",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-tweets-notify", on_new_tweets_combobox, "active-id",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-mentions-notify", on_new_mentions_switch, "active",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-dms-notify", on_new_dms_switch, "active",
                          SettingsBindFlags.DEFAULT);

    // Interface page
    auto_scroll_on_new_tweets_switch.notify["active"].connect (() => {
      on_new_tweets_combobox.sensitive = !auto_scroll_on_new_tweets_switch.active;
    });
    Settings.get ().bind ("auto-scroll-on-new-tweets", auto_scroll_on_new_tweets_switch, "active",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("max-media-size", max_media_size_spin_button, "value",
                          SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("double-click-activation", double_click_activation_switch,
                          "active", SettingsBindFlags.DEFAULT);


    // Set up sample tweet {{{
    var sample_tweet = new Tweet ();
    sample_tweet.text = "Hey, check out this new #Corebird version! #cool #newisalwaysbetter";
    sample_tweet.screen_name = "corebirdclient";
    sample_tweet.user_name = "Corebird";
    Gdk.Pixbuf? a = null;
    try {
      a = Gtk.IconTheme.get_default ().load_icon ("corebird", 48,
                                                  Gtk.IconLookupFlags.FORCE_SIZE);
    } catch (GLib.Error e) {
      warning (e.message);
      // Ignore.
    }
    sample_tweet.avatar = a;


    sample_tweet.urls = new TextEntity[3];
    sample_tweet.urls[0] = TextEntity () {
      from = 24,
      to = 33,
      display_text = "#Corebird",
      target = "somewhere" // doesn't matter here
    };
    sample_tweet.urls[1] = TextEntity () {
      from = 43,
      to = 48,
      display_text = "#cool",
      target = "foo"
    };
    sample_tweet.urls[2] = TextEntity () {
      from = 49,
      to = 67,
      display_text = "#newisalwaysbetter",
      target = "foobar"
    };

    // Just to be sure
    TweetUtils.sort_entities (ref sample_tweet.urls);


    this.sample_tweet_entry = new TweetListEntry (sample_tweet, null,
                                                  new Account (10, "", ""));
    sample_tweet_entry.activatable = false;
    sample_tweet_entry.read_only = true;
    this.sample_tweet_list.add (sample_tweet_entry);
    // }}}

    var text_transform_flags = Settings.get_text_transform_flags ();

    remove_trailing_hashtags_switch.active = (TransformFlags.REMOVE_TRAILING_HASHTAGS in
                                              text_transform_flags);
    remove_media_links_switch.active = (TransformFlags.REMOVE_MEDIA_LINKS in text_transform_flags);

    add_accels ();
    load_geometry ();
  }

  [GtkCallback]
  private bool window_destroy_cb () {
    save_geometry ();
    return false;
  }

  private void load_geometry () {
    GLib.Variant geom = Settings.get ().get_value ("settings-geometry");
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    x = geom.get_child_value (0).get_int32 ();
    y = geom.get_child_value (1).get_int32 ();
    w = geom.get_child_value (2).get_int32 ();
    h = geom.get_child_value (3).get_int32 ();
    if (w == 0 || h == 0)
      return;

    move (x, y);
    resize (w, h);
  }

  private void save_geometry () {
    var builder = new GLib.VariantBuilder (GLib.VariantType.TUPLE);
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    get_position (out x, out y);
    w = get_allocated_width ();
    h = get_allocated_height ();
    builder.add_value (new GLib.Variant.int32(x));
    builder.add_value (new GLib.Variant.int32(y));
    builder.add_value (new GLib.Variant.int32(w));
    builder.add_value (new GLib.Variant.int32(h));
    Settings.get ().set_value ("settings-geometry", builder.end ());
  }

  private void add_accels () {
    Gtk.AccelGroup ag = new Gtk.AccelGroup();

    ag.connect (Gdk.Key.Escape, 0, Gtk.AccelFlags.LOCKED,
        () => {this.destroy (); return true;});
    ag.connect (Gdk.Key.@1, Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.LOCKED,
        () => {main_stack.visible_child_name = "interface"; return true;});
    ag.connect (Gdk.Key.@2, Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.LOCKED,
        () => {main_stack.visible_child_name = "notifications"; return true;});
    ag.connect (Gdk.Key.@3, Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.LOCKED,
        () => {main_stack.visible_child_name = "tweet"; return true;});

    this.add_accel_group(ag);
  }


  [GtkCallback]
  private void remove_trailing_hashtags_cb () {
    if (remove_trailing_hashtags_switch.active) {
      Settings.add_text_transform_flag (TransformFlags.REMOVE_TRAILING_HASHTAGS);
    } else {
      Settings.remove_text_transform_flag (TransformFlags.REMOVE_TRAILING_HASHTAGS);
    }
  }

  [GtkCallback]
  private void remove_media_links_cb () {
    if (remove_media_links_switch.active) {
      Settings.add_text_transform_flag (TransformFlags.REMOVE_MEDIA_LINKS);
    } else {
      Settings.remove_text_transform_flag (TransformFlags.REMOVE_MEDIA_LINKS);
    }
  }
}
