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


using Gtk;

[GtkTemplate (ui = "/org/baedert/corebird/ui/compose-window.ui")]
class ComposeTweetWindow : Gtk.ApplicationWindow {
  public enum Mode {
    NORMAL,
    REPLY,
    QUOTE
  }
  [GtkChild]
  private Gtk.Image avatar_image;
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


  public ComposeTweetWindow(Window? parent, Account acc,
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

      TextIter start_iter;
      tweet_text.buffer.get_start_iter (out start_iter);
      tweet_text.buffer.place_cursor (start_iter);
    }

    //Let the text view immediately grab the keyboard focus
    tweet_text.grab_focus ();

    AccelGroup ag = new AccelGroup ();
    ag.connect (Gdk.Key.Escape, 0, AccelFlags.LOCKED, escape_pressed_cb);
    ag.connect (Gdk.Key.Return, Gdk.ModifierType.CONTROL_MASK, AccelFlags.LOCKED,
        () => {send_tweet (); return true;});

    this.add_accel_group (ag);
  }

  private void buffer_changed_cb () {
    recalc_tweet_length ();
    update_completion ();
  }

  private void recalc_tweet_length () {
    TextIter start, end;
    tweet_text.buffer.get_start_iter(out start);
    tweet_text.buffer.get_end_iter(out end);
    string text = tweet_text.buffer.get_text(start, end, true);

    int length = TweetUtils.calc_tweet_length (text);

    length_label.label = (Tweet.MAX_LENGTH - length).to_string ();
    if (length > 0 && length <= Tweet.MAX_LENGTH)
      send_button.sensitive = true;
    else
      send_button.sensitive = false;
  }

  private void update_completion () {
    string text = tweet_text.buffer.text;
    int cursor_position = tweet_text.buffer.cursor_position;
    string cur_word = "";
    string[] words = text.split (" ");

    int cur_pos = 0;
    foreach (string s in words) {
      cur_pos += s.length + 1;
      if (cur_pos >= cursor_position) {
        cur_word = s;
        break;
      }
    }

    if (!cur_word.has_prefix ("@")) {
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
    TextIter start, end;
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
    FileChooserDialog fcd = new FileChooserDialog(_("Select Image"), null, FileChooserAction.OPEN,
                                                  _("Cancel"), ResponseType.CANCEL,
                                                  _("Choose"),   ResponseType.ACCEPT);
    fcd.set_modal (true);
    FileFilter filter = new FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    filter.add_mime_type ("image/gif");
    fcd.set_filter (filter);
    if (fcd.run () == ResponseType.ACCEPT) {
      string file = fcd.get_filename ();
      this.media_uri = file;
      try {
        media_image.set_bg(new Gdk.Pixbuf.from_file_at_size (file, 40, 40));
        media_count++;
        media_image.set_visible(true);
      } catch (GLib.Error e){critical ("Loading scaled image: %s", e.message);}

      if (media_count >= Twitter.max_media_per_upload){
        add_image_button.set_sensitive (false);
      }
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
    return true;
  }

  [GtkCallback]
  private bool tweet_text_key_pressed_cb (Gdk.EventKey evt) {
    /* If we are not in 'completion mode' atm, just back out. */
    if (!completion_window.visible)
      return false;


    int n_results = (int)completion_list.get_children ().length ();

    if (evt.keyval == Gdk.Key.Down) {
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
      if (current_match == -1)
        current_match =0;
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
    Gtk.TextMark cursor_mark = tweet_text.buffer.get_insert ();
    Gtk.TextIter cursor_iter;
    tweet_text.buffer.get_iter_at_mark (out cursor_iter, cursor_mark);
    cursor_iter.backward_word_start ();
    cursor_iter.backward_char ();

    Gtk.TextIter end_word_iter = Gtk.TextIter();
    end_word_iter.assign (cursor_iter);
    end_word_iter.forward_word_end ();

    message (tweet_text.buffer.get_text (cursor_iter, end_word_iter, false));
    tweet_text.buffer.delete_range (cursor_iter, end_word_iter);
    cursor_mark = tweet_text.buffer.get_insert ();
    tweet_text.buffer.get_iter_at_mark (out cursor_iter, cursor_mark);
    tweet_text.buffer.insert_text (ref cursor_iter, "@" + compl + " ", compl.length + 2);
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
}
