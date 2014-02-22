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





[GtkTemplate (ui = "/org/baedert/corebird/ui/filter-page.ui")]
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
    tool_button = new BadgeRadioToolButton(group, "corebird-filter-symbolic");
    tool_button.tooltip_text = _("Filters");
    tool_button.label = _("Filters");
  }
  public Gtk.RadioToolButton? get_tool_button() { return tool_button; }
}
