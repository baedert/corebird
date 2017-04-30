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
  private Gtk.FlowBox fav_image_list;
  [GtkChild]
  private Gtk.Button fav_image_button;
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

    if (mode == Mode.QUOTE) {
      assert (reply_to != null);
      this.title_label.label = _("Quote tweet");
      add_image_button.sensitive = false;
      fav_image_button.sensitive = false;
    }

    /* Let the text view immediately grab the keyboard focus */
    tweet_text.grab_focus ();

    Gtk.AccelGroup ag = new Gtk.AccelGroup ();
    ag.connect (Gdk.Key.Escape, 0, Gtk.AccelFlags.LOCKED, escape_pressed_cb);
    ag.connect (Gdk.Key.Return, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.LOCKED,
        () => {start_send_tweet (); return true;});

    this.compose_image_manager.image_removed.connect (() => {
      if (!this.compose_image_manager.full) {
        this.add_image_button.sensitive = true;
        this.fav_image_button.sensitive = true;
      }

      if (this.compose_image_manager.n_images == 0) {
        this.compose_image_manager.hide ();
        this.enable_fav_gifs ();
      }
    });

    this.add_accel_group (ag);

    string? last_tweet = account.db.select ("info").cols ("last_tweet").once_string ();
    if (last_tweet != null && last_tweet.length > 0 &&
        tweet_text.get_buffer ().text.length == 0) {
      this.tweet_text.get_buffer ().text = last_tweet;
    }


    var image_target_list = new Gtk.TargetList (null);
    image_target_list.add_text_targets (0);

    Gtk.drag_dest_set (fav_image_list,
                       Gtk.DestDefaults.ALL,
                       null,
                       Gdk.DragAction.COPY);
    Gtk.drag_dest_set_target_list (fav_image_list, image_target_list);

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
    fav_image_button.sensitive = false;
    add_image_button.sensitive = false;
    compose_image_manager.sensitive = false;


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

    job.image_progress.connect ((path, progress) => {
      this.compose_image_manager.set_image_progress (path, progress);
    });

    job.image_upload_finished.connect ((path, error_msg) => {
      this.compose_image_manager.end_progress (path, error_msg);
    });

    this.compose_image_manager.upload_started = true;
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
  private void cancel_clicked () {
    if (this.cancellable != null)
      this.cancellable.cancel ();

    if (stack.visible_child == image_error_grid ||
        stack.visible_child_name == "fav-images") {
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

    if (stack.visible_child_name == "fav-images") {
      stack.visible_child = content_grid;
    } else {
      this.save_last_tweet ();
      this.destroy ();
    }
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
      var filename = filechooser.get_filename ();
      if (id == Gtk.ResponseType.ACCEPT) {
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
        } else if (filename.has_suffix (".gif") &&
                   this.compose_image_manager.n_images > 0) {
          stack.visible_child = image_error_grid;
          image_error_label.label = _("Only one GIF file per tweet is allowed.");
          cancel_button.label = _("Back");
          send_button.sensitive = false;
        } else {
          this.compose_image_manager.show ();
          this.compose_image_manager.load_image (filename, null);
          if (this.compose_image_manager.n_images > 0) {
            this.disable_fav_gifs ();
          }
          if (this.compose_image_manager.full) {
            this.add_image_button.sensitive = false;
            this.fav_image_button.sensitive = false;
          }
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

  [GtkCallback]
  public void fav_image_button_clicked_cb () {
    cancel_button.label = _("Back");
    stack.visible_child_name = "fav-images";
    this.load_fav_images ();
  }

  private void load_fav_images () {
    if (fav_image_list.get_children ().length () > 0)
      return;

    const int MAX_IMAGES = 50;
    string fav_image_dir = Dirs.config ("image-favorites/");
    try {
      var dir = File.new_for_path (fav_image_dir);
      var iter = dir.enumerate_children ("standard::display-name,standard::content-type",
                                         GLib.FileQueryInfoFlags.NONE);

      int i = 0;
      FileInfo? info = null;
      while ((info = iter.next_file ()) != null) {
        var content_type = info.get_content_type ();

        if (content_type == "image/jpeg" ||
            content_type == "image/png" ||
            content_type == "image/gif") {
          var file = dir.get_child (info.get_name ());
          var row = new FavImageRow (file.get_path ());
          if (this.compose_image_manager.n_images > 0)
            row.set_sensitive (false);

          row.show_all ();
          fav_image_list.add (row);

          i ++;
          if (i >= MAX_IMAGES)
            break;
        }
      }
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }

  [GtkCallback]
  private void new_fav_image_button_clicked_cb () {
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
        try {
          /* First, take the selected file and copy it into the image-favorites folder */
          var file = GLib.File.new_for_path (filechooser.get_filename ());
          var file_info = file.query_info ("standard::name", GLib.FileQueryInfoFlags.NONE);
          var dest_dir = GLib.File.new_for_path (Dirs.config ("image-favorites"));

          /* Explicitly check whether the destination file already exists, and rename
             it if it does */
          var dest_file = dest_dir.get_child (file_info.get_name ());
          if (GLib.FileUtils.test (dest_file.get_path (), GLib.FileTest.EXISTS)) {
            debug ("File '%s' already exists", dest_file.get_path ());
            dest_file = dest_dir.get_child ("%s_%s".printf (GLib.get_monotonic_time ().to_string (),
                                                            file_info.get_name ()));
            debug ("New name: '%s'", dest_file.get_path ());
          }

          file.copy (dest_file, GLib.FileCopyFlags.NONE);

          var row = new FavImageRow (dest_file.get_path ());
          if (this.compose_image_manager.n_images > 0)
            row.set_sensitive (false);

          row.show_all ();
          fav_image_list.add (row);

        } catch (GLib.Error e) {
          warning (e.message);
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

  [GtkCallback]
  private void fav_image_box_child_activated_cb (Gtk.FlowBoxChild _child) {
    FavImageRow child = (FavImageRow) _child;

    cancel_clicked ();
    this.compose_image_manager.show ();
    this.compose_image_manager.load_image (child.get_image_path (), null);
    if (this.compose_image_manager.full) {
      this.add_image_button.sensitive = false;
      this.fav_image_button.sensitive = false;
    }

    if (this.compose_image_manager.n_images > 0)
      this.disable_fav_gifs ();
  }

  [GtkCallback]
  private void fav_image_box_drag_data_received_cb (Gdk.DragContext   context,
                                                    int               x,
                                                    int               y,
                                                    Gtk.SelectionData selection_data,
                                                    uint              info,
                                                    uint              time) {
    if (info == 0) {
      /* Text */
      string? text = selection_data.get_text ().strip ();
      if (text.has_prefix ("file://")) {
        var row = new FavImageRow (GLib.File.new_for_uri (text).get_path ());
        if (this.compose_image_manager.n_images > 0)
          row.set_sensitive (false);

        row.show_all ();
        fav_image_list.add (row);
      } else {
        debug ("Can't handle '%s'", text);
      }
    } else {
      warning ("Unknown drag data info %u", info);
    }
  }

  private void disable_fav_gifs () {
    foreach (var child in this.fav_image_list.get_children ()) {
      var btn = (FavImageRow) child;
      if (btn.get_image_path ().down ().has_suffix (".gif")) {
        btn.set_sensitive (false);
      }
    }
  }

  private void enable_fav_gifs () {
    foreach (var child in this.fav_image_list.get_children ()) {
      var btn = (FavImageRow) child;
      if (btn.get_image_path ().down ().has_suffix (".gif")) {
        btn.set_sensitive (true);
      }
    }
  }
}
