




class FilterPage : Gtk.ScrolledWindow, IPage {
  public int id { get; set; }
  public unowned MainWindow main_window {get; set;}
  public unowned Account account        {get; set;}

  private Gtk.RadioToolButton tool_button;


  public FilterPage (int id) {
    this.id = id;
  }
  public void on_join (int page_id, va_list arg_list) {
  }
  public void on_leave () {

  }
  public void create_tool_button(Gtk.RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "corebird-filters-symbolic");
    tool_button.tooltip_text = _("Filters");
    tool_button.label = _("Filters");
  }
  public Gtk.RadioToolButton? get_tool_button() { return tool_button; }
}
