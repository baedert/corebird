
using Gtk;
using Soup;


class MainWindow : Window {
	private Toolbar left_toolbar = new Toolbar();
	private Box main_box = new Box(Orientation.VERTICAL, 0);
	private Box bottom_box = new Box(Orientation.HORIZONTAL, 0);
	private Notebook main_notebook = new Notebook();
	private StreamContainer stream_container = new StreamContainer();
	private MentionsContainer mentions_container = new MentionsContainer();
	private SearchContainer search_container = new SearchContainer();

	public MainWindow(){

		 ToolButton new_tweet_button = new ToolButton.from_stock(Stock.NEW);
		 new_tweet_button.clicked.connect( () => {
		 	NewTweetWindow win = new NewTweetWindow(this);
		 	win.show_all();
		 });

		 CssProvider provider = new CssProvider();
		 provider.load_from_data(
			"TweetListEntry .horizontal .tweet{
				background-image: none;
				background-color: red;
				color: green;
			}", -1);
		 this.get_style_context().add_provider(provider,STYLE_PROVIDER_PRIORITY_APPLICATION);


		left_toolbar.orientation = Orientation.VERTICAL;
		left_toolbar.set_style(ToolbarStyle.ICONS);
		left_toolbar.get_style_context().add_class("sidebar");
		left_toolbar.add(new_tweet_button);
		left_toolbar.add(new SeparatorToolItem());
		RadioToolButton home_button = new RadioToolButton.from_stock(null, Stock.HOME);
		home_button.toggled.connect( () => {
			if (home_button.active)
				main_notebook.set_current_page(0);
		});
		left_toolbar.add(home_button);
		RadioToolButton mentions_button = new RadioToolButton.with_stock_from_widget(home_button, Stock.ADD);
		mentions_button.toggled.connect( () => {
			if(mentions_button.active)
				main_notebook.set_current_page(1);
		});
		left_toolbar.add(mentions_button);
		RadioToolButton search_button = new RadioToolButton.with_stock_from_widget(home_button, Stock.FIND);
		search_button.toggled.connect( () => {
			if(search_button.active)
				main_notebook.set_current_page(2);
		});
		left_toolbar.add(search_button);

		SeparatorToolItem sep = new SeparatorToolItem();
		sep.draw = false;
		sep.set_expand(true);
		left_toolbar.add(sep);
		ToolButton refresh_button = new ToolButton.from_stock(Stock.REFRESH);
		refresh_button.clicked.connect( () => {
			stream_container.load_new_tweets.begin();
		});
		left_toolbar.add(refresh_button);
		ToolButton settings_button = new ToolButton.from_stock(Stock.PREFERENCES);
		settings_button.clicked.connect( () => {
			SettingsDialog sd = new SettingsDialog();
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
		main_notebook.append_page(search_container);

		main_notebook.show_tabs = false;
		main_notebook.show_border = false;
		bottom_box.pack_end (main_notebook, true, true);
		main_box.pack_end(bottom_box, true, true);

		//TODO Find out how to get the user_id of the authenticated user(needed for the profile info lookup)

		// Load the cached tweets from the database
		// for(int i = 0;  i  < 300; i++){
			// stdout.printf("%d\n", i);
			stream_container.load_cached_tweets.begin();
		// }

		this.add(main_box);
		this.set_default_size (450, 600);
		this.show_all();

		Corebird.create_tables();

		message(stream_container.get_style_context().get_path().to_string());
	}

	// private async void refresh_profile(){
	// 	var call = Twitter.proxy.new_call();
	// 	call.set_method("GET");
	// 	call.set_function("1.1/users/show.json");
	// 	call.add_param("user_id", "15");
	// 	call.invoke_async.begin(null, () => {
	// 		string json_string = call.get_payload();
	// 		Json.Parser parser = new Json.Parser();
	// 		try{
	// 			parser.load_from_data (json_string);
	// 			// stdout.printf(json_string+"\n");
	// 		}catch(GLib.Error e){
	// 			error("Error while refreshing profile: %s", e.message);
	// 		}
	// 	});
	// }
}
