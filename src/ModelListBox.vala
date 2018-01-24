
public class ModelListBox : Gd.ModelListBox {
  public Cb.TweetRow action_entry;
  public signal void retry_button_clicked ();

  public ModelListBox() {
    this.set_model (new Cb.TweetModel (),
                    widget_fill_func, null);
  }

  private Gtk.Widget widget_fill_func (GLib.Object item, Gtk.Widget? old_row, uint index) {
    Cb.TweetRow row = old_row as Cb.TweetRow;
    Cb.Tweet tweet = item as Cb.Tweet;

    assert (tweet != null);

    if (row == null) {
      row = new Cb.TweetRow (tweet, (MainWindow)this.get_toplevel ());
    } else {
      row.set_tweet (tweet);
    }

    return row;
  }

  public void set_error (string s) {
  }

  public void set_empty () {
  }

  public Gtk.Widget get_first_visible_row () {
    return null;
  }

  public void set_account (Account a) {}

  public Gtk.Widget get_row_at_index (int i) { return null; }
}
