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

[GtkTemplate (ui = "/org/baedert/corebird/ui/compose-window.ui")]
class ComposeTweetWindow : Gtk.ApplicationWindow {
  const int DEFAULT_WIDTH = 450;
  public enum Mode {
    NORMAL,
    REPLY,
    QUOTE
  }
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Grid content_grid;
  [GtkChild]
  private CompletionTextView tweet_text;
  [GtkChild]
  private Gtk.Label length_label;
  [GtkChild]
  private Gtk.Button send_button;
  [GtkChild]
  private Gtk.Spinner title_spinner;
  [GtkChild]
  private Gtk.Label title_label;
  [GtkChild]
  private Gtk.Stack title_stack;
  [GtkChild]
  private ComposeImageManager compose_image_manager;
  [GtkChild]
  private Gtk.Button add_image_button;
  [GtkChild]
  private Gtk.Stack stack;
  [GtkChild]
  private Gtk.Grid image_error_grid;
  [GtkChild]
  private Gtk.Label image_error_label;
  [GtkChild]
  private Gtk.Button cancel_button;
  [GtkChild]
  private FavImageView fav_image_view;
  [GtkChild]
  private Gtk.Button fav_image_button;
  [GtkChild]
  private Gtk.Revealer completion_revealer;
  [GtkChild]
  private Gtk.ListBox completion_list;
  [GtkChild]
  private Gtk.Box add_button_box;
  private Cb.EmojiChooser? emoji_chooser = null;
  private Gtk.Button? emoji_button = null;
  private unowned Account account;
  private unowned Cb.Tweet reply_to;
  private Mode mode;
  private GLib.Cancellable? cancellable;
  private Gtk.ListBox? reply_list = null;
  private Cb.ComposeJob compose_job;


  public ComposeTweetWindow (MainWindow? parent,
                             Account     acc,
                             Cb.Tweet?   reply_to = null,
                             Mode        mode = Mode.NORMAL) {
    this.set_show_menubar (false);
    this.account = acc;
    this.reply_to = reply_to;
    this.mode = mode;
    this.tweet_text.set_account (acc);
    this.application = (Gtk.Application)GLib.Application.get_default ();

    this.cancellable = new GLib.Cancellable ();
    var upload_proxy = new Rest.OAuthProxy (Settings.get_consumer_key (),
                                            Settings.get_consumer_secret (),
                                            "https://upload.twitter.com/",
                                            false);
    upload_proxy.token = account.proxy.token;
    upload_proxy.token_secret = account.proxy.token_secret;
    this.compose_job = new Cb.ComposeJob (account.proxy,
                                          upload_proxy,
                                          this.cancellable);

    this.compose_job.image_upload_progress.connect ((path, progress) => {
      this.compose_image_manager.set_image_progress (path, progress);
    });
    this.compose_job.image_upload_finished.connect ((path, error_msg) => {
      debug ("%s Finished!", path);
      this.compose_image_manager.end_progress (path, error_msg);
    });

    if (this.mode == Mode.REPLY)
      this.compose_job.set_reply_id (this.reply_to.id);
    else if (this.mode == Mode.QUOTE)
      this.compose_job.set_quoted_tweet (this.reply_to);

    avatar_image.surface = acc.avatar;
    acc.notify["avatar"].connect (() => {
      avatar_image.surface = account.avatar;
    });

    GLib.NetworkMonitor.get_default ().notify["network-available"].connect (update_send_button_sensitivity);

    length_label.label = Cb.Tweet.MAX_LENGTH.to_string ();
    tweet_text.buffer.changed.connect (update_send_button_sensitivity);

    if (parent != null) {
      this.set_transient_for (parent);
      this.set_modal (true);
    }

    if (mode != Mode.NORMAL) {
      reply_list = new Gtk.ListBox ();
      reply_list.selection_mode = Gtk.SelectionMode.NONE;
      TweetListEntry reply_entry = new TweetListEntry (reply_to, parent, acc, true);
      reply_entry.activatable = false;
      reply_entry.read_only = true;
      reply_entry.show ();
      reply_list.add (reply_entry);
      reply_list.show ();
      content_grid.attach (reply_list, 0, 0, 2, 1);
    }

    if (mode == Mode.QUOTE) {
      assert (reply_to != null);
      this.title_label.label = _("Quote tweet");
      add_image_button.sensitive = false;
      fav_image_button.sensitive = false;
    }

    /* Let the text view immediately grab the keyboard focus */
    tweet_text.grab_focus ();
    tweet_text.completion_listbox = this.completion_list;
    tweet_text.show_completion.connect (() => {
      completion_revealer.reveal_child = true;
    });
    tweet_text.hide_completion.connect (() => {
      completion_revealer.reveal_child = false;
    });

    Gtk.AccelGroup ag = new Gtk.AccelGroup ();
    ag.connect (Gdk.Key.Escape, 0, Gtk.AccelFlags.LOCKED, escape_pressed_cb);
    ag.connect (Gdk.Key.Return, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.LOCKED,
        () => {start_send_tweet (); return true;});
    ag.connect (Gdk.Key.E, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.LOCKED,
        () => {show_emoji_chooser (); return true;});


    this.compose_image_manager.image_removed.connect ((path) => {
      this.compose_job.abort_image_upload (path);

      if (!this.compose_image_manager.full) {
        this.add_image_button.sensitive = true;
        this.fav_image_button.sensitive = true;
      }

      if (path.down ().has_suffix (".gif")) {
        fav_image_view.set_gifs_enabled (true);
        this.add_image_button.sensitive = true;
        this.fav_image_button.sensitive = true;
      }

      if (this.compose_image_manager.n_images == 0) {
        this.compose_image_manager.hide ();
        fav_image_view.set_gifs_enabled (true);
      }

      update_send_button_sensitivity ();
    });

    this.add_accel_group (ag);

    string? last_tweet = account.db.select ("info").cols ("last_tweet").once_string ();
    if (last_tweet != null && last_tweet.length > 0 &&
        tweet_text.get_buffer ().text.length == 0) {
      this.tweet_text.get_buffer ().text = last_tweet;
    }


    var image_target_list = new Gtk.TargetList (null);
    image_target_list.add_text_targets (0);

    /* The GTK+ version might not have this emoji data variant */
    try {
      if (GLib.resources_get_info ("/org/gtk/libgtk/emoji/emoji.data",
                                   GLib.ResourceLookupFlags.NONE, null, null)) {
        setup_emoji_chooser ();
      }
    } catch (GLib.Error e) {
      // Ignore, just don't show the emoji chooser
    }

    this.set_default_size (DEFAULT_WIDTH, (int)(DEFAULT_WIDTH / 2.5));
  }

  private void update_send_button_sensitivity () {
    Gtk.TextIter start, end;
    tweet_text.buffer.get_bounds (out start, out end);
    string text = tweet_text.buffer.get_text (start, end, true);

    int length = (int)Tl.count_weighted_characters (text);
    length_label.label = (Cb.Tweet.MAX_LENGTH - length).to_string ();

    if (length > 0 && length <= Cb.Tweet.MAX_LENGTH ||
        (length == 0 && compose_image_manager.n_images > 0)) {
      bool network_reachable = GLib.NetworkMonitor.get_default ().network_available;
      send_button.sensitive = network_reachable;
    } else {
      send_button.sensitive = false;
    }
  }

  [GtkCallback]
  private void start_send_tweet () {
    if (!send_button.sensitive)
      return;

    title_stack.visible_child = title_spinner;
    title_spinner.start ();
    send_button.sensitive = false;
    tweet_text.sensitive = false;
    fav_image_button.sensitive = false;
    add_image_button.sensitive = false;
    compose_image_manager.insensitivize_buttons ();

    Gtk.TextIter start, end;
    tweet_text.buffer.get_start_iter (out start);
    tweet_text.buffer.get_end_iter (out end);
    this.compose_job.set_text (tweet_text.buffer.get_text (start, end, true));

    this.compose_job.send_async.begin (this.cancellable, (obj, res) => {
      bool success = false;
      try {
       success = this.compose_job.send_async.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
      }
      debug ("Tweet sent.");
      if (success) {
        /* Reset last_tweet */
        account.db.update ("info").val ("last_tweet", "").run ();
      } else {
        /* Better save this tweet */
        this.save_last_tweet ();
      }
      this.destroy ();
    });
  }

  private void save_last_tweet () {
    if (this.reply_to == null) {
      string text = tweet_text.buffer.text;
      account.db.update ("info").val ("last_tweet", text).run ();
    }
  }

  [GtkCallback]
  private void cancel_clicked () {
    if (stack.visible_child == image_error_grid ||
        stack.visible_child == emoji_chooser ||
        stack.visible_child_name == "fav-images") {
      stack.visible_child = content_grid;
      cancel_button.label = _("Cancel");
      /* Use this instead of just setting send_button.sensitive to true to avoid
         sending tweets with 0 length */
      this.update_send_button_sensitivity ();
    } else {
      if (this.cancellable != null) {
        this.cancellable.cancel ();
      }
      this.save_last_tweet ();
      destroy ();
    }
  }

  private bool escape_pressed_cb () {
    this.cancel_clicked ();
    return Gdk.EVENT_STOP;
  }

  public void set_text (string text) {
    tweet_text.buffer.text = text;
  }

  [GtkCallback]
  private void add_image_clicked_cb (Gtk.Button source) {
    var filechooser = new Gtk.FileChooserNative (_("Select Image"),
                                                 this,
                                                 Gtk.FileChooserAction.OPEN,
                                                 _("Open"),
                                                 _("Cancel"));


    var filter = new Gtk.FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    filter.add_mime_type ("image/gif");
    filechooser.set_filter (filter);

    if (filechooser.run () == Gtk.ResponseType.ACCEPT) {
      var filename = filechooser.get_filename ();
      debug ("Loading %s", filename);

      /* Get file size */
      var file = GLib.File.new_for_path (filename);
      GLib.FileInfo info;
      try {
        info = file.query_info (GLib.FileAttribute.STANDARD_TYPE + "," +
                                GLib.FileAttribute.STANDARD_CONTENT_TYPE + "," +
                                GLib.FileAttribute.STANDARD_SIZE, 0);
      } catch (GLib.Error e) {
        warning ("%s (%s)", e.message, filename);
        // TODO: Proper error checking
        return;
      }

      if (!info.get_content_type ().has_prefix ("image/")) {
        stack.visible_child = image_error_grid;
        image_error_label.label = _("Selected file is not an image.");
        cancel_button.label = _("Back");
        send_button.sensitive = false;
      } else if (info.get_size () > Twitter.MAX_BYTES_PER_IMAGE) {
        stack.visible_child = image_error_grid;
        image_error_label.label = _("The selected image is too big. The maximum file size per image is %'d MB")
                                  .printf (Twitter.MAX_BYTES_PER_IMAGE / 1024 / 1024);
        cancel_button.label = _("Back");
        send_button.sensitive = false;
      } else if (filename.has_suffix (".gif") &&
                 this.compose_image_manager.n_images > 0) {
        stack.visible_child = image_error_grid;
        image_error_label.label = _("Only one GIF file per tweet is allowed.");
        cancel_button.label = _("Back");
        send_button.sensitive = false;
      } else {
        this.compose_image_manager.show ();
        this.compose_image_manager.load_image (filename, null);
        this.compose_job.upload_image_async (filename);
        if (this.compose_image_manager.n_images > 0) {
          fav_image_view.set_gifs_enabled (false);
        }
        if (this.compose_image_manager.full) {
          this.add_image_button.sensitive = false;
          this.fav_image_button.sensitive = false;
        }
      }
    }

    update_send_button_sensitivity ();
  }

  [GtkCallback]
  public void fav_image_button_clicked_cb () {
    cancel_button.label = _("Back");
    stack.visible_child_name = "fav-images";
    this.fav_image_view.load_images ();
  }

  [GtkCallback]
  public void favorite_image_selected_cb (string path) {
    cancel_clicked ();
    this.compose_image_manager.show ();
    this.compose_image_manager.load_image (path, null);
    this.compose_job.upload_image_async (path);
    if (this.compose_image_manager.full) {
      this.add_image_button.sensitive = false;
      this.fav_image_button.sensitive = false;
    }

    if (this.compose_image_manager.n_images > 0)
      fav_image_view.set_gifs_enabled (false);

    update_send_button_sensitivity ();
  }

  [GtkCallback]
  public void tweet_text_populate_popup_cb (Gtk.Menu popup) {
    if (this.emoji_chooser == null)
      return;

    var menuitem = new Gtk.MenuItem.with_label (_("Insert Emoji"));
    menuitem.activate.connect (show_emoji_chooser);
    menuitem.show ();
    popup.add (menuitem);
  }

  private void show_emoji_chooser () {
    if (this.emoji_chooser == null)
      return;

    this.emoji_button.clicked ();
  }

  private void setup_emoji_chooser () {
    this.emoji_chooser = new Cb.EmojiChooser ();

    if (!emoji_chooser.try_init ()) {
      this.emoji_chooser = null;
      return;
    }

    emoji_chooser.emoji_picked.connect ((text) => {
      this.tweet_text.insert_at_cursor (text);
      cancel_clicked ();
    });
    emoji_chooser.show_all ();
    stack.add (emoji_chooser);

    this.emoji_button = new Gtk.Button.with_label ("🐧");
    emoji_button.clicked.connect (() => {
      this.emoji_chooser.populate ();
      this.stack.visible_child = this.emoji_chooser;
      cancel_button.label = _("Back");
    });

    emoji_button.show_all ();
    add_button_box.add (emoji_button);
  }
}
