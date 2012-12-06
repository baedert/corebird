using Gtk;

class MainWindow : ApplicationWindow {
	public static const int PAGE_STREAM    = 0;
	public static const int PAGE_MENTIONS  = 1;
	public static const int PAGE_FAVORITES = 2;
	public static const int PAGE_SEARCH    = 3;


	private Toolbar left_toolbar                  = new Toolbar();
	private Box main_box                          = new Box(Orientation.VERTICAL, 0);
	private Box bottom_box                        = new Box(Orientation.HORIZONTAL, 0);
	private Notebook main_notebook                = new Notebook();
	private StreamContainer stream_container      = new StreamContainer();
	private MentionsContainer mentions_container  = new MentionsContainer();
	private FavoriteContainer favorite_container  = new FavoriteContainer();
	private SearchContainer search_container      = new SearchContainer();
	private RadioToolButton[] switch_page_buttons = new RadioToolButton[4];

	public MainWindow(Gtk.Application app){
		GLib.Object (application: app);
		stream_container.window = this;
		search_container.window = this;
		//Load the user's sceen_name used for identifying him
		User.load();

		ToolButton new_tweet_button = new ToolButton.from_stock(Stock.NEW);
		new_tweet_button.clicked.connect( () => {
		 	NewTweetWindow win = new NewTweetWindow(this);
			win.show_all();
		});

		// SettingsDialog _sd = new SettingsDialog(this);
		// _sd.show_all();
		// _sd.run();

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
		left_toolbar.get_style_context().add_class("primary-toolbar");
		left_toolbar.get_style_context().add_class("sidebar");


		ToolButton avatar_button = new ToolButton(new Image.from_file(User.get_avatar_path()), null);
		avatar_button.clicked.connect( () => {
			ProfileDialog pd = new ProfileDialog();
			pd.show_all();
		});
		left_toolbar.add(avatar_button);

		//Update the user's info
		User.update_info.begin((Image)avatar_button.icon_widget);

		left_toolbar.add(new_tweet_button);
		left_toolbar.add(new SeparatorToolItem());
		switch_page_buttons[PAGE_STREAM]   = new RadioToolButton.from_stock(null, Stock.HOME);
		switch_page_buttons[PAGE_STREAM].toggled.connect( () => {
			if (switch_page_buttons[PAGE_STREAM].active)
				main_notebook.set_current_page(PAGE_STREAM);
		});
		switch_page_buttons[PAGE_MENTIONS] = new RadioToolButton.with_stock_from_widget(
			switch_page_buttons[0], Stock.ADD);
		switch_page_buttons[PAGE_MENTIONS].toggled.connect( () => {
			if (switch_page_buttons[PAGE_MENTIONS].active)
				main_notebook.set_current_page(PAGE_MENTIONS);
		});
		switch_page_buttons[PAGE_FAVORITES] = new RadioToolButton.from_widget(switch_page_buttons[0]);
		switch_page_buttons[PAGE_FAVORITES].icon_name = "emblem-favorite";
		switch_page_buttons[PAGE_FAVORITES].toggled.connect( () => {
			if(switch_page_buttons[PAGE_FAVORITES].active)
				main_notebook.set_current_page(PAGE_FAVORITES);
		});
		switch_page_buttons[PAGE_SEARCH]   = new RadioToolButton.with_stock_from_widget(
			switch_page_buttons[0], Stock.FIND);
		switch_page_buttons[PAGE_SEARCH].toggled.connect( () => {
			if (switch_page_buttons[PAGE_SEARCH].active)
				main_notebook.set_current_page(PAGE_SEARCH);
		});
		left_toolbar.add(switch_page_buttons[PAGE_STREAM]);
		left_toolbar.add(switch_page_buttons[PAGE_MENTIONS]);
		left_toolbar.add(switch_page_buttons[PAGE_FAVORITES]);
		left_toolbar.add(switch_page_buttons[PAGE_SEARCH]);

		SeparatorToolItem sep = new SeparatorToolItem();
		sep.draw = false;
		sep.set_expand(true);
		left_toolbar.add(sep);
		ToolButton refresh_button = new ToolButton.from_stock(Stock.REFRESH);
		refresh_button.clicked.connect( () => {
			message("refresh_button clicked");
			stream_container.load_new_tweets.begin();
		});
		left_toolbar.add(refresh_button);
		ToolButton settings_button = new ToolButton.from_stock(Stock.PREFERENCES);
		settings_button.clicked.connect( () => {
			SettingsDialog sd = new SettingsDialog(this);
			sd.show_all();
		});
		left_toolbar.add(settings_button);
		bottom_box.pack_start(left_toolbar, false, true);



		ScrolledWindow tweet_scroller = new ScrolledWindow(null, null);
		tweet_scroller.add_with_viewport(stream_container);
		// tweet_scroller.vadjustment.value_changed.connect( () => {
		// 	int max = (int)(tweet_scroller.vadjustment.upper - tweet_scroller.vadjustment.page_size);
		// 	int value = (int)tweet_scroller.vadjustment.value;
		// 	if (value >= (max * 0.9f)){
		// 		//Load older tweets
		// 		message("end!");
		// 	}
		// });

		tweet_scroller.kinetic_scrolling = true;
		main_notebook.append_page(tweet_scroller);
		var mentions_scroller = new ScrolledWindow(null, null);
		mentions_scroller.kinetic_scrolling = true;
		mentions_scroller.add_with_viewport(mentions_container);
		main_notebook.append_page(mentions_scroller);
		var favorite_scroller = new ScrolledWindow(null, null);
		favorite_scroller.add_with_viewport(favorite_container);
		main_notebook.append_page(favorite_scroller);
		main_notebook.append_page(search_container);

		main_notebook.show_tabs = false;
		main_notebook.show_border = false;
		bottom_box.pack_end (main_notebook, true, true);
		main_box.pack_end(bottom_box, true, true);

		// Load the cached tweets from the database
		stream_container.load_cached_tweets.begin();


		this.add(main_box);
		this.set_default_size (450, 600);
		this.show_all();
	}

	public void switch_to_search(string search_term){
		search_container.search_for.begin(search_term, true);
		switch_page_buttons[PAGE_SEARCH].active = true;
		main_notebook.set_current_page(PAGE_SEARCH);
	}

	public void set_show_primary_toolbar(bool show_primary_toolbar){

	}
}
