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
  private Gtk.Box content_box;
  [GtkChild]
  private CompletionTextView tweet_text;
  [GtkChild]
  private Gtk.Label length_label;
  [GtkChild]
  private Gtk.Button send_button;
  [GtkChild]
  private Gtk.Button cancel_button;
  [GtkChild]
  private Gtk.Spinner title_spinner;
  [GtkChild]
  private Gtk.Label title_label;
  [GtkChild]
  private Gtk.Stack title_stack;
  private unowned Account account;
  private unowned Tweet reply_to;
  private Mode mode;
  private Gee.ArrayList<AddImageButton> image_buttons;


  public ComposeTweetWindow (Gtk.Window?      parent,
                             Account          acc,
                             Tweet?           reply_to = null,
                             Mode             mode = Mode.NORMAL,
                             Gtk.Application? app = null) {
    this.set_show_menubar (false);
    this.account = acc;
    this.reply_to = reply_to;
    this.mode = mode;
    this.tweet_text.set_account (acc);
    if (app == null && parent is Gtk.ApplicationWindow) {
      this.application = ((Gtk.ApplicationWindow)parent).application;
    } else
      this.application = app;

    image_buttons = new Gee.ArrayList<AddImageButton> ();
    avatar_image.set_from_pixbuf (acc.avatar);
    length_label.label = Tweet.MAX_LENGTH.to_string ();
    tweet_text.buffer.changed.connect (buffer_changed_cb);


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
      content_box.pack_start (list, false, true);
      content_box.reorder_child (list, 0);
    }

    if (mode == Mode.REPLY) {
      StringBuilder mention_builder = new StringBuilder ();
      if (reply_to.screen_name != account.screen_name) {
        mention_builder.append ("@").append (reply_to.screen_name);
      }
      if (reply_to.is_retweet) {
        if (mention_builder.len > 0)
          mention_builder.append (" ");

        mention_builder.append ("@").append (reply_to.rt_by_screen_name);
      }
      foreach (string s in reply_to.mentions) {
        if (mention_builder.len > 0)
          mention_builder.append (" ");

        mention_builder.append (s);
      }
      /* Only add a space if we actually added some screen names */
      if (mention_builder.len > 0)
        mention_builder.append (" ");

      tweet_text.buffer.text = mention_builder.str;
    } else if (mode == Mode.QUOTE) {
      tweet_text.buffer.text = " RT @%s “%s“".printf (reply_to.screen_name,
                                             Utils.unescape_html (reply_to.get_real_text ()));

      Gtk.TextIter start_iter;
      tweet_text.buffer.get_start_iter (out start_iter);
      tweet_text.buffer.place_cursor (start_iter);
    }

    //Let the text view immediately grab the keyboard focus
    tweet_text.grab_focus ();

    Gtk.AccelGroup ag = new Gtk.AccelGroup ();
    ag.connect (Gdk.Key.Escape, 0, Gtk.AccelFlags.LOCKED, escape_pressed_cb);
    ag.connect (Gdk.Key.Return, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.LOCKED,
        () => {start_send_tweet (); return true;});

    this.add_accel_group (ag);

    /* Add AddImageButton because we can't do it in the ui definition for some reason */
    add_image_button (true);
  }


  private void buffer_changed_cb () {
    recalc_tweet_length ();
  }

  private void recalc_tweet_length () {
    Gtk.TextIter start, end;
    tweet_text.buffer.get_bounds (out start, out end);
    string text = tweet_text.buffer.get_text (start, end, true);

    int media_count = 0;
    if (get_effective_media_count () > 0)
      media_count = 1;

    int length = TweetUtils.calc_tweet_length (text, media_count);

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

    int media_count = get_effective_media_count ();
    Collect collect_obj = new Collect (media_count);
    int64[] media_ids = new int64[media_count];

    title_stack.visible_child = title_spinner;
    title_spinner.start ();
    cancel_button.sensitive = false;
    send_button.sensitive = false;
    tweet_text.sensitive = false;

    /* Remove unused media button */
    foreach (AddImageButton btn in image_buttons)
      if (btn.image == null) {
        btn.sensitive = false;
        break;
      }


    if (media_count > 0) {
      /* Set up a new proxy because why not */
      Rest.OAuthProxy proxy = new Rest.OAuthProxy (Settings.get_consumer_key (),
                                                   Settings.get_consumer_secret (),
                                                   "https://upload.twitter.com/",
                                                   false);
      proxy.token = account.proxy.token;
      proxy.token_secret = account.proxy.token_secret;

      int i = 0;
      foreach (AddImageButton aib in image_buttons) {
        if (aib.image != null) {
          int k = i;
          aib.start_progress ();
          upload_media.begin (aib.image_path, proxy, (obj, res) => {
            int64 id;
            try {
              id = upload_media.end (res);
            } catch (GLib.Error e) {
              warning (e.message);
              collect_obj.emit (e);
              aib.set_error (e.message);
              return;
            }
            aib.set_success ();
            media_ids[k] = id;
            collect_obj.emit ();
          });
          i ++;
        }
      }
      collect_obj.finished.connect ((error) => {
        title_stack.visible_child = title_label;
        cancel_button.sensitive = true;
        send_button.sensitive = true;
        tweet_text.sensitive = true;
        send_tweet (error, media_ids);
      });

    } else {
      /* No media attached so just send the text */
      send_tweet (null, media_ids);
    }
  }

  private void send_tweet (GLib.Error? error, int64[] ids) {
    if (error != null) {
      GLib.error (error.message);
    }

    Gtk.TextIter start, end;
    tweet_text.buffer.get_start_iter (out start);
    tweet_text.buffer.get_end_iter (out end);
    string text = tweet_text.buffer.get_text (start, end, true);

    var call = account.proxy.new_call ();
    call.set_method ("POST");
    call.add_param ("status", text);
    if (this.reply_to != null && mode == Mode.REPLY) {
      call.add_param("in_reply_to_status_id", reply_to.id.to_string ());
    }

    if (ids.length > 0) {
      StringBuilder id_str = new StringBuilder ();
      id_str.append (ids[0].to_string ());
      for (int i = 1; i < ids.length; i ++) {
        id_str.append (",").append (ids[i].to_string ());
      }
      call.add_param ("media_ids", id_str.str);
    }

    call.set_function ("1.1/statuses/update.json");
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        critical (e.message);
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE);
      } finally {
        this.destroy ();
      }
    });
    this.hide ();
  }

  private async int64 upload_media (string path, Rest.Proxy proxy) throws GLib.Error {
    var call = proxy.new_call ();
    call.set_function ("1.1/media/upload.json");
    call.set_method ("POST");
    uint8[] file_contents;
    GLib.File media_file = GLib.File.new_for_path (path);
    media_file.load_contents (null, out file_contents, null);
    Rest.Param param = new Rest.Param.full ("media",
                                            Rest.MemoryUse.COPY,
                                            file_contents,
                                            "multipart/form-data",
                                            path);
    call.add_param_full (param);


    yield call.invoke_async (null);
    var parser = new Json.Parser ();
    try {
      parser.load_from_data (call.get_payload ());
    } catch (GLib.Error e) {
      warning (e.message); //XXX Error handling
      return -1;
    }
    var root = parser.get_root ().get_object ();
    return root.get_int_member ("media_id");
  }

  [GtkCallback]
  private void cancel_clicked (Gtk.Widget source) {
    destroy ();
  }


  private bool escape_pressed_cb () {
    this.destroy ();
    return true;
  }

  public void set_text (string text) {
    tweet_text.buffer.text = text;
  }


  /* Image handling stuff {{{ */

  private void add_image_button (bool initially_visible = false) {
    if (image_buttons.size >= Twitter.max_media_per_upload)
      return;

    var image_button = new AddImageButton ();
    var revealer = new Gtk.Revealer ();
    image_button.remove_clicked.connect (remove_image_clicked_cb);
    image_button.add_clicked.connect (add_image_clicked_cb);
    image_button.notify["image"].connect (() => {
      if (image_button.image != null) {
        add_image_button ();
        recalc_tweet_length ();
      }
    });
    revealer.add (image_button);
    revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

    revealer.reveal_child = initially_visible;
    revealer.show_all ();
    content_box.pack_start (revealer, false, false);
    if (!initially_visible)
      revealer.reveal_child = true;

    image_buttons.add (image_button);
  }

  private void add_image_clicked_cb (AddImageButton source) {
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
      string file = fcd.get_filename ();
      try {
        var pixbuf = new Gdk.Pixbuf.from_file (file);
        var thumb = Utils.slice_pixbuf (pixbuf, 500, MultiMediaWidget.HEIGHT);
        source.image = thumb;
        source.image_path = file;
      } catch (GLib.Error e) {
        warning (e.message);
      }
    }
    fcd.close ();
  }

  private void remove_image_clicked_cb (AddImageButton source) {
    source.image = null;
    Gtk.Revealer revealer = (Gtk.Revealer)source.parent;
    revealer.reveal_child = false;
    revealer.notify["child-revealed"].connect (() => {
      content_box.remove (revealer);
      image_buttons.remove (source);
    });
    recalc_tweet_length ();
  }

  private int get_effective_media_count () {
    int c = 0;
    foreach (AddImageButton btn in image_buttons)
      if (btn.image != null)
        c ++;

    return c;
  }

  /* }}} */
}
