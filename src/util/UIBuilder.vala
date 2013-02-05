

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
}