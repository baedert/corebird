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
  private unowned Account account;
  private unowned Cb.Tweet reply_to;
  private Mode mode;
  private GLib.Cancellable? cancellable;
  private Gtk.ListBox? reply_list = null;


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

    avatar_image.surface = acc.avatar;
    acc.notify["avatar"].connect (() => {
      avatar_image.surface = account.avatar;
    });

    /* Just use recalc_tweet_length here so we have a central place where we update the
       send_button sensitivity */
    GLib.NetworkMonitor.get_default ().notify["network-available"].connect (recalc_tweet_length);

    length_label.label = Cb.Tweet.MAX_LENGTH.to_string ();
    tweet_text.buffer.changed.connect (recalc_tweet_length);

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

    if (mode == Mode.REPLY) {
      StringBuilder mention_builder = new StringBuilder ();
      if (reply_to.get_screen_name () != account.screen_name) {
        mention_builder.append ("@").append (reply_to.get_screen_name ());
      }

      if (reply_to.retweeted_tweet != null) {
        if (mention_builder.len > 0)
          mention_builder.append (" ");

        mention_builder.append ("@").append (reply_to.source_tweet.author.screen_name);
      }

      foreach (unowned string s in reply_to.get_mentions ()) {
        if (s == "@" + account.screen_name ||
            s == "@" + reply_to.get_screen_name () ||
            (reply_to.retweeted_tweet != null && reply_to.source_tweet.author.screen_name != s))
          continue;

        if (mention_builder.len > 0)
          mention_builder.append (" ");

        mention_builder.append (s);
      }
      /* Only add a space if we actually added some screen names */
      if (mention_builder.len > 0)
        mention_builder.append (" ");

      tweet_text.buffer.text = mention_builder.str;
    } else if (mode == Mode.QUOTE) {
      assert (reply_to != null);
      this.title_label.label = _("Quote tweet");
    }

    /* Let the text view immediately grab the keyboard focus */
    tweet_text.grab_focus ();

    Gtk.AccelGroup ag = new Gtk.AccelGroup ();
    ag.connect (Gdk.Key.Escape, 0, Gtk.AccelFlags.LOCKED, escape_pressed_cb);
    ag.connect (Gdk.Key.Return, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.LOCKED,
        () => {start_send_tweet (); return true;});

    this.compose_image_manager.image_removed.connect (() => {
      if (this.compose_image_manager.n_images < Twitter.max_media_per_upload)
        this.add_image_button.sensitive = true;

      if (this.compose_image_manager.n_images == 0)
        this.compose_image_manager.hide ();
    });

    this.add_accel_group (ag);

    string? last_tweet = account.db.select ("info").cols ("last_tweet").once_string ();
    if (last_tweet != null && last_tweet.length > 0 &&
        tweet_text.get_buffer ().text.length == 0) {
      this.tweet_text.get_buffer ().text = last_tweet;
    }


    this.set_default_size (DEFAULT_WIDTH, (int)(DEFAULT_WIDTH / 2.5));
  }



  private void recalc_tweet_length () {
    Gtk.TextIter start, end;
    tweet_text.buffer.get_bounds (out start, out end);
    string text = tweet_text.buffer.get_text (start, end, true);

    int length = TweetUtils.calc_tweet_length (text);

    length_label.label = (Cb.Tweet.MAX_LENGTH - length).to_string ();
    if (length > 0 && length <= Cb.Tweet.MAX_LENGTH) {
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

    var job = new ComposeJob (this.account);
    this.cancellable = new GLib.Cancellable ();

    if (this.mode == Mode.REPLY)
      job.reply_id = this.reply_to.id;
    else if (this.mode == Mode.QUOTE)
      job.quoted_tweet = this.reply_to;

    title_stack.visible_child = title_spinner;
    title_spinner.start ();
    send_button.sensitive = false;
    tweet_text.sensitive = false;
    content_grid.sensitive = false;

    Gtk.TextIter start, end;
    tweet_text.buffer.get_start_iter (out start);
    tweet_text.buffer.get_end_iter (out end);
    job.text = tweet_text.buffer.get_text (start, end, true);

    foreach (var path in this.compose_image_manager.get_image_paths ()) {
      job.add_image (path);
    }

    job.image_upload_started.connect ((path) => {
      this.compose_image_manager.start_progress (path);
    });

    job.image_upload_finished.connect ((path, error_msg) => {
      this.compose_image_manager.end_progress (path, error_msg);
    });

    job.start.begin (cancellable, (obj, res) => {
      bool success = job.start.end (res);
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
  private void cancel_clicked (Gtk.Widget source) {
    if (this.cancellable != null)
      this.cancellable.cancel ();

    if (stack.visible_child == image_error_grid) {
      stack.visible_child = content_grid;
      cancel_button.label = _("Cancel");
      /* Use this instead of just setting send_button.sensitive to true to avoid
         sending tweets with 0 length */
      this.recalc_tweet_length ();
    } else {
      this.save_last_tweet ();
      destroy ();
    }
  }

  private bool escape_pressed_cb () {
    this.save_last_tweet ();
    this.destroy ();
    return Gdk.EVENT_STOP;
  }

  public void set_text (string text) {
    tweet_text.buffer.text = text;
  }

  [GtkCallback]
  private void add_image_clicked_cb (Gtk.Button source) {
    var filechooser = new Gtk.FileChooserDialog (_("Select Image"),
                                                 this,
                                                 Gtk.FileChooserAction.OPEN,
                                                 _("Cancel"),
                                                 Gtk.ResponseType.CANCEL,
                                                 _("Open"),
                                                 Gtk.ResponseType.ACCEPT);
    filechooser.select_multiple = false;
    filechooser.modal = true;

    filechooser.response.connect ((id) => {
      if (id == Gtk.ResponseType.ACCEPT) {
        var filename = filechooser.get_filename ();
        debug ("Loading %s", filename);

        /* Get file size */
        var file = GLib.File.new_for_path (filename);
        GLib.FileInfo info;
        try {
          info = file.query_info (GLib.FileAttribute.STANDARD_TYPE + "," +
                                  GLib.FileAttribute.STANDARD_SIZE, 0);
        } catch (GLib.Error e) {
          warning ("%s (%s)", e.message, filename);
          // TODO: Proper error checking
          return;
        }

        if (info.get_size () > Twitter.MAX_BYTES_PER_IMAGE) {
          stack.visible_child = image_error_grid;
          image_error_label.label = _("The selected image is too big. The maximum file size per image is %'d MB")
                                    .printf (Twitter.MAX_BYTES_PER_IMAGE / 1024 / 1024);
          cancel_button.label = _("Back");
          send_button.sensitive = false;
        } else {
          this.compose_image_manager.show ();
          this.compose_image_manager.load_image (filename, null);
        }
      }
      filechooser.destroy ();
    });

    var filter = new Gtk.FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    filter.add_mime_type ("image/gif");
    filechooser.set_filter (filter);

    filechooser.show_all ();
  }
}
