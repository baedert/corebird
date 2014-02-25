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
  [GtkChild]
  private Gtk.ListBox filter_list;
  private bool inited = false;

  public FilterPage (int id) {
    this.id = id;
    filter_list.add (new AddFilterEntry ());
    filter_list.row_activated.connect ((row) => {
      if (row is AddFilterEntry) {
        var dialog = new AddFilterDialog (main_window);
        dialog.show_all ();
      } else if (row is FilterListEntry) {

      }
    });
  }

  public void on_join (int page_id, va_list arg_list) {
    if (inited)
      return;


    account.db.select ("filters").cols ("content", "block_count", "id")
              .order ("id").run ((cols) => {
      var entry = new FilterListEntry ();
      entry.content = cols[0];
      entry.block_count = int.parse(cols[1]);
      return true;
     });
    inited = true;
  }




  public void on_leave () {}
  public void create_tool_button(Gtk.RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "corebird-filter-symbolic");
    tool_button.tooltip_text = _("Filters");
    tool_button.label = _("Filters");
  }
  public Gtk.RadioToolButton? get_tool_button() { return tool_button; }
}




class AddFilterEntry : Gtk.ListBoxRow {


  public AddFilterEntry () {
    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
    var img = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DIALOG);
    img.pixel_size = 32;
    img.margin_left = 10;
    img.hexpand = true;
    img.halign = Gtk.Align.END;
    box.pack_start (img);
    var l = new Gtk.Label (_("Add new Filter"));
    l.hexpand = true;
    l.halign = Gtk.Align.START;
    box.pack_start (l);
    add (box);
  }


}

