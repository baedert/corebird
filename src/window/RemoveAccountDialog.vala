



[GtkTemplate (ui = "/org/baedert/corebird/ui/remove-account-dialog.ui")]
class RemoveAccountDialog : Gtk.Dialog {
  public signal void remove_clicked();


  public RemoveAccountDialog () {
    this.response.connect (on_response);
  }

  private void on_response (int id) {
    if (id == 1) {
      remove_clicked ();
    }
  }

  [GtkCallback]
  private void cancel_clicked_cb () {
    this.destroy ();
  }
}
