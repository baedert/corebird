using Gtk;




class MainWindow : ApplicationWindow {
	public static const int PAGE_STREAM    = 0;
	public static const int PAGE_MENTIONS  = 1;
	public static const int PAGE_FAVORITES = 2;
	public static const int PAGE_SEARCH    = 3;


	private Toolbar left_toolbar             = new Toolbar();
	private Toolbar primary_toolbar          = new Toolbar();
	private Box main_box                     = new Box(Orientation.VERTICAL, 0);
	private Box bottom_box                   = new Box(Orientation.HORIZONTAL, 0);
	private Notebook main_notebook           = new Notebook();
	// private TweetContainer[] containers      = new TweetContainer[4];
	private Timeline[] timelines			 = new Timeline[2];
	private ToolButton avatar_button         = new ToolButton(null, null);
	private ToolButton refresh_button        = new ToolButton.from_stock(Stock.REFRESH);
	private ToolButton settings_button       = new ToolButton.from_stock(Stock.PROPERTIES);
	private ToolButton new_tweet_button      = new ToolButton.from_stock(Stock.NEW);
	private SeparatorToolItem expander_item  = new SeparatorToolItem();
	private SeparatorToolItem left_separator = new SeparatorToolItem();
	private PaneWidget right_pane;

	public MainWindow(Gtk.Application app){
		GLib.Object (application: app);

		timelines[0] = new HomeTimeline(PAGE_STREAM);
		timelines[1] = new MentionsTimeline(PAGE_MENTIONS);
		// timelines[2] = new FavoriteContainer(PAGE_FAVORITES);
		// timelines[3] = new SearchContainer(PAGE_SEARCH);

		/** Initialize all containers */
		for(int i = 0; i < timelines.length; i++){
			Timeline tl = timelines[i];
			tl.load_cached();
			tl.main_window = this;
			tl.create_tool_button(timelines[0].get_tool_button());
			tl.get_tool_button().toggled.connect(() => {
				if(tl.get_tool_button().active)
					this.main_notebook.set_current_page(tl.get_id());
			});
		}

		//Load the user's sceen_name used for identifying him
		User.load();
		//Update the Twitter config
		Twitter.update_config.begin();

		this.delete_event.connect(() => {
			//message("destroy.");
			NotificationManager.uninit();
			// if (Settings.show_tray_icon()){
				// 'Minimize to tray'
				// set_visible(false);
			// }else{
				save_geometry();
				this.application.release();
			// }
			return true;
		});

		new_tweet_button.clicked.connect( () => {
		 	NewTweetWindow win = new NewTweetWindow(this);
			win.show_all();

		});

		//Load custom style sheet
		try{
			CssProvider provider = new CssProvider();
			provider.load_from_file(File.new_for_path("ui/style.css"));
			Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
		                                         STYLE_PROVIDER_PRIORITY_APPLICATION);
		}catch(GLib.Error e){
			warning("Error while loading ui/style.css: %s", e.message);
		}

		left_toolbar.orientation = Orientation.VERTICAL;
		left_toolbar.set_style(ToolbarStyle.ICONS);

		primary_toolbar.orientation = Orientation.HORIZONTAL;
		primary_toolbar.set_style(ToolbarStyle.ICONS);
		primary_toolbar.get_style_context().add_class("primary-toolbar");
		primary_toolbar.set_visible(true);


		expander_item.draw = false;
		expander_item.set_expand(true);


		avatar_button.set_icon_widget(new Image.from_file(User.get_avatar_path()));
		avatar_button.clicked.connect( () => {
			ProfileDialog pd = new ProfileDialog();
			pd.show_all();
		});

		//Update the user's info
		User.update_info.begin((Image)avatar_button.icon_widget);

		// Add all tool buttons for the timelines
		foreach(var tl in timelines) {
			left_toolbar.add(tl.get_tool_button());
			main_notebook.append_page(tl);
		}

		refresh_button.clicked.connect( () => {
			//Refresh the current container
			timelines[main_notebook.page].load_newest();
		});
		settings_button.clicked.connect( () => {
			SettingsDialog sd = new SettingsDialog(this);
			sd.show_all();
		});
		bottom_box.pack_start(left_toolbar, false, false);

		if (Settings.show_primary_toolbar()){
			main_box.pack_start(primary_toolbar, false, false);
			setup_primary_toolbar();
		}else{
			setup_left_toolbar();
		}


		// TODO: Implement TestToolButton
		// var tt = new TestToolButton();
		// tt.icon_name = "find";
		// left_toolbar.add(tt);

		main_notebook.show_border = false;
		main_notebook.show_tabs   = false;
		bottom_box.pack_start (main_notebook, true, true);
		main_box.pack_end(bottom_box, true, true);



		this.add(main_box);
		this.load_geometry();
		this.show_all();
	}


	/**
	 * Adds/inserts the widgets into the left toolbar.
	 */
	private void setup_left_toolbar(){
		left_toolbar.get_style_context().remove_class("sidebar");
		left_toolbar.get_style_context().add_class("primary-toolbar");

		left_toolbar.insert(avatar_button, 0);
		left_toolbar.insert(new_tweet_button, 1);
		left_toolbar.insert(left_separator, 2);
		left_toolbar.add(expander_item);
		left_toolbar.add(refresh_button);
		left_toolbar.add(settings_button);
	}

	/**
	 * Adds/inserts the widgets into the primary toolbar
	 */
	private void setup_primary_toolbar(){
		primary_toolbar.add(avatar_button);
		primary_toolbar.add(new_tweet_button);
		primary_toolbar.add(expander_item);
		primary_toolbar.add(refresh_button);
		primary_toolbar.add(settings_button);
		//Make the left toolbar a sidebar
		left_toolbar.get_style_context().remove_class("primary-toolbar");
		left_toolbar.get_style_context().add_class("sidebar");
	}

	public void set_show_primary_toolbar(bool show_primary_toolbar){
		// We just ASSUME that this value only toggles and that 2 subsequent calls
		// NEVER have the same value of show_primary_toolbar.
		if(show_primary_toolbar){
			main_box.pack_start(primary_toolbar, false, false);
			//Remove widgets
			left_toolbar.remove(avatar_button);
			left_toolbar.remove(settings_button);
			left_toolbar.remove(refresh_button);
			left_toolbar.remove(new_tweet_button);
			left_toolbar.remove(expander_item);
			left_toolbar.remove(left_separator);
			//Add them again
			setup_primary_toolbar();
		}else{
			main_box.remove(primary_toolbar);
			//Remove widgets
			primary_toolbar.remove(avatar_button);
			primary_toolbar.remove(new_tweet_button);
			primary_toolbar.remove(expander_item);
			primary_toolbar.remove(refresh_button);
			primary_toolbar.remove(settings_button);
			//add them again
			setup_left_toolbar();
		}
	}

	private void save_geometry(){
		int x, y, w, h;
		this.get_size(out w, out h);
		this.get_position(out x, out y);
		// if (right_pane != null && right_pane.is_visible())
			// w -= right_pane_width;
		Settings.set_string("main-window-geometry", "%d,%d,%d,%d".printf(x,
		                    y, w, h));
	}

	private void load_geometry(){
		string geometry_str = Settings.get_string("main-window-geometry");
		string[] parts 		= geometry_str.split(",");
		int x      = int.parse(parts[0]);
		int y      = int.parse(parts[1]);
		int width  = int.parse(parts[2]);
		int height = int.parse(parts[3]);
		this.move(x, y);
		this.resize(width, height);
	}


	/**
	*  Toggles the right pane of the window.
	*  If the given pane is the same as the one currently shown,
	*  the current one will be hidden, not shown.
	*  If it's not the same, the current one will be removed from
	*  the window and the given pane will be added and shown.
	*
	*  @param new_pane the pane to show/hide
	**/
	public void toggle_right_pane(PaneWidget new_pane){
		int width, height;
		this.get_size(out width, out height);

		if(right_pane != null && new_pane.get_id() == right_pane.get_id()){
			if(right_pane.visible)
				this.resize(width - new_pane.get_width(), height);
			else
				this.resize(width + new_pane.get_width(), height);

			right_pane.visible = !right_pane.visible;
			return;
		}
		else if(right_pane != null){
			//Remove current pane
			width -= right_pane.get_width();
			bottom_box.remove(right_pane);
		}
		bottom_box.pack_end(new_pane, false, true);

		Allocation alloc;
		main_notebook.get_allocation(out alloc);
		main_notebook.set_size_request(alloc.width, alloc.height);


		this.resize(width + new_pane.get_width(), height);
		this.right_pane = new_pane;
	}
}