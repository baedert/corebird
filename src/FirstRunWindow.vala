
using Gtk;
using Rest;


class FirstRunWindow : Window {
	private Button cancel_button = new Button.with_label("Cancel");
	private Button next_button = new Button.with_label("Next");
	private Notebook notebook = new Notebook();
	private Box main_box = new Box(Orientation.VERTICAL, 2);
	private Box button_box = new Box(Orientation.HORIZONTAL, 15);
	private int page = 0;
	private OAuthProxy proxy;


	public FirstRunWindow(){
		this.resize(600, 300);
		notebook.show_border = false;
		notebook.show_tabs = false;
		notebook.append_page(new Label("Hey Ho! First page!"));

		var page1_box = new Box(Orientation.VERTICAL, 3);
		page1_box.pack_start(new Label("Write the pin from the Website that
		                     just opened in the input field below."));
		var pin_entry = new Entry();
		pin_entry.placeholder_text = "PIN";
		page1_box.pack_start(pin_entry, false, true);



		notebook.append_page(page1_box);


		main_box.pack_start(notebook, true, true);


		var proxy = new OAuthProxy(
        	"0rvHLdbzRULZd5dz6X1TUA",						//Consumer Key
        	"oGrvd6654nWLhzLcJywSW3pltUfkhP4BnraPPVNhHtY", 	//Consumer Secret
        	"https://api.twitter.com",						//Url Format
        	false
        );



		cancel_button.margin_left = 10;
		cancel_button.margin_bottom = 10;
		cancel_button.clicked.connect( () => {
			this.destroy();
		});
		button_box.pack_start(cancel_button, false, false);
		next_button.margin_right = 10;
		next_button.margin_bottom = 10;
		next_button.clicked.connect( () => {
			page++;
			if (page == 1){
	            try{
					proxy.request_token ("oauth/request_token", "oob");
					GLib.AppInfo.launch_default_for_uri("http://twitter.com/oauth/authorize?oauth_token=%s"
				                                    .printf(proxy.get_token()), null);
				}catch(Error e){
					stderr.printf("Error while requesting token: "+e.message+"\n");
				}


			}else if (page == 2){
				try{
					proxy.access_token("oauth/access_token", pin_entry.get_text());
				}catch(Error e){
					stderr.printf(e.message+"\n");
				}

				// Save token + token_secret
				try{
					Corebird.create_databases();
					//Write token + token_secret ot the database
					SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db, 
						"INSERT INTO common(token, token_secret) VALUES (:token, :token_secret);");
					q.set_string(":token", proxy.get_token());
					q.set_string(":token_secret", proxy.get_token_secret());
					Corebird.db.queue(q);
				}catch(SQLHeavy.Error e){
					stderr.printf("SQL ERROR: "+e.message);
				}

				//Tell everyone that the first run has just ended.
				Settings.set_bool("first-run", false);

			}
			notebook.set_current_page(page);
		});
		button_box.pack_end (next_button, false, false);



		main_box.pack_end(button_box, false, false);
		this.add(main_box);

		this.show_all();
	}



}