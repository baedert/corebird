using Gtk;

[GtkTemplate (ui = "/org/baedert/corebird/ui/account-info-widget.ui")]
class AccountInfoWidget : Gtk.Grid {
  [GtkChild]
  private Switch always_notify_switch;
  [GtkChild]
  private Label screen_name_label;
  [GtkChild]
  private Label name_label;

  public AccountInfoWidget (Account acc) {
    screen_name_label.label = acc.screen_name;
    name_label.label = acc.name;
  }
}
