
using Gtk;
using Rest;


class FirstRunWindow : ApplicationWindow {
	private Button cancel_button = new Button.with_label("Cancel");
	private Button next_button = new Button.with_label("Next");
	private Notebook notebook = new Notebook();
	private Box main_box = new Box(Orientation.VERTICAL, 2);
	private Box button_box = new Box(Orientation.HORIZONTAL, 15);
	private int page = 0;


	public FirstRunWindow(Gtk.Application app){
		GLib.Object(application: app);
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
					Twitter.proxy.request_token ("oauth/request_token", "oob");
					GLib.AppInfo.launch_default_for_uri("http://twitter.com/oauth/authorize?oauth_token=%s"
				                                    .printf(Twitter.proxy.get_token()), null);
				}catch(Error e){
					stderr.printf("Error while requesting token: "+e.message+"\n");
				}


			}else if (page == 2){
				try{
					Twitter.proxy.access_token("oauth/access_token", pin_entry.get_text());
				}catch(Error e){
					error("Error while obtatning access token: %s", e.message);
				}



				// Save token + token_secret
				try{
					Corebird.create_tables();
					//Write token + token_secret ot the database
					SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db, "INSERT INTO 'common'(token, token_secret) 
					                  VALUES (:t, :ts);");
					q.set_string(":t", Twitter.proxy.get_token());
					q.set_string(":ts", Twitter.proxy.get_token_secret());
					q.execute();
				}catch(SQLHeavy.Error e){
					stderr.printf("SQL ERROR: "+e.message+"\n");
				}

				//Load the user's settings
				var settings_call = Twitter.proxy.new_call();
				settings_call.set_function("1.1/account/settings.json");
				settings_call.set_method("GET");
				settings_call.invoke_async.begin(null, (obj, res) => {
					try{
						settings_call.invoke_async.end(res);
					} catch (GLib.Error e){
						error ("Error while ending settings_call: %s", e.message);
					}
					string back = settings_call.get_payload();
					var parser = new Json.Parser();
					try{
						parser.load_from_data(back);
					} catch(GLib.Error e){
						error("Error with Json data: %s\n DATA:\n%s", e.message, back);
					}
					var root = parser.get_root().get_object();
					string screen_name = root.get_string_member("screen_name");
					try{
						SQLHeavy.Query screen_name_query = new SQLHeavy.Query(Corebird.db,
							"INSERT INTO `user`(screen_name) VALUES ('%s');".printf(screen_name));
						screen_name_query.execute_async.begin();
					}catch(SQLHeavy.Error e){
						error("Error while settings the screen_name: %s", e.message);
					}
				});

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