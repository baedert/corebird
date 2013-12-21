




class UserListDialog : Gtk.Dialog {
  private static const int SAVE_RESPONSE   = 2;
  private static const int CANCEL_RESPONSE = -1;
  private unowned Account account;
  private Gtk.ListBox list_list_box = new Gtk.ListBox ();

  public UserListDialog (MainWindow parent, Account account) {
    set_modal (true);
    set_transient_for (parent);
    add_button ("Cancel", CANCEL_RESPONSE);
    add_button ("Save", SAVE_RESPONSE);


    var content_box = get_content_area ();
    var scroller = new Gtk.ScrolledWindow (null, null);
    scroller.add (list_list_box);
    content_box.pack_start (scroller, true, true);
  }


  public override void response (int response_id) {
    if (response_id == CANCEL_RESPONSE) {
      this.destroy ();
    } else if (response_id == SAVE_RESPONSE) {
      this.destroy ();
    }
  }
}
