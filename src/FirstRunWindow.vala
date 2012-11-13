
using Gtk;


class FirstRunWindow : Window {
	private Button cancel_button = new Button.with_label("Cancel");
	private Button next_button = new Button.with_label("Next");
	private Notebook notebook = new Notebook();
	private Box main_box = new Box(Orientation.VERTICAL, 2);
	private Box button_box = new Box(Orientation.HORIZONTAL, 15);


	public FirstRunWindow(){
		this.set_default_size(600, 300);
		notebook.show_border = false;
		notebook.show_tabs = false;
		notebook.append_page(new Label("thihi"));
		main_box.pack_start(notebook, true, true);


		cancel_button.margin_left = 10;
		cancel_button.margin_bottom = 10;
		cancel_button.clicked.connect( () => {
			this.destroy();
		});
		button_box.pack_start(cancel_button, false, false);
		next_button.margin_right = 10;
		next_button.margin_bottom = 10;
		button_box.pack_end (next_button, false, false);



		main_box.pack_end(button_box, false, false);
		this.add(main_box);
		// this.resizable = false;
		this.show_all();
	}



}