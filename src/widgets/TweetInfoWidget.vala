using Gtk;

class TweetInfoWidget : PaneWidget, GLib.Object{
	// private Label text_label = new Label("");
	private Box box;


	//TASK:
	// make the "window" open in the right of MainWindow!
	public TweetInfoWidget(Tweet t){
		// text_label.set_use_markup(true);
		// text_label.set_line_wrap(true);
		// text_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
		// text_label.label = t.text;
		// text_label.max_width_chars = 20;
		// this.pack_start(text_label, true, true);
		UIBuilder builder = new UIBuilder("ui/tweet-info-window.ui", "main_box");
		builder.get_label("name_label").label = "<big><b>"+t.user_name+"</b></big>";
		box = builder.get_box("main_box");
		box.unparent();
	}

	public string get_id(){
		return "bla";
	}

	public bool is_visible(){
		return box.visible;
	}

	public void set_visible(bool visible){
		box.visible = visible;
	}

	public Widget get_widget(){
		return box;
	}
}