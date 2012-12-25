

using Gtk;


public class UIBuilder {
	private Gtk.Builder builder = new Gtk.Builder();


	public UIBuilder(string path){
		builder.add_from_file(path);
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
}