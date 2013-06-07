/*  This file is part of corebird.
 *
 *  Foobar is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Foobar is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;


public class UIBuilder {
	private Gtk.Builder builder = new Gtk.Builder();


	public UIBuilder(string path, string object_name = ""){
		try {
			if(object_name != "")
				builder.add_objects_from_file(path, {object_name});
			else
				builder.add_from_file(path);
		} catch(GLib.Error e) {
			critical("Loading %s: %s", path, e.message);
		}
	}

	public Button get_button(string name){
		return builder.get_object(name) as Button;
	}

	public Window get_window(string name){
		return builder.get_object(name) as Window;
	}

	public Dialog get_dialog(string name) {
		return builder.get_object(name) as Dialog;
	}

	public Switch get_switch(string name) {
		return builder.get_object(name) as Switch;
	}

	public Label get_label(string name){
		return builder.get_object(name) as Label;
	}

	public Image get_image(string name){
		return builder.get_object(name) as Image;
	}

	public Box get_box(string name){
		return builder.get_object(name) as Box;
	}

	public ToggleButton get_toggle(string name){
		return builder.get_object(name) as ToggleButton;
	}

	public Notebook get_notebook(string name){
		return builder.get_object(name) as Notebook;
	}

	public Entry get_entry(string name){
		return builder.get_object(name) as Entry;
	}

	public MenuModel get_menu_model(string name){
		return builder.get_object(name) as MenuModel;
	}
	public SpinButton get_spin_button(string name) {
		return builder.get_object(name) as SpinButton;
	}

	public ComboBox get_combobox(string name){
		return builder.get_object(name) as ComboBox;
	}
}
