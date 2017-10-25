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

class CompletionTextView : Gtk.TextView {
  private const string NO_SPELL_CHECK = "gtksourceview:context-classes:no-spell-check";
  private const string[] TEXT_TAGS = {
    "link",
    "mention",
    "hashtag",
    "snippet"
  };
  private Gtk.Window completion_window;
  private int current_match = 0;
  private string? current_word = null;
  private GLib.Cancellable? completion_cancellable = null;

  private bool _default_listbox = true;
  public Gtk.ListBox completion_listbox {
    set {
      _default_listbox = false;
      Cb.Utils.unbind_non_gobject_model (completion_list, completion_model);
      this.completion_list = value;
      Cb.Utils.bind_non_gobject_model (completion_list, completion_model, create_completion_row);
    }
  }

  private Gtk.ListBox completion_list;
  private Cb.UserCompletionModel completion_model;

  public signal void show_completion ();
  public signal void hide_completion ();

  private unowned Account account;

  construct {
    completion_window = new Gtk.Window (Gtk.WindowType.POPUP);
    completion_window.set_type_hint (Gdk.WindowTypeHint.COMBO);
    completion_window.focus_out_event.connect (completion_window_focus_out_cb);
    completion_window.set_screen (this.get_screen ());

    completion_list = new Gtk.ListBox ();
    completion_model = new Cb.UserCompletionModel ();
    Cb.Utils.bind_non_gobject_model (completion_list, completion_model, create_completion_row);
    var placeholder_label = new Gtk.Label (_("No users found"));
    placeholder_label.get_style_context ().add_class ("dim-label");
    placeholder_label.show ();
    completion_list.set_placeholder (placeholder_label);

    var scroller = new Gtk.ScrolledWindow (null, null);
    scroller.add (completion_list);
    var frame = new Gtk.Frame (null);
    frame.add (scroller);
    completion_window.add (frame);

    this.focus_out_event.connect (completion_window_focus_out_cb);

    /* Your theme uses a wildcard for :link, right? */
    var style_context = this.get_style_context ();
    style_context.save ();
    style_context.set_state (Gtk.StateFlags.LINK);
    Gdk.RGBA link_color = style_context.get_color ();
    style_context.restore ();

    if (link_color.red ==   1.0 &&
        link_color.green == 1.0 &&
        link_color.blue ==  1.0 &&
        link_color.alpha == 1.0) {
      /* Unset, fall back to Adwaita's default */
      link_color = {
        0.16470,
        0.462735,
        0.77647,
        1.0
      };
    }

    Gdk.RGBA snippet_color = { 0.0, 0.65, 0.0627, 1.0};

    this.buffer.create_tag (TEXT_TAGS[0],
                            "foreground_rgba",
                            link_color, null);
    this.buffer.create_tag (TEXT_TAGS[1],
                            "foreground_rgba",
                            link_color, null);
    this.buffer.create_tag (TEXT_TAGS[2],
                            "foreground_rgba",
                            link_color, null);
    this.buffer.create_tag (TEXT_TAGS[3],
                            "foreground_rgba",
                            snippet_color, null);
    /* gspell marker */
    this.buffer.create_tag (NO_SPELL_CHECK, null);

    this.buffer.notify["cursor-position"].connect (update_completion_listbox);
    this.buffer.changed.connect (buffer_changed_cb);
    this.key_press_event.connect (key_press_event_cb);

    /* Set them here so they are consistent everywhere */
    this.right_margin  = 6;
    this.left_margin   = 6;
    this.top_margin    = 6;
    this.bottom_margin = 6;

#if SPELLCHECK
    var gspell_view = Gspell.TextView.get_from_gtk_text_view (this);
    gspell_view.set_inline_spell_checking (true);
    gspell_view.set_enable_language_menu (true);

    var gspell_buffer = Gspell.TextBuffer.get_from_gtk_text_buffer (this.buffer);
    var checker = new Gspell.Checker (Gspell.Language.get_default ());
    gspell_buffer.set_spell_checker (checker);
#endif
  }

  public void set_account (Account account) {
    this.account = account;
  }

  private bool insert_snippet () {
    Gtk.TextIter cursor_word_start;
    Gtk.TextIter cursor_word_end;
    string cursor_word = get_cursor_word (out cursor_word_start,
                                          out cursor_word_end);

    /* See the git log for an explanation */
    if (cursor_word.get_char (0) == ' ' ||
        cursor_word.get_char (0) == '\t' ||
        cursor_word.get_char (0) == '\n') {
      cursor_word = cursor_word.substring (1);
      cursor_word_start.forward_char ();
    }

    string? snippet = Corebird.snippet_manager.get_snippet (cursor_word.strip ());

    if (snippet == null) {
      debug ("No snippet for cursor_word '%s' found.", cursor_word);
      return false;
    }

    Gtk.TextIter start_word_iter;

    this.buffer.freeze_notify ();
    this.buffer.delete_range (cursor_word_start, cursor_word_end);

    Gtk.TextMark cursor_mark = this.buffer.get_insert ();
    this.buffer.get_iter_at_mark (out start_word_iter, cursor_mark);

    this.buffer.insert_text (ref start_word_iter, snippet, snippet.length);
    this.buffer.thaw_notify ();

    return true;
  }

  private inline bool snippets_configured () {
    return Corebird.snippet_manager.n_snippets () > 0;
  }

  private void select_completion_row (Gtk.ListBoxRow? row) {
    if (row == null)
      return;

    assert (row.get_parent () == completion_list);

    Gtk.Allocation alloc;
    row.get_allocation (out alloc);

    completion_list.select_row (row);

    Gtk.Viewport viewport = completion_list.get_parent () as Gtk.Viewport;

    if (viewport == null)
      return;

    Gtk.ScrolledWindow scroller = viewport.get_parent () as Gtk.ScrolledWindow;

    if (scroller != null) {
      Gtk.Adjustment adjustment = scroller.get_vadjustment ();

      adjustment.clamp_page (alloc.y, alloc.y + alloc.height);
    }
  }

  private bool key_press_event_cb (Gdk.EventKey evt) {
    uint keyval;

    evt.get_keyval (out keyval);

    if (keyval == Gdk.Key.Tab && snippets_configured ()) {
      return insert_snippet ();
    }

    /* If we are not in 'completion mode' atm, just back out. */
    if (!completion_list.get_mapped ())
      return Gdk.EVENT_PROPAGATE;


    int n_results = (int)completion_model.get_n_items ();

    switch (keyval) {
      case Gdk.Key.Down:
        if (n_results == 0)
          return Gdk.EVENT_PROPAGATE;

        this.current_match = (current_match + 1) % n_results;
        var row = completion_list.get_row_at_index (current_match);
        if (_default_listbox) {
          row.grab_focus ();
        }
        select_completion_row (row);

        return Gdk.EVENT_STOP;

      case Gdk.Key.Up:
        current_match --;
        if (current_match < 0) current_match = n_results - 1;
        var row = completion_list.get_row_at_index (current_match);
        if (_default_listbox) {
          row.grab_focus ();
        }
        select_completion_row (row);

        return Gdk.EVENT_STOP;

      case Gdk.Key.Return:
        if (n_results == 0)
          return Gdk.EVENT_PROPAGATE;
        if (current_match == -1)
          current_match = 0;
        var row = completion_list.get_row_at_index (current_match);
        assert (row is UserCompletionRow);
        string compl = ((UserCompletionRow)row).get_screen_name ();
        insert_completion (compl.substring (1));
        current_match = -1;
        hide_completion_window ();
        return Gdk.EVENT_STOP;

      case Gdk.Key.Escape:
        hide_completion_window ();
        return Gdk.EVENT_STOP;

      default:
        return Gdk.EVENT_PROPAGATE;
    }
  }

  private void buffer_changed_cb () {
    Gtk.TextIter? start_iter;
    Gtk.TextIter? end_iter;
    this.buffer.get_start_iter (out start_iter);
    this.buffer.get_end_iter (out end_iter);
    var tag_table = this.buffer.get_tag_table ();

    /* We can't use gtk_text_buffer_remove_all_tags because that will also
       remove the ones added by gspell */
    for (int i = 0; i < TEXT_TAGS.length; i ++)
      this.buffer.remove_tag (tag_table.lookup (TEXT_TAGS[i]), start_iter, end_iter);

    string text = this.buffer.get_text (start_iter, end_iter, true);
    size_t text_length;
    var entities = Tl.extract_entities_and_text (text, out text_length);
    foreach  (unowned Tl.Entity e in entities) {
      Gtk.TextIter? e_start_iter;
      Gtk.TextIter? e_end_iter;

      this.buffer.get_iter_at_offset (out e_start_iter, (int)e.start_character_index);
      this.buffer.get_iter_at_offset (out e_end_iter, (int)(e.start_character_index + e.length_in_characters));

      switch (e.type) {
        case Tl.EntityType.HASHTAG:
          buffer.apply_tag_by_name (NO_SPELL_CHECK, e_start_iter, e_end_iter);
          buffer.apply_tag_by_name ("hashtag", e_start_iter, e_end_iter);
          break;
        case Tl.EntityType.MENTION:
          buffer.apply_tag_by_name (NO_SPELL_CHECK, e_start_iter, e_end_iter);
          buffer.apply_tag_by_name ("mention", e_start_iter, e_end_iter);
          break;
        case Tl.EntityType.LINK:
          buffer.apply_tag_by_name (NO_SPELL_CHECK, e_start_iter, e_end_iter);
          buffer.apply_tag_by_name ("link", e_start_iter, e_end_iter);
          break;

        case Tl.EntityType.TEXT:
          if (Corebird.snippet_manager.has_snippet_n (e.start, e.length_in_bytes)) {
            buffer.apply_tag_by_name (NO_SPELL_CHECK, e_start_iter, e_end_iter);
            buffer.apply_tag_by_name ("snippet", e_start_iter, e_end_iter);
          }
          break;

        default:
          break;
      }
    }

    if (buffer.text.length == 0)
      hide_completion_window ();
  }

  private void show_completion_window () {
    if (!this.get_mapped ())
      return;

    completion_model.clear ();

    if (!_default_listbox) {
      this.show_completion ();
      return;
    }

    debug ("show_completion_window");
    int x, y;
    Gtk.Allocation alloc;
    this.get_allocation (out alloc);
    this.get_window (Gtk.TextWindowType.WIDGET).get_origin (out x, out y);
    y += alloc.height;

    /* +2 for the size and -1 for x since we account for the
       frame size around the text view */
    completion_window.set_attached_to (this);
    completion_window.set_transient_for ((Gtk.Window) this.get_toplevel ());
    completion_window.move (x - 1, y);
    completion_window.resize (alloc.width + 2, 50);
    completion_window.show ();
  }

  private void hide_completion_window () {
    this.current_word = null;

    if (!_default_listbox) {
      hide_completion ();
      return;
    }

    completion_window.hide ();
  }

  private bool completion_window_focus_out_cb () {
    if (_default_listbox) {
      hide_completion_window ();
    }

    return false;
  }


  private void update_completion_listbox () {
    string cur_word = get_cursor_word (null, null);
    int n_chars = cur_word.char_count ();

    if (n_chars == 0) {
      hide_completion_window ();
      return;
    }

    /* Check if the word ends with a 'special' character like ?!_ */
    char end_char = cur_word.get (n_chars - 1);
    bool word_has_alpha_end = (end_char.isalpha () || end_char.isdigit ()) &&
                              end_char.isgraph () || end_char == '@';

    if (!cur_word.has_prefix ("@") ||
        !word_has_alpha_end ||
        this.buffer.has_selection) {
      hide_completion_window ();
      return;
    }

    // Strip off the @
    cur_word = cur_word.substring (1);

    if (cur_word == null || cur_word.length == 0) {
      hide_completion_window ();
      return;
    }

    if (cur_word != this.current_word) {

      if (this.completion_cancellable != null) {
        debug ("Cancelling earlier completion call...");
        this.completion_cancellable.cancel ();
      }

      /* Clears the model */
      show_completion_window ();

      /* Query users from local cache */
      Cb.UserInfo[] corpus;
      account.user_counter.query_by_prefix (account.db.get_sqlite_db (),
                                            cur_word, 10,
                                            out corpus);
      completion_model.insert_infos (corpus);

      bool corpus_was_empty = (corpus.length == 0);
      if (corpus.length > 0) {
        select_completion_row (completion_list.get_row_at_index (0));
        current_match = 0;
      }
      corpus = null; /* Make sure we won't use it again */

      /* Now also query users from the Twitter server, in case our local cache doesn't have anything
         worthwhile */
      this.completion_cancellable = new GLib.Cancellable ();
      Cb.Utils.query_users_async.begin (account.proxy, cur_word, completion_cancellable, (obj, res) => {
        Cb.UserIdentity[] users;
        try {
          users = Cb.Utils.query_users_async.end (res);
        } catch (GLib.Error e) {
          if (!(e is GLib.IOError.CANCELLED))
            warning ("User completion call error: %s", e.message);

          return;
        }

        completion_model.insert_items (users);
        if (users.length > 0 && corpus_was_empty) {
          select_completion_row (completion_list.get_row_at_index (0));
          current_match = 0;
        }
      });

      this.current_word = cur_word;

      completion_list.show ();
    }
  }

  private string get_cursor_word (out Gtk.TextIter start_iter,
                                  out Gtk.TextIter end_iter) {

    Gtk.TextMark cursor_mark = this.buffer.get_insert ();
    Gtk.TextIter cursor_iter;
    this.buffer.get_iter_at_mark (out cursor_iter, cursor_mark);

    /* Check if the current "word" is just "@" */
    var test_iter = Gtk.TextIter ();
    test_iter.assign (cursor_iter);


    for (;;) {
      Gtk.TextIter left_iter = test_iter;
      left_iter.assign (test_iter);

      left_iter.backward_char ();

      string s = this.buffer.get_text (left_iter, test_iter, false);
      unichar c = s.get_char (0);
      assert (s.char_count () == 1 ||
              s.char_count () == 0);

      if (left_iter.is_start ())
        test_iter.assign (left_iter);

      if (c.isspace() || left_iter.is_start ()) {
        break;
      }

      test_iter.assign (left_iter);
    }

    start_iter = test_iter;
    start_iter.assign (test_iter);
    end_iter = cursor_iter;
    end_iter.assign (cursor_iter);
    return this.buffer.get_text (test_iter, cursor_iter, false);
  }

  private void insert_completion (string compl) {
    this.buffer.freeze_notify ();
    Gtk.TextIter start_word_iter;
    Gtk.TextIter end_word_iter;
    string word_to_delete = get_cursor_word (out start_word_iter,
                                             out end_word_iter);
    debug ("Delete word: %s", word_to_delete);
    this.buffer.delete_range (start_word_iter, end_word_iter);

    Gtk.TextMark cursor_mark = this.buffer.get_insert ();
    this.buffer.get_iter_at_mark (out start_word_iter, cursor_mark);

    this.buffer.insert_text (ref start_word_iter, "@" + compl + " ", compl.length + 2);
    this.buffer.thaw_notify ();
  }

  private Gtk.Widget create_completion_row (void *id_ptr) {
    // *shrug*
    Cb.UserIdentity *id = (Cb.UserIdentity*) id_ptr;
    var row = new UserCompletionRow (id->id, id->user_name, id->screen_name, id->verified);

    row.show ();
    return row;
  }

  ~CompletionTextView () {
    Cb.Utils.unbind_non_gobject_model (completion_list, completion_model);
  }
}

class UserCompletionRow : Gtk.ListBoxRow {
  private static Cairo.Surface verified_surface;
  private Gtk.Label user_name_label;
  private Gtk.Label screen_name_label;

  static construct {
    try {
      verified_surface = Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/org/baedert/corebird/data/verified-small.png"),
          1, null);
    } catch (GLib.Error e) {
      error (e.message);
    }
  }

  public UserCompletionRow (int64 id, string user_name, string screen_name, bool verified) {
    user_name_label = new Gtk.Label (user_name);
    screen_name_label = new Gtk.Label ("@" + screen_name);

    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    user_name_label.set_valign (Gtk.Align.BASELINE);
    user_name_label.set_use_markup (true);
    user_name_label.set_ellipsize (Pango.EllipsizeMode.END);
    box.add (user_name_label);
    screen_name_label.set_valign (Gtk.Align.BASELINE);
    screen_name_label.get_style_context ().add_class ("dim-label");
    box.add (screen_name_label);

    if (verified) {
      var verified_image= new Gtk.Image.from_surface (verified_surface);
      box.add (verified_image);
    }

    box.margin = 2;
    this.add (box);
  }

  public string get_screen_name () {
    return screen_name_label.get_label ();
  }

}
