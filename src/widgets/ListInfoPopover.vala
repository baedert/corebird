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
[GtkTemplate (ui = "/org/baedert/corebird/ui/list-info-popover.ui")]
class ListInfoPopover : Gtk.Popover {
  [GtkChild]
  private Gtk.Label name_label;
  [GtkChild]
  private Gtk.Label description_label;
  [GtkChild]
  private Gtk.Label members_label;
  [GtkChild]
  private Gtk.Label subscribers_label;
  [GtkChild]
  private Gtk.Label created_at_label;
  [GtkChild]
  private Gtk.Label creator_label;
  [GtkChild]
  private Gtk.Label mode_label;
  [GtkChild]
  private Gtk.Stack mode_stack;
  [GtkChild]
  private Gtk.Stack name_stack;
  [GtkChild]
  private Gtk.Stack description_stack;
  [GtkChild]
  private Gtk.Entry name_entry;
  [GtkChild]
  private Gtk.Stack edit_stack;
  [GtkChild]
  private Gtk.Stack delete_stack;
  [GtkChild]
  private Gtk.ComboBox mode_combo_box;
  [GtkChild]
  private Gtk.Button save_button;
  [GtkChild]
  private Gtk.Button cancel_button;
  [GtkChild]
  private Gtk.TextView description_text_view;
  [GtkChild]
  private Gtk.Frame description_frame;
  [GtkChild]
  private Gtk.Button edit_button;
  [GtkChild]
  private Gtk.Button delete_button;

  public ListInfoPopover (int64  list_id,
                          string name,
                          bool   user_list,
                          string description,
                          string creator,
                          int    subscribers_count,
                          int    members_count,
                          int64  created_at,
                          string mode) {
    this.name_label.label = name;
    this.description_label.label = description;
    this.members_label.label = "%'d".printf (members_count);
    this.subscribers_label.label = "%'d".printf (subscribers_count);
    this.created_at_label.label = new GLib.DateTime.from_unix_local (created_at).format ("%x");
    this.creator_label.label = "@" + creator;
    this.mode_label.label = Utils.capitalize (mode);
  }



  [GtkCallback]
  private void edit_button_clicked_cb () {
    name_stack.visible_child = name_entry;
    description_stack.visible_child = description_frame;
    delete_stack.visible_child = cancel_button;
    //edit_stack.visible_child = save_button;
    mode_stack.visible_child = mode_combo_box;

    name_entry.text = real_list_name ();
    description_text_view.buffer.set_text (description_label.label);
    mode_combo_box.active_id = mode_label.label;
  }

  [GtkCallback]
  private void cancel_button_clicked_cb () {
    name_stack.visible_child = name_label;
    description_stack.visible_child = description_label;
    delete_stack.visible_child = delete_button;
    edit_stack.visible_child = edit_button;
    mode_stack.visible_child = mode_label;
  }

  private string real_list_name () {
    string cur_name = name_label.label;
    int slash_index = cur_name.index_of ("/");
    return cur_name.substring (slash_index + 1);
  }

}
