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
  [GtkChild]
  private Gtk.Switch hide_nsfw_content_switch;
  [GtkChild]
  private Gtk.ListBox snippet_list_box;

  private TweetListEntry sample_tweet_entry;

  public SettingsDialog (Corebird application) {
    this.application = application;

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

    // Tweets page

    // Set up sample tweet {{{
    var sample_tweet = new Tweet ();
    sample_tweet.source_tweet = new MiniTweet();
    sample_tweet.source_tweet.author = UserIdentity() {
      id = 12,
      screen_name = "corebirdclient",
      user_name = "Corebird"
    };
    string sample_text = _("Hey, check out this new #Corebird version! \\ (•◡•) / #cool #newisalwaysbetter");
    Cairo.Surface? avatar_surface = null;
    try {
      var a = Gtk.IconTheme.get_default ().load_icon ("corebird",
                                                      48 * this.get_scale_factor (),
                                                      Gtk.IconLookupFlags.FORCE_SIZE);
      avatar_surface = Gdk.cairo_surface_create_from_pixbuf (a, this.get_scale_factor (), this.get_window ());
    } catch (GLib.Error e) {
      warning (e.message);
    }
    sample_tweet.source_tweet.text = sample_text;

    try {
      var regex = new GLib.Regex ("#\\w+");
      GLib.MatchInfo match_info;
      bool matched = regex.match (sample_text, 0, out match_info);
      assert (matched);

      sample_tweet.source_tweet.entities = new TextEntity[3];

      int i = 0;
      while (match_info.matches ()) {
        assert (match_info.get_match_count () == 1);
        int from, to;
        match_info.fetch_pos (0, out from, out to);
        string match = match_info.fetch (0);
        sample_tweet.source_tweet.entities[i] = TextEntity () {
          from = sample_text.char_count (from),
          to   = sample_text.char_count (to),
          display_text = match,
          target       = "foobar"
        };

        match_info.next ();
        i ++;
      }
    } catch (GLib.RegexError e) {
      critical (e.message);
    }

    // Just to be sure
    TweetUtils.sort_entities (ref sample_tweet.source_tweet.entities);


    this.sample_tweet_entry = new TweetListEntry (sample_tweet, null,
                                                  new Account (10, "", ""));
    sample_tweet_entry.set_avatar (avatar_surface);
    sample_tweet_entry.activatable = false;
    sample_tweet_entry.read_only = true;
    sample_tweet_entry.show ();
    this.sample_tweet_list.add (sample_tweet_entry);
    // }}}

    var text_transform_flags = Settings.get_text_transform_flags ();

    remove_trailing_hashtags_switch.active = (TransformFlags.REMOVE_TRAILING_HASHTAGS in
                                              text_transform_flags);
    remove_media_links_switch.active = (TransformFlags.REMOVE_MEDIA_LINKS in text_transform_flags);


    Settings.get ().bind ("hide-nsfw-content", hide_nsfw_content_switch, "active",
                          SettingsBindFlags.DEFAULT);


    // Fill snippet list box
    Corebird.snippet_manager.query_snippets ((key, value) => {
      var e = new SnippetListEntry (key, value);
      e.show_all ();
      snippet_list_box.add (e);
    });

    add_accels ();
    load_geometry ();
  }

  [GtkCallback]
  private bool window_destroy_cb () {
    save_geometry ();
    return Gdk.EVENT_PROPAGATE;
  }

  [GtkCallback]
  private void snippet_entry_activated_cb (Gtk.ListBoxRow row) {
    var snippet_row = (SnippetListEntry) row;
    var d = new ModifySnippetDialog (snippet_row.key,
                                     snippet_row.value);
    d.snippet_updated.connect (snippet_updated_func);
    d.set_transient_for (this);
    d.modal = true;
    d.show ();
  }

  [GtkCallback]
  private void add_snippet_button_clicked_cb () {
    var d = new ModifySnippetDialog ();
    d.snippet_updated.connect (snippet_updated_func);
    d.set_transient_for (this);
    d.modal = true;
    d.show ();
  }

  private void snippet_updated_func (string? old_key, string? key, string? value) {
    if (old_key != null && key == null && value == null) {
      foreach (var _row in snippet_list_box.get_children ()) {
        var srow = (SnippetListEntry) _row;
        if (srow.key == old_key) {
          srow.reveal ();
          break;
        }
      }
      return;
    }

    if (old_key == null) {
      var e = new SnippetListEntry (key, value);
      e.show_all ();
      snippet_list_box.add (e);
    } else {
      foreach (var _row in snippet_list_box.get_children ()) {
        var srow = (SnippetListEntry) _row;
        if (srow.key == old_key) {
          srow.key = key;
          srow.value = value;
          break;
        }
      }
    }
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

    this.move (x, y);
    this.set_default_size (w, h);
  }

  private void save_geometry () {
    var builder = new GLib.VariantBuilder (GLib.VariantType.TUPLE);
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    this.get_position (out x, out y);
    this.get_size (out w, out h);
    builder.add_value (new GLib.Variant.int32(x));
    builder.add_value (new GLib.Variant.int32(y));
    builder.add_value (new GLib.Variant.int32(w));
    builder.add_value (new GLib.Variant.int32(h));
    Settings.get ().set_value ("settings-geometry", builder.end ());
  }

  private void add_accels () {
    Gtk.AccelGroup ag = new Gtk.AccelGroup();

    ag.connect (Gdk.Key.Escape, 0, Gtk.AccelFlags.LOCKED,
        () => {this.close (); return true;});
    ag.connect (Gdk.Key.@1, Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.LOCKED,
        () => {main_stack.visible_child_name = "interface"; return true;});
    ag.connect (Gdk.Key.@2, Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.LOCKED,
        () => {main_stack.visible_child_name = "notifications"; return true;});
    ag.connect (Gdk.Key.@3, Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.LOCKED,
        () => {main_stack.visible_child_name = "tweet"; return true;});
    ag.connect (Gdk.Key.@4, Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.LOCKED,
        () => {main_stack.visible_child_name = "snippets"; return true;});


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
