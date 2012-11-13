
using Gtk;


class MainWindow : Window {
	private Toolbar main_toolbar = new Toolbar();
	private Toolbar left_toolbar = new Toolbar();
	private Box main_box = new Box(Orientation.VERTICAL, 2);
	private Box bottom_box = new Box(Orientation.HORIZONTAL, 2);
	private ListStore tweets = new ListStore(1, typeof(Tweet));
	private TreeView tweet_tree = new TreeView();

	public MainWindow(){

		ToolButton new_tweet_button = new ToolButton.from_stock(Stock.NEW);
		main_toolbar.add(new_tweet_button);
		main_toolbar.get_style_context().add_class("primary-toolbar");
		main_toolbar.orientation = Orientation.HORIZONTAL;
		main_box.pack_start(main_toolbar, false, false);





		ToolButton b = new ToolButton.from_stock(Stock.ADD);
		left_toolbar.add(b);
		left_toolbar.orientation = Orientation.VERTICAL;
		left_toolbar.set_style(ToolbarStyle.ICONS);
		bottom_box.pack_start(left_toolbar, false, true);



		var tweet_renderer = new TweetRenderer();
		var column = new TreeViewColumn();
		column.pack_start(tweet_renderer, true);
		column.set_title("Tweets");
		column.add_attribute(tweet_renderer, "tweet", 0);
		tweet_tree.append_column(column);


		tweet_tree.set_model (tweets);
		ScrolledWindow tweet_scroller = new ScrolledWindow(null, null);
		tweet_scroller.add(tweet_tree);
		bottom_box.pack_end (tweet_scroller, true, true);



		main_box.pack_end(bottom_box, true, true);


		this.add(main_box);
		this.set_default_size (300, 400);
		this.show_all();
	}

}