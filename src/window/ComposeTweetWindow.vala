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
  private unowned Account account;
  private unowned Tweet reply_to;
  private Mode mode;
  private Gee.ArrayList<AddImageButton> image_buttons;
  private GLib.Cancellable? cancellable;


  public ComposeTweetWindow (Gtk.Window? parent,
                             Account     acc,
                             Tweet?      reply_to = null,
                             Mode        mode = Mode.NORMAL) {
    this.set_show_menubar (false);
    this.account = acc;
    this.reply_to = reply_to;
    this.mode = mode;
    this.tweet_text.set_account (acc);
    this.application = (Gtk.Application)GLib.Application.get_default ();

    image_buttons = new Gee.ArrayList<AddImageButton> ();
    avatar_image.surface = acc.avatar;

    if (mode != Mode.QUOTE)
      length_label.label = Tweet.MAX_LENGTH.to_string ();
    else
      length_label.label = (Tweet.MAX_LENGTH - Twitter.short_url_length_https).to_string ();


    tweet_text.buffer.changed.connect (recalc_tweet_length);


    if (parent != null) {
      this.set_transient_for (parent);
    }

    if (mode != Mode.NORMAL) {
      var list = new Gtk.ListBox ();
      list.selection_mode = Gtk.SelectionMode.NONE;
      TweetListEntry reply_entry = new TweetListEntry (reply_to, (MainWindow)parent, acc);
      reply_entry.activatable = false;
      reply_entry.read_only = true;
      reply_entry.show ();
      list.add (reply_entry);
      list.show ();
      content_grid.attach (list, 0, 0, 2, 1);
    }

    if (mode == Mode.REPLY) {
      StringBuilder mention_builder = new StringBuilder ();
      if (reply_to.screen_name != account.screen_name) {
        mention_builder.append ("@").append (reply_to.screen_name);
      }
      if (reply_to.retweeted_tweet != null) {
        if (mention_builder.len > 0)
          mention_builder.append (" ");

        mention_builder.append ("@").append (reply_to.source_tweet.author.screen_name);
      }
      foreach (string s in reply_to.get_mentions ()) {
        if (s == "@" + account.screen_name)
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

    //Let the text view immediately grab the keyboard focus
    tweet_text.grab_focus ();

    Gtk.AccelGroup ag = new Gtk.AccelGroup ();
    ag.connect (Gdk.Key.Escape, 0, Gtk.AccelFlags.LOCKED, escape_pressed_cb);
    ag.connect (Gdk.Key.Return, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.LOCKED,
        () => {start_send_tweet (); return true;});

    this.compose_image_manager.image_removed.connect (() => {
      if (this.compose_image_manager.n_images < Twitter.max_media_per_upload) {
        this.add_image_button.sensitive = true;
      }
    });

    this.add_accel_group (ag);

    if (mode == Mode.NORMAL)
      this.resize (400, 250);
  }

  private void recalc_tweet_length () {
    Gtk.TextIter start, end;
    tweet_text.buffer.get_bounds (out start, out end);
    string text = tweet_text.buffer.get_text (start, end, true);

    int media_count = 0;
    if (compose_image_manager.n_images > 0)
      media_count = 1;

    int length = TweetUtils.calc_tweet_length (text, media_count);

    if (this.mode == Mode.QUOTE)
      length += 1 + Twitter.short_url_length_https; //Quoting will add a space and then the tweet's URL


    length_label.label = (Tweet.MAX_LENGTH - length).to_string ();
    if (length > 0 && length <= Tweet.MAX_LENGTH)
      send_button.sensitive = true;
    else
      send_button.sensitive = false;
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
      message ("Adding %s", path);
      job.add_image (path);
    }

    job.image_upload_started.connect ((path) => {
      this.compose_image_manager.start_progress (path);
    });

    job.image_upload_finished.connect ((path, error_msg) => {
      this.compose_image_manager.end_progress (path, error_msg);
    });

    job.start.begin (cancellable, () => {
      message ("Tweet sent.");
      this.destroy ();
    });
  }

  [GtkCallback]
  private void cancel_clicked (Gtk.Widget source) {
    if (this.cancellable != null)
      this.cancellable.cancel ();
    destroy ();
  }

  private bool escape_pressed_cb () {
    this.destroy ();
    return Gdk.EVENT_STOP;
  }

  public void set_text (string text) {
    tweet_text.buffer.text = text;
  }

  /* Image handling stuff {{{ */
  [GtkCallback]
  private void add_image_clicked_cb (Gtk.Button source) {
    var fcd = new Gtk.FileChooserDialog(_("Select Image"), this, Gtk.FileChooserAction.OPEN,
                                        _("Cancel"), Gtk.ResponseType.CANCEL,
                                        _("Choose"), Gtk.ResponseType.ACCEPT);
    fcd.set_modal (true);
    var filter = new Gtk.FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    filter.add_mime_type ("image/gif");
    fcd.set_filter (filter);
    var preview_widget = new Gtk.Image ();
    fcd.set_preview_widget (preview_widget);
    fcd.update_preview.connect (() => {
      string? uri = fcd.get_preview_uri ();
      if (uri != null && uri.has_prefix ("file://")) {
        try {
          int final_size = 130;
          var p = new Gdk.Pixbuf.from_file (GLib.File.new_for_uri (uri).get_path ());
          int w = p.get_width ();
          int h = p.get_height ();
          if (w > h) {
            double ratio = final_size / (double) w;
            w = final_size;
            h = (int)(h * ratio);
          } else {
            double ratio = final_size / (double) h;
            w = (int)(w * ratio);
            h = final_size;
          }
          var scaled = p.scale_simple (w, h, Gdk.InterpType.BILINEAR);
          preview_widget.set_from_pixbuf (scaled);
          preview_widget.show ();
        } catch (GLib.Error e) {
          preview_widget.hide ();
        }
      } else
        preview_widget.hide ();
    });

    if (fcd.run () == Gtk.ResponseType.ACCEPT) {
      string path = fcd.get_filename ();
      this.compose_image_manager.load_image (path);

      if (this.compose_image_manager.n_images == Twitter.max_media_per_upload)
        this.add_image_button.sensitive = false;
    }
    fcd.close ();
  }
  /* }}} */
}
