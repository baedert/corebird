using Gtk;


/**
 * A VERY simple preferenes dialog that tries to unify the look.
 */
class PreferencesDialog : Dialog {
	private static int RESPONSE_CLOSE = 1;
	public delegate void BoolDelegate(bool value);
	public delegate void IntDelegate(int value);
	public delegate void ArrayDelegate(int index);
	private Notebook nb = new Notebook();
	private int[] heights;



	public PreferencesDialog(string title, int num_pages){
		this.title = title;
		this.heights = new int[num_pages];
		this.border_width = 5;
		this.get_content_area().pack_start(nb, true, true);
		add_button("Close", RESPONSE_CLOSE);

		this.response.connect( (id) => {
			if (id == RESPONSE_CLOSE)
				this.destroy();
		});
	}

	/**
	 * Appends a new page to the end of the dialog's notebook.
	 *
	 * @param title The title of the tab
	 * @return The page's index. Used for the other operations
	 */
	public int append_page(string title){
		Grid grid = new Grid();
		grid.column_homogeneous = true;
		grid.row_spacing = 3;
		grid.column_spacing = 8;
		grid.border_width = 10;

		return nb.append_page(grid, new Label(title));
	}

	public void add_heading(int page, string title){
		Label heading = new Label("");
		heading.use_markup = true;
		heading.set_markup("<b>"+title+"</b>");
		heading.xalign = 0.0f;
		Grid grid = (Grid)nb.get_nth_page(page);
		grid.attach(heading, 0, heights[page], 2, 1);
		heights[page]++;
	}


	public void add_bool_option(int page, string title,
	                              bool default_value,
	                              BoolDelegate action){
		Grid grid = (Grid)nb.get_nth_page(page);
		Label title_label = new Label(title);
		title_label.xalign = 1.0f;
		Switch action_switch = new Switch();
		action_switch.active = default_value;
		action_switch.notify["active"].connect( () => {
			action(action_switch.active);
		});
		action_switch.set_halign(Align.START);
		grid.attach(title_label, 0, heights[page], 1, 1);
		grid.attach(action_switch, 1, heights[page], 1, 1);
		heights[page]++;
	}

	public void add_int_option(int page, string title,
	                           int min, int val, int max, IntDelegate action){
		Grid grid = (Grid)nb.get_nth_page(page);
		Label title_label = new Label(title);
		title_label.xalign = 1.0f;
		SpinButton sb = new SpinButton.with_range(min, max, 1);
		sb.value = val;
		sb.numeric = false;
		sb.set_halign(Align.START);
		sb.value_changed.connect( () => {
			action((int)sb.value);
		});
		grid.attach(title_label, 0, heights[page], 1, 1);
		grid.attach(sb, 1, heights[page], 1, 1);
		heights[page]++;
	}

	// TODO: Something in here causes a crash
	public void add_array_option(int page, string title, string[] options,
	                             int default_index, ArrayDelegate action){
		Grid grid = (Grid)nb.get_nth_page(page);
		Label title_label = new Label(title);
		title_label.xalign = 1.0f;
		
		ListStore store = new ListStore(1, typeof(string));
		TreeIter iter;
		foreach(string item in options){
			store.append(out iter);	
			store.set(iter, 0, item);
		}
		ComboBox combo = new ComboBox.with_model(store);
		combo.set_halign(Align.START);
		CellRendererText renderer = new CellRendererText();
		combo.pack_start(renderer, true);
		combo.add_attribute(renderer, "text", 0);
		combo.active = default_index;
		combo.changed.connect( () => {
			int index = combo.get_active();
			action(index);
		});

		grid.attach(title_label, 0, heights[page], 1, 1);
		grid.attach(combo, 1, heights[page], 1, 1);
		heights[page]++;	
	}
}