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
  private Gtk.Box left_box;
  private PixbufButton media_image = new PixbufButton ();
  private string media_uri;
  private uint media_count = 0;
  private unowned Account account;
  private unowned Tweet answer_to;
  private Mode mode;


  public ComposeTweetWindow(Window? parent, Account acc,
                            Tweet? answer_to = null,
                            Mode mode = Mode.NORMAL,
                             Gtk.Application? app = null) { // {{{
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
    tweet_text.buffer.changed.connect (recalc_tweet_length);

    if (parent != null) {
      this.set_transient_for (parent);
    }

    if (mode != Mode.NORMAL) {
      TweetListEntry answer_entry = new TweetListEntry (answer_to, (MainWindow)parent, acc);
      content_box.pack_start (answer_entry, false, true);
    }

    if (mode == Mode.REPLY) {
      tweet_text.buffer.text = "@%s ".printf (answer_to.screen_name);
    } else if (mode == Mode.QUOTE) {
      tweet_text.buffer.text = " RT @%s “%s“".printf (answer_to.screen_name,
                                             Utils.unescape_html (answer_to.get_real_text ()));

      TextIter start_iter;
      tweet_text.buffer.get_start_iter (out start_iter);
      tweet_text.buffer.place_cursor (start_iter);
    }

    media_image.set_halign(Align.CENTER);
    media_image.set_valign(Align.START);

    media_image.clicked.connect (() => {
      media_image.set_visible(false);
      media_count--;
      if(media_count <= Twitter.max_media_per_upload)
        add_image_button.set_sensitive (true);
    });

    left_box.pack_end (media_image, false, true);

    //Let the text view immediately grab the keyboard focus
    tweet_text.grab_focus ();

    AccelGroup ag = new AccelGroup ();
    ag.connect (Gdk.Key.Escape, 0, AccelFlags.LOCKED,
        () => {this.destroy (); return true;});
    ag.connect (Gdk.Key.Return, Gdk.ModifierType.CONTROL_MASK, AccelFlags.LOCKED,
        () => {send_tweet (); return true;});

    this.add_accel_group (ag);
  } // }}}

  private void recalc_tweet_length () {
    TextIter start, end;
    tweet_text.buffer.get_start_iter(out start);
    tweet_text.buffer.get_end_iter(out end);
    string text = tweet_text.buffer.get_text(start, end, true);

    int length = TweetUtils.calc_tweet_length (text);

    int n_tweets = length / Tweet.MAX_LENGTH;
    if (Settings.long_tweet_method () == Settings.LongTweetMethod.SPLIT
        && n_tweets > 0) {
      length_label.label = "%d(%d)".printf (Tweet.MAX_LENGTH - (length - (n_tweets * Tweet.MAX_LENGTH)),
                                            n_tweets + 1);
    } else {
      length_label.label = (Tweet.MAX_LENGTH - length).to_string ();
    }

    if (length > Tweet.MAX_LENGTH &&
        Settings.long_tweet_method () == Settings.LongTweetMethod.FORBID) {
      send_button.sensitive = false;
    } else if (length > 0)
      send_button.sensitive = true;

  }

  [GtkCallback]
  private async void send_tweet () {
    TextIter start, end;
    tweet_text.buffer.get_start_iter (out start);
    tweet_text.buffer.get_end_iter (out end);
    string text = tweet_text.buffer.get_text (start, end, true);

    if(text.strip() == "" || !send_button.sensitive)
      return;

    // Just hide it now
    this.visible = false;

    int64 reply_id = -1;
    if (answer_to != null)
      reply_id = answer_to.id;

    int tweet_length = TweetUtils.calc_tweet_length (text);

    if (tweet_length <= Tweet.MAX_LENGTH) {
      yield TweetUtils.send_tweet (account,
                                   text,
                                   reply_id,
                                   media_uri);
    } else {
      yield TweetSplit.split_and_send (account, text, reply_id, answer_to.screen_name, media_uri);
    }

    this.destroy ();
  }

  [GtkCallback]
  private void cancel_clicked (Gtk.Widget source) {
    destroy ();
  }

  [GtkCallback]
  private void add_image_clicked () { // {{{
    FileChooserDialog fcd = new FileChooserDialog("Select Image", null, FileChooserAction.OPEN,
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
  } // }}}



  public void set_text (string text) {
    tweet_text.buffer.text = text;
  }
}
