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
  private static const uint TARGET_STRING   = 1;
  private static const uint TARGET_URI_LIST = 2;
  private static const uint TARGET_IMAGE    = 3;
  public enum Mode {
    NORMAL,
    REPLY,
    QUOTE
  }
  [GtkChild]
  private AvatarWidget avatar_image;
  [GtkChild]
  private Gtk.Button add_image_button;
  [GtkChild]
  private Gtk.Box content_box;
  [GtkChild]
  private Gtk.TextView tweet_text;
  [GtkChild]
  private Gtk.Label length_label;
  [GtkChild]
  private Gtk.Button send_button;
  [GtkChild]
  private PixbufButton media_image;
  [GtkChild]
  private Gtk.Window completion_window;
  [GtkChild]
  private Gtk.ListBox completion_list;
  private string media_uri;
  private uint media_count = 0;
  private unowned Account account;
  private unowned Tweet answer_to;
  private Mode mode;
  private int current_match = -1;


  public ComposeTweetWindow (Gtk.Window? parent, Account acc,
                             Tweet? answer_to = null,
                             Mode mode = Mode.NORMAL,
                             Gtk.Application? app = null) {
    this.set_show_menubar (false);
    this.account = acc;
    this.answer_to = answer_to;
    this.mode = mode;
    if (app == null && parent is Gtk.ApplicationWindow) {
      this.application = ((Gtk.ApplicationWindow)parent).application;
    } else
      this.application = app;
    avatar_image.set_from_pixbuf (acc.avatar);
    length_label.label = Tweet.MAX_LENGTH.to_string ();
    tweet_text.buffer.notify["cursor-position"].connect (buffer_changed_cb);
    tweet_text.focus_out_event.connect (completion_window_focus_out_cb);

    completion_window.set_attached_to (tweet_text);
    completion_window.set_screen (tweet_text.get_screen ());

    if (parent != null) {
      this.set_transient_for (parent);
    }

    if (mode != Mode.NORMAL) {
      TweetListEntry answer_entry = new TweetListEntry (answer_to, (MainWindow)parent, acc);
      content_box.pack_start (answer_entry, false, true);
    }

    if (mode == Mode.REPLY) {
      StringBuilder mention_builder = new StringBuilder ();
      mention_builder.append ("@").append (answer_to.screen_name);
      foreach (string s in answer_to.mentions) {
        mention_builder.append (" ").append (s);
      }
      mention_builder.append (" ");
      tweet_text.buffer.text = mention_builder.str;
    } else if (mode == Mode.QUOTE) {
      tweet_text.buffer.text = " RT @%s “%s“".printf (answer_to.screen_name,
                                             Utils.unescape_html (answer_to.get_real_text ()));

      Gtk.TextIter start_iter;
      tweet_text.buffer.get_start_iter (out start_iter);
      tweet_text.buffer.place_cursor (start_iter);
    }

    //Let the text view immediately grab the keyboard focus
    tweet_text.grab_focus ();

    Gtk.AccelGroup ag = new Gtk.AccelGroup ();
    ag.connect (Gdk.Key.Escape, 0, Gtk.AccelFlags.LOCKED, escape_pressed_cb);
    ag.connect (Gdk.Key.Return, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.LOCKED,
        () => {send_tweet (); return true;});

    this.add_accel_group (ag);


    // DND stuff
    const Gtk.TargetEntry[] target_entries = {
      {"STRING",          0,   TARGET_STRING},
      {"text/plain",      0,   TARGET_STRING},
      {"text/uri-list",   0,   TARGET_URI_LIST},
      {"image/png",       0,   TARGET_IMAGE},
      {"image/jpeg",      0,   TARGET_IMAGE},
    };
    Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, target_entries,
                       Gdk.DragAction.COPY);
    this.drag_data_received.connect (drag_data_received_cb);
  }

  private void drag_data_received_cb (Gdk.DragContext context, int x, int y,
                                      Gtk.SelectionData selection_data,
                                      uint info, uint time) {

    if (media_count > Twitter.max_media_per_upload)
      return;

    if (info == TARGET_STRING) {
      var uri = selection_data.get_text ().strip ();
      var file = GLib.File.new_for_uri (uri);
      load_inline_media (file.get_path ());
    } else if (info == TARGET_IMAGE) {
      var pixbuf = selection_data.get_pixbuf ();
      var thumb = Utils.slice_pixbuf (pixbuf, 48);
      load_inline_media ("whyisthisevenneeded", false);
      media_image.set_bg (thumb);
    } else if (info == TARGET_URI_LIST) {
      var uris = selection_data.get_uris ();
      // TODO: Would be fun to allow using external images (drag a remot image
      //       from your browser directly into your twitter client)
      var file = GLib.File.new_for_uri (uris[0]);
      if (file.get_uri_scheme () == "file")
        load_inline_media (file.get_path ());
    }
  }

  private void load_inline_media (string path, bool load = true) {
    this.media_uri = path;
    if (load) {
      try {
        var pixbuf = new Gdk.Pixbuf.from_file (path);
        var thumb = Utils.slice_pixbuf (pixbuf, 48);
        media_image.set_bg (thumb);
      } catch (GLib.Error e){critical ("Loading scaled image: %s", e.message);}
    }

    media_count++;
    media_image.set_visible (true);

    if (media_count >= Twitter.max_media_per_upload) {
      add_image_button.set_sensitive (false);
    }
  }

  private void buffer_changed_cb () {
    recalc_tweet_length ();
    update_completion ();
  }

  private void recalc_tweet_length () {
    Gtk.TextIter start, end;
    tweet_text.buffer.get_start_iter(out start);
    tweet_text.buffer.get_end_iter(out end);
    string text = tweet_text.buffer.get_text(start, end, true);

    int length = TweetUtils.calc_tweet_length (text, (int)media_count);

    length_label.label = (Tweet.MAX_LENGTH - length).to_string ();
    if (length > 0 && length <= Tweet.MAX_LENGTH)
      send_button.sensitive = true;
    else
      send_button.sensitive = false;
  }

  private void update_completion () {
    string cur_word = get_cursor_word (null, null);

    /* Check if the word ends with a 'special' character like ?!_ */
    char end_char = cur_word.get (cur_word.char_count () - 1);
    bool word_has_alpha_end = (end_char.isalpha () || end_char.isdigit ()) &&
                              end_char.isgraph () || end_char == '@';
    if (!cur_word.has_prefix ("@") || !word_has_alpha_end
        || tweet_text.buffer.has_selection) {
      completion_window.hide ();
      return;
    }
    show_completion_window ();

    // Strip off the @
    cur_word = cur_word.substring (1);

    int corpus_size = 0;
    var corpus = account.user_counter.query_by_prefix (cur_word, 10, out corpus_size);

    for (int i = 0; i < corpus_size; i++) {
      var l = new Gtk.Label ("@" + corpus[i].screen_name);
      l.halign = Gtk.Align.START;
      completion_list.add (l);
    }
    if (current_match == -1 && corpus_size > 0) {
      completion_list.select_row (completion_list.get_row_at_index (0));
    }
    completion_list.show_all ();

  }

  [GtkCallback]
  private void send_tweet () {
    Gtk.TextIter start, end;
    tweet_text.buffer.get_start_iter (out start);
    tweet_text.buffer.get_end_iter (out end);
    string text = tweet_text.buffer.get_text (start, end, true);
    if(text.strip() == "")
      return;

    var call = account.proxy.new_call ();
    call.set_method ("POST");
    call.add_param ("status", text);
    if (this.answer_to != null && mode == Mode.REPLY) {
      call.add_param("in_reply_to_status_id", answer_to.id.to_string ());
    }

    Rest.Param param;
    if (media_count == 0) {
      call.set_function ("1.1/statuses/update.json");
    } else {
      call.set_function ("1.1/statuses/update_with_media.json");
      uint8[] content;
      try {
        GLib.File media_file = GLib.File.new_for_path(media_uri);
        media_file.load_contents (null, out content, null);
      } catch (GLib.Error e) {
        critical (e.message);
      }

      param  = new Rest.Param.full ("media[]", Rest.MemoryUse.COPY,
                                    content, "multipart/form-data",
                                    media_uri);
      call.add_param_full (param);
    }

    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        critical (e.message);
        Utils.show_error_object (call.get_payload (), e.message);
      } finally {
        this.destroy ();
      }
    });
    this.visible = false;
  }

  [GtkCallback]
  private void cancel_clicked (Gtk.Widget source) {
    destroy ();
  }

  [GtkCallback]
  private void add_image_clicked () {
    var fcd = new Gtk.FileChooserDialog(_("Select Image"), null, Gtk.FileChooserAction.OPEN,
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
          var p = new Gdk.Pixbuf.from_file (uri.substring (7));
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
      load_inline_media (file);
    }
    fcd.close ();
  }

  [GtkCallback]
  private void media_image_clicked_cb () {
    media_image.set_visible(false);
    media_count--;
    if(media_count <= Twitter.max_media_per_upload)
      add_image_button.set_sensitive (true);
  }

  [GtkCallback]
  private bool completion_window_focus_out_cb () {
    completion_window.hide ();
    return false;
  }

  [GtkCallback]
  private bool tweet_text_key_pressed_cb (Gdk.EventKey evt) {
    /* If we are not in 'completion mode' atm, just back out. */
    if (!completion_window.visible)
      return false;


    int n_results = (int)completion_list.get_children ().length ();

    if (evt.keyval == Gdk.Key.Down) {
      if (n_results == 0)
        return false;
      this.current_match = (current_match + 1) % n_results;
      var row = completion_list.get_row_at_index (current_match);
      completion_list.select_row (row);

      return true;
    } else if (evt.keyval == Gdk.Key.Up) {
      current_match --;
      if (current_match < 0) current_match = n_results - 1;
      var row = completion_list.get_row_at_index (current_match);
      completion_list.select_row (row);

      return true;
    } else if (evt.keyval == Gdk.Key.Return) {
      if (n_results == 0)
        return false;
      if (current_match == -1)
        current_match = 0;
      var row = completion_list.get_row_at_index (current_match);
      string compl = ((Gtk.Label)(((Gtk.ListBoxRow)row).get_child ())).label;
      insert_completion (compl.substring (1));
      current_match = -1;
      completion_window.hide ();
      return true;
    } else if (evt.keyval == Gdk.Key.Escape) {
      completion_window.hide ();
      return true;
    }

    return false;
  }

  private void insert_completion (string compl) {
    tweet_text.buffer.freeze_notify ();
    Gtk.TextIter start_word_iter;
    Gtk.TextIter end_word_iter;
    string word_to_delete = get_cursor_word (out start_word_iter,
                                             out end_word_iter);
    debug ("Delete word: %s", word_to_delete);
    tweet_text.buffer.delete_range (start_word_iter, end_word_iter);

    Gtk.TextMark cursor_mark = tweet_text.buffer.get_insert ();
    tweet_text.buffer.get_iter_at_mark (out start_word_iter, cursor_mark);

    tweet_text.buffer.insert_text (ref start_word_iter, "@" + compl + " ", compl.length + 2);
    tweet_text.buffer.thaw_notify ();
  }


  private void show_completion_window () {
    int x, y;
    Gtk.Allocation alloc;
    tweet_text.get_allocation (out alloc);
    tweet_text.get_window (Gtk.TextWindowType.WIDGET).get_origin (out x, out y);
    x += alloc.x;
    y += alloc.y + alloc.height;

    completion_window.move (x, y);
    completion_window.resize (alloc.width, 50);
    completion_list.foreach ((w) => { completion_list.remove (w);});
    completion_window.show_all ();
  }


  private bool escape_pressed_cb () {
    if (completion_window.visible)
      completion_window.hide ();
    else
      this.destroy ();
    return true;
  }

  public void set_text (string text) {
    tweet_text.buffer.text = text;
  }

  private string get_cursor_word (out Gtk.TextIter start_iter,
                                  out Gtk.TextIter end_iter) {

    Gtk.TextMark cursor_mark = tweet_text.buffer.get_insert ();
    Gtk.TextIter cursor_iter;
    tweet_text.buffer.get_iter_at_mark (out cursor_iter, cursor_mark);

    Gtk.TextIter end_word_iter = Gtk.TextIter();
    end_word_iter.assign (cursor_iter);


    /* Check if the current "word" is just "@" */
    var test_iter = Gtk.TextIter ();
    test_iter.assign (cursor_iter);
    test_iter.backward_char ();
    if (tweet_text.buffer.get_text (test_iter, cursor_iter, false) != "@") {
      // Go to the word start and one char back(i.e. the @)
      cursor_iter.backward_word_start ();
      cursor_iter.backward_char ();

      // Go to the end of the word
      end_word_iter.forward_word_end ();
    } else {
      end_word_iter.assign (cursor_iter);
      cursor_iter.backward_char ();
    }
    start_iter = cursor_iter;
    start_iter.assign (cursor_iter);
    end_iter = end_word_iter;
    end_iter.assign (end_word_iter);
    return tweet_text.buffer.get_text (cursor_iter, end_word_iter, false);
  }
}
