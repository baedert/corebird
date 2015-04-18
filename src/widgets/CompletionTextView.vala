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
  private Gtk.ListBox completion_list;
  private Gtk.Window completion_window;
  private int current_match = 0;


  private unowned Account account;

  construct {
    completion_window = new Gtk.Window (Gtk.WindowType.POPUP);
    completion_window.set_type_hint (Gdk.WindowTypeHint.COMBO);
    completion_window.focus_out_event.connect (completion_window_focus_out_cb);
    completion_window.set_screen (this.get_screen ());

    completion_list = new Gtk.ListBox ();

    var scroller = new Gtk.ScrolledWindow (null, null);
    scroller.add (completion_list);
    completion_window.add (scroller);

    this.focus_out_event.connect (completion_window_focus_out_cb);

    /* Your theme uses a wildcard for :link, right? */
    var style_context = this.get_style_context ();
    Gdk.RGBA link_color = style_context.get_color (Gtk.StateFlags.LINK);

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

    this.buffer.create_tag ("link",
                            "foreground_rgba",
                            link_color, null);
    this.buffer.create_tag ("mention",
                            "foreground_rgba",
                            link_color, null);
    this.buffer.create_tag ("hashtag",
                            "foreground_rgba",
                            link_color, null);
    this.buffer.notify["cursor-position"].connect (update_completion);
    this.buffer.changed.connect (buffer_changed_cb);
    this.key_press_event.connect (key_press_event_cb);
  }

  public void set_account (Account account) {
    this.account = account;
  }


  public bool key_press_event_cb (Gdk.EventKey evt) {
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

  private void buffer_changed_cb () {
    Gtk.TextIter? start_iter;
    Gtk.TextIter? end_iter;
    this.buffer.get_start_iter (out start_iter);
    this.buffer.get_end_iter (out end_iter);
    this.buffer.remove_all_tags (start_iter, end_iter);
    TweetUtils.annotate_text (this.buffer);
  }

  private void show_completion_window () {
    debug ("show_completion_window");
    if (!this.get_mapped ())
      return;

    int x, y;
    Gtk.Allocation alloc;
    this.get_allocation (out alloc);
    this.get_window (Gtk.TextWindowType.WIDGET).get_origin (out x, out y);
    y += alloc.height;

    completion_window.move (x, y);
    completion_window.resize (alloc.width, 50);
    completion_list.foreach ((w) => { completion_list.remove (w);});
    completion_window.show_all ();
  }

  private bool completion_window_focus_out_cb () {
    completion_window.hide ();
    return false;
  }


  private void update_completion () {
    string cur_word = get_cursor_word (null, null);

    /* Check if the word ends with a 'special' character like ?!_ */
    char end_char = cur_word.get (cur_word.char_count () - 1);
    bool word_has_alpha_end = (end_char.isalpha () || end_char.isdigit ()) &&
                              end_char.isgraph () || end_char == '@';
    if (!cur_word.has_prefix ("@") || !word_has_alpha_end
        || this.buffer.has_selection) {
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
    if (corpus_size > 0) {
      completion_list.select_row (completion_list.get_row_at_index (0));
      current_match = 0;
    }
    completion_list.show_all ();

  }

  private string get_cursor_word (out Gtk.TextIter start_iter,
                                  out Gtk.TextIter end_iter) {

    Gtk.TextMark cursor_mark = this.buffer.get_insert ();
    Gtk.TextIter cursor_iter;
    this.buffer.get_iter_at_mark (out cursor_iter, cursor_mark);

    Gtk.TextIter end_word_iter = Gtk.TextIter();
    end_word_iter.assign (cursor_iter);


    /* Check if the current "word" is just "@" */
    var test_iter = Gtk.TextIter ();
    test_iter.assign (cursor_iter);
    test_iter.backward_char ();
    if (this.buffer.get_text (test_iter, cursor_iter, false) != "@") {
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
    return this.buffer.get_text (cursor_iter, end_word_iter, false);
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


}
