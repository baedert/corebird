
using Gtk;

class ProfileWidget : Gtk.Box {
	private static const int PAGE_TWEETS     = 0;
	private static const int PAGE_FOLLOWING  = 1;
	private static const int PAGE_FOLLOWERS  = 2;

	private ImageBox banner_box         = new ImageBox(Orientation.VERTICAL, 3);
	private ImageBox avatar_image       = new ImageBox(Orientation.VERTICAL, 0);
	private Label name_label            = new Label("");
	private Label description_label     = new Label("");
	private Label url_label             = new Label("");
	private Label location_label        = new Label("");
	private TextButton tweets_button    = new TextButton();
	private TextButton following_button = new TextButton();
	private TextButton followers_button = new TextButton();
	private ToggleButton follow_button  = new ToggleButton.with_label("Follow");
	private Gd.Stack bottom_stack       = new Gd.Stack();
	private int active_page 			= 0;
	private int64 user_id;
	private string screen_name;
	private MainWindow window;

	public ProfileWidget(MainWindow window){
		GLib.Object(orientation: Orientation.VERTICAL);
		this.window = window;

		banner_box.get_style_context().add_class("profile-header");
		var top_banner_box = new Gtk.Box(Orientation.HORIZONTAL, 8);
		avatar_image.set_size_request(100, 100);
		avatar_image.margin_left = 8;
		avatar_image.margin_top  = 8;
		top_banner_box.pack_start(avatar_image, false, false);


		var data_box = new Gtk.Box(Orientation.VERTICAL, 5);
		name_label.get_style_context().add_class("data");
		name_label.set_alignment(0, 0.5f);
		name_label.margin_top = 8;
		data_box.pack_start(name_label, false, true);
		url_label.set_alignment(0, 0.5f);
		url_label.get_style_context().add_class("data");
		url_label.max_width_chars = 20;
		url_label.set_ellipsize(Pango.EllipsizeMode.MIDDLE);
		data_box.pack_start(url_label, false, true);
		location_label.set_alignment(0, 0.5f);
		location_label.get_style_context().add_class("data");
		data_box.pack_start(location_label, false, true);
		follow_button.set_halign(Align.START);
		follow_button.toggled.connect(toggle_follow);
		data_box.pack_start(follow_button, false, false);
		top_banner_box.pack_start(data_box, true, true);

		banner_box.pack_start(top_banner_box, false, false);

		description_label.set_use_markup(true);
		description_label.set_line_wrap(true);
		description_label.get_style_context().add_class("description");
		description_label.set_justify(Justification.CENTER);
		description_label.activate_link.connect(handle_uri);
		description_label.margin_bottom = 5;
		banner_box.pack_start(description_label, true, true);

		var bottom_banner_box = new Gtk.Box(Orientation.HORIZONTAL, 0);
		bottom_banner_box.homogeneous = true;

		tweets_button.get_style_context().add_class("data-button");
		tweets_button.clicked.connect(() => {
			switch_page (PAGE_TWEETS);
		});
		following_button.get_style_context().add_class("data-button");
		following_button.clicked.connect(() => {
			switch_page (PAGE_FOLLOWING);
		});
		followers_button.get_style_context().add_class("data-button");
		followers_button.clicked.connect(() => {
			switch_page (PAGE_FOLLOWERS);
		});
		bottom_banner_box.pack_start(tweets_button, false, true);
		bottom_banner_box.pack_start(following_button, false, true);
		bottom_banner_box.pack_start(followers_button, false, true);


		banner_box.pack_start(bottom_banner_box, false, false);

		this.pack_start(banner_box, false, false);
		this.pack_start(bottom_stack, true, true);
	}


	public void set_user_id(int64 user_id, string screen_name = ""){
		if(user_id != 0 && screen_name != "") {
			error("Can't use both user_id and screen_name.");
		}
		this.user_id = user_id;
		this.screen_name = screen_name;

		/* Load the profile data now, then - if available - set the cached data */
		load_profile_data.begin(user_id, screen_name);

		//Load cached data
		string query_string = "SELECT id, screen_name, name, description, tweets,
					 following, followers, avatar_name, banner_url,
					 url, location, following, is_following, banner_name
					 FROM profiles ";
		if(user_id != 0)
			query_string += @"WHERE id='$user_id';";
		else
			query_string += @"WHERE screen_name='$screen_name';";

		SQLHeavy.Query cache_query = new SQLHeavy.Query(Corebird.db,
														query_string);
		SQLHeavy.QueryResult cache_result = cache_query.execute();
		if (!cache_result.finished){
			/* If we get inside this block, there is already some data in the 
			  DB we can use. */
			if(screen_name != "")
				user_id = cache_result.fetch_int64(0);

			avatar_image.set_background(Utils.user_file(
								   "/assets/avatars/"+cache_result.fetch_string(7)));

			set_data(cache_result.fetch_string(2), cache_result.fetch_string(1),
					 cache_result.fetch_string(9), cache_result.fetch_string(10),
					 cache_result.fetch_string(3),
					 cache_result.fetch_int(4), cache_result.fetch_int(5),
					 cache_result.fetch_int(6));
			follow_button.active = (cache_result.fetch_int(12) == 1);
			string banner_name = cache_result.fetch_string(13);
			debug("banner_name: %s", banner_name);

			if(banner_name != null && 
				FileUtils.test(Utils.user_file("assets/banners/"+banner_name), FileTest.EXISTS)){
				debug("Banner exists, set it directly...");
				banner_box.set_background(Utils.user_file(
										  "assets/banners/"+banner_name));
			}else{
				// If the cached banner does somehow not exist, load it again.
				debug("Banner %s does not exist, load it first...", banner_name);
				load_banner.begin(user_id, Utils.user_file("assets/banners/"+banner_name),
							screen_name);
				banner_box.set_background(DATADIR+"/no_banner.png");
			}
		}else {
			banner_box.set_background(DATADIR+"/no_banner.png");
			load_banner.begin(user_id, "", screen_name);
		}
	}


	private async void load_profile_data(int64 user_id, string screen_name = ""){
		if(user_id != 0 && screen_name != "") {
			error("Can't use both user_id and screen_name.");
		}

		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/users/show.json");
		if(user_id != 0)
			call.add_param("user_id", user_id.to_string());
		else
			call.add_param("screen_name", screen_name);
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end (res);
			} catch (GLib.Error e){
				warning("Error while ending call: %s", e.message);
				return;
			}
			string back = call.get_payload();
			Json.Parser parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			} catch (GLib.Error e){
				warning ("Error while loading profile data: %s", e.message);
				return;
			}

			var root = parser.get_root().get_object();
			string avatar_url = root.get_string_member("profile_image_url");
			avatar_url = avatar_url.replace("_normal", "");
			string avatar_name = Utils.get_avatar_name(avatar_url);
			string avatar_on_disk = Utils.user_file("assets/avatars/"+avatar_name);

			if(!FileUtils.test(avatar_on_disk, FileTest.EXISTS)){
				Utils.download_file_async.begin(avatar_url, avatar_on_disk, 
					() => {avatar_image.set_background(avatar_on_disk);});
			}else
				avatar_image.set_background(avatar_on_disk);
			string name        = root.get_string_member("name");
			       screen_name = root.get_string_member("screen_name");
			string description = root.get_string_member("description").replace("&", "&amp;");
			int64 id		   = root.get_int_member("id");
			int followers      = (int)root.get_int_member("followers_count");
			int following      = (int)root.get_int_member("friends_count");
			int tweets         = (int)root.get_int_member("statuses_count");
			bool is_following  = root.get_boolean_member("following");
			bool has_url       = root.get_object_member("entities").has_member("url");
			string banner_name = get_banner_name(user_id, screen_name);

			string display_url = null;
			if(has_url) {
				var urls_object = root.get_object_member("entities")
					.get_object_member("url").get_array_member("urls").get_element(0)
						.get_object();

				var url = urls_object.get_string_member("expanded_url");
				if(urls_object.has_member("display_url")){
					display_url = urls_object.get_string_member("expanded_url");
				}else{
					url = urls_object.get_string_member("url");
					display_url = url;
				}
			}

			string location = null;
			if(root.has_member("location")){
				location	   = root.get_string_member("location");
			}

			set_data(name, screen_name, display_url, location, description, tweets,
					 following, followers);
			follow_button.active = is_following;

			try{
				SQLHeavy.Query update_query = new SQLHeavy.Query(Corebird.db,
					"INSERT OR REPLACE INTO `profiles`(`id`, `screen_name`, `name`,
					   `followers`, `following`, `tweets`, `description`, `avatar_name`,
					   `url`, `location`, `is_following`, `banner_name`)
					 VALUES
					(:id, :screen_name, :name, :followers, :following, :tweets,
					 :description, :avatar_name, :url, :location, :is_following,
					 :banner_name);");
				update_query.set_int64(":id", id);
				update_query.set_string(":screen_name", screen_name);
				update_query.set_string(":name", name);
				update_query.set_int(":followers", followers);
				update_query.set_int(":following", following);
				update_query.set_int(":tweets", tweets);
				update_query.set_string(":description", description);
				update_query.set_string(":avatar_name", avatar_name);
				update_query.set_string(":url", display_url);
				update_query.set_string(":location", location);
				update_query.set_int(":is_following", is_following ? 1 : 0);
				update_query.set_string(":banner_name", banner_name);
				update_query.execute_async.begin();
			}catch(SQLHeavy.Error e){
				warning("Error while updating profile info for %s:%s", screen_name,
						e.message);
			}
		});
	}


	/**
	 * Loads the user's banner image.
	 *
	 * @param user_id The user's ID
	 * @param saved_banner_url 
	 * @param screen_name
	 */
	private async void load_banner(int64 user_id, string saved_banner_url,
	                               string screen_name = ""){

		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/users/profile_banner.json");
		if(user_id != 0)
			call.add_param("user_id", user_id.to_string());
		else
			call.add_param("screen_name", screen_name);

		call.invoke_async.begin(null, (obj, res) => {
			if (call.get_status_code() == 404){
				// Normal. The user has not set a profile banner.
				message("No Banner set.");
				return;
			}

			try{
				call.invoke_async.end (res);
			} catch (GLib.Error e){
				warning("Error while ending call: %s", e.message);
				return;
			}

			string back = call.get_payload();
			Json.Parser parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			} catch (GLib.Error e){
				warning ("Error while loading banner: %s\nDATA:%s\n", e.message, back);
				return;
			}

			var root = parser.get_root().get_object().get_object_member("sizes");
			string banner_url, banner_name;
			banner_url = root.get_object_member("mobile_retina").get_string_member("url");
			banner_name = get_banner_name(user_id, screen_name);

			string banner_on_disk = Utils.user_file("assets/banners/"+banner_name);
			if (!FileUtils.test(banner_on_disk, FileTest.EXISTS) ||
			    	banner_url != saved_banner_url){

				Utils.download_file_async.begin(banner_url, banner_on_disk,
						() => {banner_box.set_background(banner_on_disk);});
				try{
					debug("Setting the banner name to %s", banner_name);
					Corebird.db.execute(@"UPDATE `profiles` SET `banner_url`='$banner_url',
					                    `banner_name`='$banner_name'
					                    WHERE `id`='$user_id';");
				} catch (GLib.Error ex) {
					warning ("Error while setting banner: %s", ex.message);
				}
			}else
				// If the user's banner on the server is the same as the cached one AND
				// it exists on disk, we just use that.
				banner_box.set_background(banner_on_disk);
		});
	}


	private new void set_data(string name, string screen_name, string? url,
	                          string? location, string description, int tweets,
	                          int following, int followers) {

			name_label.set_markup("<big><big><b>%s</b>  @%s</big></big>"
				                      .printf(name, screen_name));
			string d = Tweet.replace_links(description);
			description_label.set_markup("<big><big><big>%s</big></big></big>".printf(d));
			tweets_button.set_markup(
					"<big><big><b>%'d</b></big></big>\nTweets"
					.printf(tweets));

			following_button.set_markup(
					"<big><big><b>%'d</b></big></big>\nFollowing"
					.printf(following));

			followers_button.set_markup(
					"<big><big><b>%'d</b></big></big>\nFollowers"
					.printf(followers));

			if(location != null && location != ""){
				location_label.visible = true;
				location_label.set_markup("<big><big>%s</big></big>".printf(location));
			}else
				location_label.visible = false;

			if(url != null && url != ""){
				url_label.visible = true;
				url_label.set_markup("<big><big><a href='%s'>%s</a></big></big>"
				                     .printf(url, url));
			}else
				url_label.visible = false;

	}


	private void toggle_follow() {
		return;
		// TODO: Don't automatically call this whenever the user opens a profile…
		bool value = follow_button.active;
		var call = Twitter.proxy.new_call();
		if(value)
			call.set_function("1.1/friendships/create.json");
		else
			call.set_function("1.1/friendships/destroy.json");
		call.set_method("POST");
		call.add_param("follow", "true");
		if(user_id != 0)
			call.add_param("id", user_id.to_string());
		else
			call.add_param("screen_name", screen_name);
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end(res);
			} catch (GLib.Error e) {
				critical(e.message);
			}
			//stdout.printf(call.get_payload()+"\n");
		});
	}

	private string get_banner_name(int64 user_id, string screen_name) {
		if(user_id != 0)
			return user_id.to_string()+".png";
		return screen_name+".png";
	}

	private bool handle_uri(string uri){
		uri = uri._strip();
		string term = uri.substring(1);

		if(uri.has_prefix("@")){
			window.switch_page(MainWindow.PAGE_PROFILE,
			                   ProfilePage.BY_NAME,
			                   term);
			return true;
		}else if(uri.has_prefix("#")){
			window.switch_page(MainWindow.PAGE_SEARCH, uri);
			return true;
		}
		return false;
	}
	
	/**
	 * Switch the page to the one with the given ID
	 * @param page The page to switch to
	 */
	private void switch_page(int page) {
		if(page == active_page)
			return;

		if(page > active_page)
			bottom_stack.transition_type = Gd.Stack.TransitionType.SLIDE_LEFT;
		else
			bottom_stack.transition_type = Gd.Stack.TransitionType.SLIDE_RIGHT;

		bottom_stack.set_visible_child_name("%d".printf(page));
	}
}
